//
//  Errors.m
//  BonjourEcho
//
//  Created by Steve Madsen on 8/7/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import "Errors.h"

void LogErrno(NSString *message)
{
    char *errorString = strerror(errno);
    NSLog(@"%@: %s (%d)", message, errorString, errno);
}
