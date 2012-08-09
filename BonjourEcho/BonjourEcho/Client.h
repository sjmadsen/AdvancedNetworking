//
//  Client.h
//  BonjourEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ClientDelegate;

@interface Client : NSObject <NSStreamDelegate>

@property (weak) id<ClientDelegate> delegate;
@property (readonly) BOOL isConnected;

- (id) initWithNetService:(NSNetService *)netService;
- (void) connect;
- (void) send:(NSString *)string;

@end

@protocol ClientDelegate <NSObject>

- (void) client:(Client *)client didReceiveString:(NSString *)string;
- (void) clientDidDisconnect:(Client *)client;

@end