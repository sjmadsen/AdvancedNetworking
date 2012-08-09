//
//  Server.m
//  BonjourEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#import "Server.h"
#import "Errors.h"
#import "GCDTCPConnection.h"

@implementation Server
{
    int _listenSocket;
    NSNetService *_netService;
    dispatch_source_t _listenSource;
    dispatch_queue_t _queue;
    NSMutableSet *_connections;
}

- (id) init
{
    self = [super init];
    if (self)
    {
        _queue = dispatch_get_main_queue();
    }

    return self;
}

- (BOOL) listen
{
    _listenSocket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    sin.sin_port = 0;
    sin.sin_addr.s_addr = INADDR_ANY;

    if (bind(_listenSocket, (struct sockaddr *)&sin, sizeof(sin)) < 0)
    {
        LogErrno(@"Failed to bind TCP listen socket");
        return NO;
    }

    socklen_t sin_length = sizeof(sin);
    if (getsockname(_listenSocket, (struct sockaddr *)&sin, &sin_length) < 0)
    {
        LogErrno(@"getsockname()");
        return NO;
    }

    _netService = [[NSNetService alloc] initWithDomain:@""
                                                  type:@"_lys-echo._tcp"
                                                  name:@""
                                                  port:ntohs(sin.sin_port)];
    [_netService publish];

    if (listen(_listenSocket, 1) < 0)
    {
        LogErrno(@"Failed to listen");
        return NO;
    }

    NSLog(@"Server is advertising the service on Bonjour on port %u", ntohs(sin.sin_port));

    _listenSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
                                           _listenSocket,
                                           0,
                                           _queue);

    dispatch_source_set_event_handler(_listenSource, ^{
        struct sockaddr_in clientSin;
        socklen_t clientSinLength = sizeof(clientSin);
        int clientSocket = accept(_listenSocket, (struct sockaddr *)&clientSin, &clientSinLength);
        if (clientSocket >= 0)
        {
            char clientName[INET6_ADDRSTRLEN];
            if (inet_ntop(clientSin.sin_family, &clientSin.sin_addr.s_addr, clientName, sizeof(clientName)))
            {
                NSLog(@"Server: accepted connection from %s", clientName);
            }

            GCDTCPConnection *connection =
                [[GCDTCPConnection alloc] initWithSocket:clientSocket queue:_queue];
            __weak GCDTCPConnection *weakConnection = connection;
            connection.completion = ^{
                [_connections removeObject:weakConnection];
            };
            connection.dataReceived = ^(GCDTCPConnection *conn, NSData *data) {
                NSLog(@"Server: received %ld bytes", [data length]);
                [conn writeData:data];
            };

            [_connections addObject:connection];
        }
        else
        {
            LogErrno(@"accept() failed");
        }
    });

    dispatch_source_set_cancel_handler(_listenSource, ^{
        close(_listenSocket);
    });

    _connections = [NSMutableSet set];
    dispatch_resume(_listenSource);
    
    return YES;
}

@end
