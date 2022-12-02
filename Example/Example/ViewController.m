//
//  ViewController.m
//  Example
//
//  Created by zhuruhong on 2022/11/21.
//

#import "ViewController.h"
//logger
#import <CCDBucket/CCDLogger.h>
//websocket server
#import <GCDWebSocket/GCDWebSocketServer.h>
#import <GCDWebSocket/GCDWebSocketServerConnection.h>
//websocket client
#import <SocketRocket/SocketRocket.h>

@interface ViewController ()
<
GCDWebServerDelegate,
GCDWebSocketServerTransport,
SRWebSocketDelegate
>

@property (nonatomic, strong) GCDWebSocketServer *wsServer;
@property (nonatomic, strong) SRWebSocket *websocketClient;
@property (nonatomic, strong) NSTimer *heartbeatTimer;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *statusButton;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
    [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [_dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.frame = CGRectMake(20, 100, width - 20 * 2, 40);
    self.statusLabel.textColor = [UIColor blueColor];
    [self.view addSubview:self.statusLabel];
    
    self.statusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.statusButton.frame = CGRectMake(20, 160, 80, 40);
    [self.statusButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.statusButton setTitle:@"start" forState:UIControlStateNormal];
    [self.statusButton addTarget:self action:@selector(startOrStopClient) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.statusButton];
    
    self.textView = [[UITextView alloc] init];
    self.textView.frame = CGRectMake(20, 220, width - 20 * 2, height - 350);
    self.textView.layer.borderColor = [UIColor blueColor].CGColor;
    self.textView.layer.borderWidth = 1.0f;
    self.textView.font = [UIFont systemFontOfSize:14.0f];
    [self.view addSubview:self.textView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self startEchoServer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopHeartbeatTimer];
}

- (void)startOrStopClient
{
    if (nil == self.websocketClient) {
        NSString *wsUrl = @"ws://localhost:2022";
        [self openWebSocketClient:wsUrl];
        [self.statusButton setTitle:@"stop" forState:UIControlStateNormal];
    } else {
        [self closeWebSocketClient];
        [self.statusButton setTitle:@"start" forState:UIControlStateNormal];
    }
}

#pragma mark - date formate

- (NSString *)getCurrentTime
{
    NSDate *nowDate = [NSDate date];
    return [self.dateFormatter stringFromDate:nowDate];
}

#pragma mark - heartbeat

- (void)stopHeartbeatTimer
{
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
}

- (void)startHeartbeatTimerWith:(NSTimeInterval)interval
{
    [self stopHeartbeatTimer];
    
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(doHeartbeatAction) userInfo:nil repeats:YES];
}

- (void)doHeartbeatAction
{
    if (self.websocketClient.readyState == SR_OPEN) {
        NSString *testData = @"[heartbeat] server will echo this string when received.";
        [self.websocketClient send:testData];
    }
}

#pragma mark - websocket client

- (void)closeWebSocketClient
{
    if (self.websocketClient) {
        [self.websocketClient close];
        self.websocketClient = nil;
    }
}

- (void)openWebSocketClient:(NSString *)urlString
{
    NSAssert(urlString, @"please set websocket url");
    NSURL *URL = [NSURL URLWithString:urlString];
    NSAssert(URL, @"url:(%@) error, please check !!!", urlString);
    
    [self closeWebSocketClient];
    
    self.websocketClient = [[SRWebSocket alloc] initWithURL:URL];
    self.websocketClient.delegate = self;
    [self.websocketClient open];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"receive echo message from server:  %@", message);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSString *testData = @"create the text for test, then send this string to server; server will echo this string when received.";
    [self.websocketClient send:testData];
    //start heartbeat loop
    [self startHeartbeatTimerWith:5];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    DDLogDebug(@"didFailWithError: %@", error);
}

#pragma mark - echo server

- (void)startEchoServer
{
    self.wsServer = [[GCDWebSocketServer alloc] init];
    self.wsServer.transport = self;
    self.wsServer.delegate = self;
    [self.wsServer startWithPort:2022 bonjourName:nil];
}

#pragma mark - GCDWebServerDelegate

/**
 *  This method is called after the server has successfully started.
 */
- (void)webServerDidStart:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] start: %@", server.serverURL);
    self.statusLabel.text = [NSString stringWithFormat:@"ws://%@:%@", server.serverURL.host, server.serverURL.port];
    NSString *text = [NSString stringWithFormat:@"[WebServer] start: %@\n\n", server.serverURL];
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
}

- (void)webServerDidCompleteBonjourRegistration:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] Bonjour: %@", server.bonjourServerURL);
    NSString *text = [NSString stringWithFormat:@"[WebServer] Bonjour: %@\n\n", server.bonjourServerURL];
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
}

- (void)webServerDidStop:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] stop: %@", server);
}

#pragma mark - GCDWebSocketServerTransport

- (void)transportWillBegin:(GCDWebServerConnection *)transport
{
    //one connection will callback by this method when it open
    NSString *text = [NSString stringWithFormat:@"[%@] connection[%p] will begin\n\n", [self getCurrentTime], transport];
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
}

- (void)transportWillEnd:(GCDWebServerConnection *)transport
{
    //one connection will callback by this method when it close
    NSString *text = [NSString stringWithFormat:@"[%@] connection[%@] will end\n\n", [self getCurrentTime], transport];
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
}

- (void)transport:(GCDWebServerConnection *)transport received:(GCDWebSocketMessage)msg
{
    //server got the msg by this method
    NSString *content = [[NSString alloc] initWithData:msg.body.payload encoding:NSUTF8StringEncoding];
    NSString *text = [NSString stringWithFormat:@"[%@] connection[%p] received: opcode=%d, payload=%@\n\n", [self getCurrentTime], transport, msg.header.opcode, content];
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
    
#ifdef DEBUG
    GCDWebSocketServerConnection *connection = nil;
    if ([transport isKindOfClass:[GCDWebSocketServerConnection class]]) {
        connection = (GCDWebSocketServerConnection *)transport;
    }
    
    //echo message
    GCDWebSocketMessage echoMessage;
    echoMessage.header.fin = YES;
    echoMessage.header.opcode = GCDWebSocketOpcodeTextFrame;
    echoMessage.body.payload = msg.body.payload;
    [connection sendMessage:echoMessage];
#endif
}

@end
