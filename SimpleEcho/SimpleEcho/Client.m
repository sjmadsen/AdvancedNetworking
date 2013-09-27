//
//  Client.m
//  SimpleEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import "Client.h"

@implementation Client
{
    NSString *_host;
    uint16_t _port;
    NSInputStream *_readStream;
    NSOutputStream *_writeStream;
    NSMutableArray *_writeBuffer;
    NSUInteger _writeOffset;
}

- (id) initWithHost:(NSString *)host port:(uint16_t)port
{
    self = [super init];
    if (self)
    {
        _host = [host copy];
        _port = port;
    }

    return self;
}

- (void) connect
{
    NSLog(@"Client: connecting to %@:%u", _host, _port);

    CFReadStreamRef readStreamRef;
    CFWriteStreamRef writeStreamRef;
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                       (__bridge CFStringRef)_host,
                                       (uint32_t)_port,
                                       &readStreamRef,
                                       &writeStreamRef);

    _readStream = CFBridgingRelease(readStreamRef);
    _readStream.delegate = self;
    [_readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    _writeStream = CFBridgingRelease(writeStreamRef);
    _writeStream.delegate = self;
    [_writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    [_readStream open];
    [_writeStream open];

    _writeBuffer = [NSMutableArray array];
}

- (void) disconnect
{
    [_readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _readStream.delegate = nil;
    [_readStream close];
    _readStream = nil;

    [_writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _writeStream.delegate = nil;
    [_writeStream close];
    _writeStream = nil;

    _isConnected = NO;

    [_delegate clientDidDisconnect:self];
}

- (void) send:(NSString *)string
{
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    if ([_writeBuffer count] == 0)
    {
        /* If _writeBuffer is empty, there is nothing else waiting to send, so
         * create the buffer and immediately write it to the stream. */
        [_writeBuffer addObject:stringData];
        [self sendPendingData];
    }
    else
    {
        /* If _writeBuffer isn't empty, then append this new message to what's
         * already waiting. */
        [_writeBuffer addObject:stringData];
    }
}

- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
            if (stream == _writeStream)
            {
                NSLog(@"Client: connected");
                _isConnected = YES;
            }
            break;

        case NSStreamEventHasSpaceAvailable:
            [self sendPendingData];
            break;

        case NSStreamEventHasBytesAvailable:
            [self read];
            break;

        case NSStreamEventEndEncountered:
            [self disconnect];
            break;

        case NSStreamEventErrorOccurred:
            NSLog(@"stream error");
            break;

        case NSStreamEventNone:
            break;
    }
}

- (void) sendPendingData
{
    if (_isConnected && [_writeBuffer count] > 0)
    {
        NSData *data = [_writeBuffer objectAtIndex:0];
        NSUInteger length = [data length] - _writeOffset;
        uint8_t *bytes = (uint8_t *)[data bytes];
        NSInteger written = [_writeStream write:bytes + _writeOffset maxLength:length];
        NSLog(@"Client: wrote %ld bytes", written);
        if (written < 0)
        {
            /* An error occurred.
             *
             * I'm not sure if this will trigger an error event on the stream or
             * not. */
        }
        else if ((NSUInteger)written < length)
        {
            /* A partial write: remember how much was written. We'll get another
             * callback when there is room for more. */
            _writeOffset += written;
        }
        else
        {
            /* Everything was written: we can dispose of data. */
            [_writeBuffer removeObjectAtIndex:0];
            _writeOffset = 0;
        }
    }
}

- (void) read
{
    uint8_t bytes[128];
    NSInteger bytesRead = [_readStream read:bytes maxLength:sizeof(bytes)];
    if (bytesRead < 0)
    {
        /* An error occurred.
         *
         * As with writes, I'm not sure if this triggers a stream error event. */
    }
    else if (bytesRead > 0)
    {
        NSLog(@"Client: read %lu bytes", bytesRead);
        NSString *string = [[NSString alloc] initWithBytes:bytes length:bytesRead encoding:NSUTF8StringEncoding];
        [_delegate client:self didReceiveString:string];
    }
}

@end
