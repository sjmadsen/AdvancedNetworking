//
//  AppDelegate.m
//  SimpleEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import "AppDelegate.h"
#import "Server.h"

@implementation AppDelegate
{
    Server *_server;
    Client *_client;
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.host = @"localhost";
    self.port = 5000;
    self.serverReply = @"";

    _server = [[Server alloc] initWithPort:(uint16_t)self.port];
    [_server listen];
}

- (IBAction) sendText:(id)sender
{
    if (_client == nil)
    {
        _client = [[Client alloc] initWithHost:self.host port:self.port];
        [_client connect];
        _client.delegate = self;
    }

    [_client send:self.textToSend];
    self.textToSend = @"";
}

- (void) client:(Client *)client didReceiveString:(NSString *)string
{
    self.serverReply = string;
}

- (void) clientDidDisconnect:(Client *)client
{
    _client = nil;
}

@end
