//
//  GCDWebSocketServer.h
//  Pods
//
//  Created by ruhong zhu on 2021/9/20.
//

#import <GCDWebServer/GCDWebServer.h>
#import "GCDWebSocketDefines.h"

@class GCDWebServerConnection;

@protocol GCDWebSocketServerTransport <NSObject>

@optional

- (void)transportWillBegin:(GCDWebServerConnection *)connection;
- (void)transportWillEnd:(GCDWebServerConnection *)connection;
- (void)transport:(GCDWebServerConnection *)connection received:(GCDWebSocketMessage)message;

@end

@interface GCDWebSocketServer : GCDWebServer

/// Sets the timeout value for connections，default is 30 second
@property (nonatomic, assign) NSTimeInterval timeout;
/// Sets the transport for the connections
@property (nonatomic, weak) id<GCDWebSocketServerTransport> transport;

@end

@interface GCDWebSocketServer (Transport) <GCDWebSocketServerTransport>

@end
