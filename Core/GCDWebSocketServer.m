//
//  GCDWebSocketServer.m
//  Pods
//
//  Created by ruhong zhu on 2021/9/20.
//

#import "GCDWebSocketServer.h"
#import <GCDWebServer/GCDWebServerPrivate.h>
#import <pthread/pthread.h>
#import "GCDWebServerTimer.h"
#import "GCDWebServerResponse+WebSocket.h"
#import "GCDWebSocketServerConnection.h"

static inline NSString *GCDWebServerConnectionKey(GCDWebServerConnection *con)
{
    return GCDWebServerComputeMD5Digest(@"%p%@%@", con, con.remoteAddressString, con.localAddressString);
}

@interface GCDWebSocketServer ()
{
    pthread_rwlock_t _con_rwlock;
}

@property (nonatomic, strong) NSMutableDictionary *connectionsDic;
@property (nonatomic, strong) GCDWebServerTimer *checkTimer;

@end

@implementation GCDWebSocketServer

- (void)dealloc
{
    pthread_rwlock_destroy(&_con_rwlock);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeout = 30;
        pthread_rwlock_init(&_con_rwlock, NULL);
        _connectionsDic = @{}.mutableCopy;
        [self addHandlerForMethod:@"GET" pathRegex:@"^/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
            return [GCDWebServerResponse responseWith:request];
        }];
    }
    return self;
}

- (BOOL)startWithPort:(NSUInteger)port bonjourName:(NSString *)name
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[GCDWebServerOption_Port] = @(port);
    options[GCDWebServerOption_BonjourName] = name ?: @"";
    options[GCDWebServerOption_AutomaticallySuspendInBackground] = @(NO);
    options[GCDWebServerOption_ConnectionClass] = [GCDWebSocketServerConnection class];
    
    if ([self startWithOptions:options error:NULL]) {
        // 如果启动正常，则开始长链接超时检测逻辑，每秒检测一次；
        [self startCheckTimerWith:1];
        return YES;
    }
    return NO;
}

#pragma mark - check alive

- (void)stopCheckTimer
{
    if (self.checkTimer) {
        [self.checkTimer invalidate];
        self.checkTimer = nil;
    }
}

- (void)startCheckTimerWith:(NSTimeInterval)interval
{
    [self stopCheckTimer];
    
    self.checkTimer = [GCDWebServerTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(doCheckAction) userInfo:nil repeats:YES];
}

- (void)doCheckAction
{
    pthread_rwlock_rdlock(&_con_rwlock);
    NSDictionary<NSString *, id> *tempConnectionsDic = [self.connectionsDic copy];
    pthread_rwlock_unlock(&_con_rwlock);
    
    //check connection
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    NSMutableArray *timeoutConnectionKeys = [NSMutableArray array];
    [tempConnectionsDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        GCDWebSocketServerConnection *con = nil;
        if ([obj isKindOfClass:[GCDWebSocketServerConnection class]]) {
            con = obj;
        } else {
            !key ?: [timeoutConnectionKeys addObject:key];
        }
        // timeout
        if (currentTime - con.lastReadDataTime > self.timeout) {
            [con close];
            [timeoutConnectionKeys addObject:key];
        }
    }];
    
    pthread_rwlock_wrlock(&_con_rwlock);
    [self.connectionsDic removeObjectsForKeys:timeoutConnectionKeys];
    pthread_rwlock_unlock(&_con_rwlock);
}

@end

@implementation GCDWebSocketServer (Transport)

- (void)transportWillBegin:(GCDWebServerConnection *)connection
{
    pthread_rwlock_wrlock(&_con_rwlock);
    NSString *key = GCDWebServerConnectionKey(connection);
    [self.connectionsDic setValue:connection forKey:key];
    pthread_rwlock_unlock(&_con_rwlock);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!connection) {
            return;
        }
        if ([self.transport respondsToSelector:@selector(transportWillBegin:)]) {
            [self.transport transportWillBegin:connection];
        }
    });
}

- (void)transportWillEnd:(GCDWebServerConnection *)connection
{
    pthread_rwlock_wrlock(&_con_rwlock);
    NSString *key = GCDWebServerConnectionKey(connection);
    GCDWebServerConnection *tempCon = [self.connectionsDic objectForKey:key];
    [self.connectionsDic removeObjectForKey:key];
    pthread_rwlock_unlock(&_con_rwlock);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!tempCon) {
            return;
        }
        if ([self.transport respondsToSelector:@selector(transportWillEnd:)]) {
            [self.transport transportWillEnd:tempCon];
        }
    });
}

- (void)transport:(GCDWebServerConnection *)connection received:(GCDWebSocketMessage)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!connection) {
            return;
        }
        if ([self.transport respondsToSelector:@selector(transport:received:)]) {
            [self.transport transport:connection received:message];
        }
    });
}

@end
