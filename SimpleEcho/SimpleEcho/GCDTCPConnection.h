//
//  GCDTCPConnection.h
//  SimpleEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDTCPConnection : NSObject

@property (copy) void (^completion)(void);
@property (copy) void (^dataReceived)(GCDTCPConnection *connection, NSData *data);

- (id) initWithSocket:(int)sock queue:(dispatch_queue_t)queue;
- (void) close;
- (void) writeData:(NSData *)data;

@end
