//
//  GCDTCPConnection.m
//  SimpleEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#include <sys/socket.h>

#import "GCDTCPConnection.h"
#import "Errors.h"

@implementation GCDTCPConnection
{
    int _sock;
    dispatch_queue_t _queue;
    dispatch_source_t _readSource;
    dispatch_source_t _writeSource;
    NSMutableArray *_writeBuffer;
    NSUInteger _writeOffset;
}

- (id) initWithSocket:(int)sock queue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self)
    {
        _sock = sock;
        _queue = queue;

        /* Per Apple's documentation, we need to set O_NONBLOCK and SO_NOSIGPIPE
         * on the socket.
         *
         * O_NONBLOCK avoids a read or write operation getting stuck if there is
         * insufficient data (for reads) or buffer space (for writes).
         *
         * SO_NOSIGPIPE prevents the system sending our process a SIGPIPE signal
         * when a write on a closed socket occurs. Instead, it returns EPIPE.
         * Signals don't mix well with dispatch queues. */
        fcntl(_sock, F_SETFL, O_NONBLOCK);
        setsockopt(_sock, SOL_SOCKET, SO_NOSIGPIPE, &(int){ 1 }, sizeof(int));

        _readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
                                             _sock,
                                             0,
                                             _queue);
        dispatch_source_set_event_handler(_readSource, ^{
            size_t available = dispatch_source_get_data(_readSource);
            char *buffer = malloc(available);
            if (buffer != NULL)
            {
                ssize_t length = read(_sock, buffer, available);
                if (length < 0)
                {
                    free(buffer);
                    LogErrno(@"read()");
                    dispatch_suspend(_readSource);
                }
                else if (length == 0)
                {
                    free(buffer);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self close];
                    });
                }
                else
                {
                    NSData *data = [NSData dataWithBytesNoCopy:buffer length:length];

                    if (_dataReceived != nil)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _dataReceived(self, data);
                        });
                    }
                }
            }
            else
            {
                LogErrno(@"Cannot allocate memory for received data");
                dispatch_suspend(_readSource);
            }
        });
        dispatch_source_set_cancel_handler(_readSource, ^{
            close(_sock);
            dispatch_async(dispatch_get_main_queue(), ^{
                _completion();
            });
        });

        _writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE,
                                              _sock,
                                              0,
                                              _queue);
        dispatch_source_set_event_handler(_writeSource, ^{
            if ([_writeBuffer count] == 0)
            {
                /* There is nothing more to write, so suspend the event source
                 * until we have more data. */
                dispatch_suspend(_writeSource);
            }
            else
            {
                /* Get the next block of data to send. If _writeOffset is
                 * non-zero, the last time we wrote to the socket, it didn't
                 * accept all of the data. Adjust the pointer and length
                 * accordingly. */
                NSData *data = [_writeBuffer objectAtIndex:0];
                const char *bytes = [data bytes] + _writeOffset;
                NSUInteger length = [data length] - _writeOffset;

                ssize_t wrote = write(_sock, bytes, length);
                if (wrote < 0)
                {
                    LogErrno(@"write()");
                    [self close];
                }
                else
                {
                    NSLog(@"Server: wrote %ld bytes", wrote);
                    if ((NSUInteger)wrote < length)
                    {
                        /* The socket couldn't take all of the data we wrote,
                         * so we need to adjust _writeOffset and try the
                         * remaining bytes when there is more room. */
                        _writeOffset += wrote;
                    }
                    else
                    {
                        [_writeBuffer removeObjectAtIndex:0];
                        _writeOffset = 0;
                    }
                }
            }
        });

        dispatch_resume(_readSource);

        /* Resuming _writeSource at this point will result in a flood of
         * events telling you that there is room to write, but until we have
         * something to write, this is a waste of cycles. We'll resume the
         * source in -writeData:, below. */

        _writeBuffer = [NSMutableArray array];
    }

    return self;
}

- (void) close
{
    if (_writeSource != NULL)
    {
        if ([_writeBuffer count] == 0)
        {
            // Releasing a suspended dispatch source will crash.
            dispatch_resume(_writeSource);
        }
        dispatch_source_cancel(_writeSource);
        dispatch_release(_writeSource);
        _writeSource = NULL;
    }
    if (_readSource != NULL)
    {
        dispatch_source_cancel(_readSource);
        dispatch_release(_readSource);
        _readSource = NULL;
    }
}

- (void) writeData:(NSData *)data
{
    [_writeBuffer addObject:data];
    if ([_writeBuffer count] == 1)
    {
        dispatch_resume(_writeSource);
    }
}

@end
