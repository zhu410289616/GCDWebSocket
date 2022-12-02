//
//  GCDWebServerTimer.m
//  GCDWebSocket
//
//  Created by zhuruhong on 2022/12/2.
//

#import "GCDWebServerTimer.h"

@interface GCDWebServerTimer ()

@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic,   weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) id userInfo;
@property (nonatomic, assign) BOOL repeats;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation GCDWebServerTimer

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                        target:(id)target
                                      selector:(SEL)selector
                                      userInfo:(id)userInfo
                                       repeats:(BOOL)repeats
{
    return [GCDWebServerTimer scheduledTimerWithTimeInterval:timeInterval target:target selector:selector userInfo:userInfo repeats:repeats dispatchQueue:dispatch_get_main_queue()];
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                        target:(id)target
                                      selector:(SEL)selector
                                      userInfo:(id)userInfo
                                       repeats:(BOOL)repeats
                                 dispatchQueue:(dispatch_queue_t)dispatchQueue
{
    GCDWebServerTimer *timer = [[GCDWebServerTimer alloc] initWithTimeInterval:timeInterval target:target selector:selector userInfo:userInfo repeats:repeats dispatchQueue:dispatchQueue];
    [timer schedule];
    return timer;
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval
                              target:(id)target
                            selector:(SEL)selector
                            userInfo:(id)userInfo
                             repeats:(BOOL)repeats
                       dispatchQueue:(dispatch_queue_t)dispatchQueue
{
    NSParameterAssert(target);
    NSParameterAssert(selector);
    
    if (self = [super init]) {
        self.timeInterval = timeInterval;
        self.target = target;
        self.selector = selector;
        self.userInfo = userInfo;
        self.repeats = repeats;
        self.dispatchQueue = dispatchQueue ?: dispatch_get_main_queue();
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.dispatchQueue);
        
        __weak typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(_timer, ^{
            __strong typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            [strongSelf timerFired];
        });
        
        uint64_t second = (uint64_t)(_timeInterval * NSEC_PER_SEC);
        dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, second);
        dispatch_source_set_timer(_timer, tt, second, NSEC_PER_MSEC);
    }
    return self;
}

- (void)timerFired
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.selector withObject:self];
#pragma clang diagnostic pop
        
    if (!self.repeats) {
        [self invalidate];
    }
}

- (void)schedule
{
    if (self.timer) {
        dispatch_resume(self.timer);
    }
}

- (void)fire
{
    [self timerFired];
}

- (void)invalidate
{
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

@end
