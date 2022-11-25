//
//  GCDWebServerConnection+Internal.h
//  GCDWebServer
//
//  Created by zhuruhong on 2022/11/25.
//

#import <GCDWebServer/GCDWebServerConnection.h>
#import <GCDWebServer/GCDWebServer.h>

NS_ASSUME_NONNULL_BEGIN

@interface GCDWebServerConnection (Internal)

- (instancetype)initWithServer:(GCDWebServer*)server localAddress:(NSData*)localAddress remoteAddress:(NSData*)remoteAddress socket:(CFSocketNativeHandle)socket;

@end

#pragma mark - read & write

typedef void (^ReadDataCompletionBlock)(BOOL success);
typedef void (^ReadHeadersCompletionBlock)(NSData* extraData);
typedef void (^ReadBodyCompletionBlock)(BOOL success);

typedef void (^WriteDataCompletionBlock)(BOOL success);
typedef void (^WriteHeadersCompletionBlock)(BOOL success);
typedef void (^WriteBodyCompletionBlock)(BOOL success);

@interface GCDWebServerConnection (Read)
- (void)readData:(NSMutableData*)data withLength:(NSUInteger)length completionBlock:(ReadDataCompletionBlock)block;
- (void)readHeaders:(NSMutableData*)headersData withCompletionBlock:(ReadHeadersCompletionBlock)block;
- (void)readBodyWithRemainingLength:(NSUInteger)length completionBlock:(ReadBodyCompletionBlock)block;
- (void)readNextBodyChunk:(NSMutableData*)chunkData completionBlock:(ReadBodyCompletionBlock)block;
@end

@interface GCDWebServerConnection (Write)
- (void)writeData:(NSData*)data withCompletionBlock:(WriteDataCompletionBlock)block;
- (void)writeHeadersWithCompletionBlock:(WriteHeadersCompletionBlock)block;
- (void)writeBodyWithCompletionBlock:(WriteBodyCompletionBlock)block;
@end

NS_ASSUME_NONNULL_END
