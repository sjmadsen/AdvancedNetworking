//
//  Server.h
//  BonjourEcho
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Server : NSObject

- (id) init;
- (BOOL) listen;

@end
