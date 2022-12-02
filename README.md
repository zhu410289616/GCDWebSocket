# GCDWebSocket
GCDWebSocket base GCDWebServer

# pod
```
pod 'GCDWebSocket', '~> 0.0.1'
```

```
pod 'GCDWebSocket', '~> 0.0.1', :subspecs => ['Core', 'EchoServer']
```

# function
## start websocket server
``` 
- (void)startWebsocketServer
{
    self.websocketServer = [[GCDWebSocketServer alloc] init];
    self.websocketServer.transport = self;
    self.websocketServer.delegate = self;
    [self.websocketServer startWithPort:2022 bonjourName:nil];
}
```

## websocket connection
```
@protocol GCDWebSocketServerTransport <NSObject>

@optional

- (void)transportWillBegin:(GCDWebServerConnection *)connection;
- (void)transportWillEnd:(GCDWebServerConnection *)connection;
- (void)transport:(GCDWebServerConnection *)connection received:(GCDWebSocketMessage)message;

@end
```
