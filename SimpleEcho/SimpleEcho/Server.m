//
//  Server.m
//  SimpleEcho
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
    uint16_t _port;
    int _listenSocket;
    dispatch_source_t _listenSource;
    dispatch_queue_t _queue;
    NSMutableSet *_connections;
}

- (id) initWithPort:(uint16_t)port
{
    self = [super init];
    if (self)
    {
        _port = port;
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
    sin.sin_port = htons(_port);
    sin.sin_addr.s_addr = INADDR_ANY;

    /* Setting SO_REUSEADDR prevents "address already in use" errors when
     * quitting and restarting the app before the system is willing to
     * completely release the socket. */
    setsockopt(_listenSocket, SOL_SOCKET, SO_REUSEADDR, &(int) { 1 }, sizeof(int));

    if (bind(_listenSocket, (struct sockaddr *)&sin, sizeof(sin)) < 0)
    {
        LogErrno(@"Failed to bind TCP listen socket");
        return NO;
    }

    if (listen(_listenSocket, 1) < 0)
    {
        LogErrno(@"Failed to listen");
        return NO;
    }

    NSLog(@"Server is listening on *:%u", _port);

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
