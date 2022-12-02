//
//  GCDWebServerTimer.h
//  GCDWebSocket
//
//  Created by zhuruhong on 2022/12/2.
//

#import <Foundation/Foundation.h>

@interface GCDWebServerTimer : NSObject

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                        target:(id)target
                                      selector:(SEL)selector
                                      userInfo:(id)userInfo
                                       repeats:(BOOL)repeats;

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                        target:(id)target
                                      selector:(SEL)selector
                                      userInfo:(id)userInfo
                                       repeats:(BOOL)repeats
                                 dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval
                              target:(id)target
                            selector:(SEL)selector
                            userInfo:(id)userInfo
                             repeats:(BOOL)repeats
                       dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (void)schedule;
- (void)fire;
- (void)invalidate;

@end
