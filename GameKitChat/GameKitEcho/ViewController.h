//
//  ViewController.h
//  GameKitChat
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
    <UITextFieldDelegate, GKSessionDelegate>

@property IBOutlet UITextField *textField;
@property IBOutlet UILabel *replyLabel;

@end
