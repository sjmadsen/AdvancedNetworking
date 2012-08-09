//
//  AppDelegate.h
//  SimpleEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Client.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, ClientDelegate>

@property (assign) IBOutlet NSWindow *window;

@property NSString *host;
@property NSUInteger port;
@property NSString *textToSend;
@property NSString *serverReply;

- (IBAction) sendText:(id)sender;

@end
