//
//  ViewController.m
//  PubSub
//
//  Created by Steve Madsen on 8/9/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
{
    FayeClient *_faye;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.delegateMessage.text = @"";
    self.messageLabel.text = @"";

    _faye = [[FayeClient alloc] initWithURLString:@"http://localhost:9292/faye" channel:@"/channel"];
    _faye.delegate = self;
    [_faye connectToServer];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) connectedToServer
{
    NSLog(@"Connected");
    self.delegateMessage.text = @"Connected";
}

- (void) socketDidFailWithError:(NSError *)error
{
    NSLog(@"Socket error: %@", [error localizedDescription]);
    self.delegateMessage.text = [NSString stringWithFormat:@"Socket error: %@", [error localizedDescription]];
}

- (void) disconnectedFromServer
{
    NSLog(@"Disconnected");
    self.delegateMessage.text = @"Disconnected";
}

- (void) messageReceived:(NSDictionary *)messageDict
{
    self.messageLabel.text = [NSString stringWithFormat:@"%@", messageDict];
}

@end
