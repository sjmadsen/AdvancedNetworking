//
//  ViewController.m
//  GameKitChat
//
//  Created by Steve Madsen on 8/8/12.
//  Copyright (c) 2012 Steven Madsen. All rights reserved.
//

#import <GameKit/GameKit.h>

#import "ViewController.h"

@implementation ViewController
{
    GKSession *_session;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _session = [[GKSession alloc] initWithSessionID:nil
                                        displayName:nil
                                        sessionMode:GKSessionModePeer];
    _session.delegate = self;
    [_session setDataReceiveHandler:self withContext:NULL];

    [self.textField becomeFirstResponder];
    self.replyLabel.text = @"";
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _session.available = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    _session.available = NO;
    [_session disconnectFromAllPeers];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) session:(GKSession *)session didFailWithError:(NSError *)error
{
    NSLog(@"GKSession error: %@", [error localizedDescription]);
}

- (void) session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    switch (state)
    {
        case GKPeerStateAvailable:
            NSLog(@"Found peer %@", peerID);
            [session connectToPeer:peerID withTimeout:5.0];
            break;

        case GKPeerStateConnected:
            NSLog(@"Connected to peer %@", peerID);
            break;

        case GKPeerStateDisconnected:
            NSLog(@"Disconnected from peer %@", peerID);
            break;

        case GKPeerStateUnavailable:
            NSLog(@"Peer %@ is unavailable", peerID);

        default:
            break;
    }
}

- (void) session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    NSError *error;
    if (![session acceptConnectionFromPeer:peerID error:&error])
    {
        NSLog(@"Error accepting connection: %@", [error localizedDescription]);
    }
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peerID inSession:(GKSession *)session context:(void *)context
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.replyLabel.text = string;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    NSData *stringData = [textField.text dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    if ([_session sendDataToAllPeers:stringData
                        withDataMode:GKSendDataReliable
                               error:&error])
    {
        NSLog(@"Sent %u bytes", [stringData length]);
    }
    else
    {
        NSLog(@"Send data failed: %@", [error localizedDescription]);
    }

    textField.text = @"";

    return YES;
}

@end
