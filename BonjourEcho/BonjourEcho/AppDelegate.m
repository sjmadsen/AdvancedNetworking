//
//  AppDelegate.m
//  BonjourEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#include <arpa/inet.h>

#import "AppDelegate.h"
#import "Server.h"

@implementation AppDelegate
{
    Server *_server;
    NSNetServiceBrowser *_browser;
    NSMutableSet *_services;
    Client *_client;
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.serverReply = @"";

    _server = [[Server alloc] init];
    [_server listen];

    _services = [NSMutableSet set];
    _browser = [[NSNetServiceBrowser alloc] init];
    _browser.delegate = self;
    [_browser searchForServicesOfType:@"_lys-echo._tcp" inDomain:@""];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [_services addObject:aNetService];
    aNetService.delegate = self;
    [aNetService resolveWithTimeout:5.0];
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender
{
    struct sockaddr_in *sin = (struct sockaddr_in *)[[[sender addresses] objectAtIndex:0] bytes];
    char name[INET6_ADDRSTRLEN];
    if (inet_ntop(sin->sin_family, &sin->sin_addr.s_addr, name, sizeof(name)))
    {
        NSLog(@"Found echo service at %s:%u", name, ntohs(sin->sin_port));
    }

    self.canSend = YES;
}

- (void) netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    // ...
}

- (IBAction) sendText:(id)sender
{
    if (_client == nil)
    {
        _client = [[Client alloc] initWithNetService:[_services anyObject]];
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
