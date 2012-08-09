//
//  Server.h
//  SimpleEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Server : NSObject

- (id) initWithPort:(uint16_t)port;
- (BOOL) listen;

@end
