//
//  ViewController.h
//  PubSub
//
//  Created by Steve Madsen on 8/9/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FayeClient.h"

@interface ViewController : UIViewController <FayeClientDelegate>

@property IBOutlet UILabel *delegateMessage;
@property IBOutlet UILabel *messageLabel;

@end
