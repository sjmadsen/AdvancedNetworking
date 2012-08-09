//
//  AppDelegate.h
//  BonjourEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Client.h"

@interface AppDelegate : NSObject
    <NSApplicationDelegate,
     NSNetServiceBrowserDelegate,
     NSNetServiceDelegate,
     ClientDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (assign) BOOL canSend;
@property NSString *textToSend;
@property NSString *serverReply;

- (IBAction) sendText:(id)sender;

@end
