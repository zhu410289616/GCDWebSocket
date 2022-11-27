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
#import <GCDWebSocket/GCDWebSocketEchoServer.h>
#import <GCDWebSocket/GCDWebSocketServerConnection.h>
//websocket client
#import <SocketRocket/SocketRocket.h>

@interface ViewController ()
<
GCDWebServerDelegate,
GCDWebSocketServerTransport,
SRWebSocketDelegate
>

@property (nonatomic, strong) GCDWebSocketEchoServer *echoServer;
@property (nonatomic, strong) SRWebSocket *websocketClient;
@property (nonatomic, strong) NSTimer *heartbeatTimer;

@property (nonatomic, strong) UIButton *testButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self startEchoServer];
    
    self.testButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.testButton.frame = CGRectMake(50, 100, 80, 40);
    [self.testButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.testButton setTitle:@"start" forState:UIControlStateNormal];
    [self.testButton addTarget:self action:@selector(startOrPauseClient) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.testButton];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopHeartbeatTimer];
}

- (void)startOrPauseClient
{
    if (nil == self.websocketClient) {
        NSString *wsUrl = @"ws://localhost:2022";
        [self openWebSocketClient:wsUrl];
        [self.testButton setTitle:@"stop" forState:UIControlStateNormal];
    } else {
        [self closeWebSocketClient];
        [self.testButton setTitle:@"start" forState:UIControlStateNormal];
    }
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
    [self startHeartbeatTimerWith:10];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    DDLogDebug(@"didFailWithError: %@", error);
}

#pragma mark - echo server

- (void)startEchoServer
{
    self.echoServer = [[GCDWebSocketEchoServer alloc] init];
    self.echoServer.transport = self;
    self.echoServer.delegate = self;
    [self.echoServer startWithPort:2022 bonjourName:nil];
}

#pragma mark - GCDWebServerDelegate

/**
 *  This method is called after the server has successfully started.
 */
- (void)webServerDidStart:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] start: %@", server.serverURL);
}

- (void)webServerDidCompleteBonjourRegistration:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] Bonjour: %@", server.bonjourServerURL);
}

- (void)webServerDidStop:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] stop: %@", server);
}

#pragma mark - GCDWebSocketServerTransport

- (void)transportWillStart:(GCDWebServerConnection *)transport
{
    //one connection will callback by this method when it open
}

- (void)transportWillEnd:(GCDWebServerConnection *)transport
{
    //one connection will callback by this method when it close
}

- (void)transport:(GCDWebServerConnection *)transport received:(GCDWebSocketMessage)msg
{
    //server got the msg by this method
    DDLogDebug(@"[received] opcode: %d, payload: %@", msg.header.opcode, msg.body.payload);
    
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
