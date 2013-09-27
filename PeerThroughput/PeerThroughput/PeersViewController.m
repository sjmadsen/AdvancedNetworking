//
//  PeersViewController.m
//  PeerThroughput
//
//  Created by Steve Madsen on 9/26/13.
//  Copyright (c) 2013 Light Year Software, LLC. All rights reserved.
//

#import "PeersViewController.h"
#import "PeerCell.h"

@interface PeersViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

- (IBAction) addPeers:(id)sender;

@end

@implementation PeersViewController
{
    MCPeerID *_myPeerID;
    MCSession *_session;
    MCAdvertiserAssistant *_advertiserAssistant;
    NSMutableDictionary *_peerData;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _myPeerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    _session = [[MCSession alloc] initWithPeer:_myPeerID];
    _session.delegate = self;
    _advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:@"peerthroughput" discoveryInfo:nil session:_session];
    [_advertiserAssistant start];

    _peerData = [NSMutableDictionary dictionary];
}

- (void)addPeers:(id)sender
{
    MCBrowserViewController *browser = [[MCBrowserViewController alloc] initWithServiceType:@"peerthroughput" session:_session];
    browser.delegate = self;
    browser.minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers;
    browser.maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers;

    [self presentViewController:browser animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_session.connectedPeers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PeerCell";
    PeerCell *cell = (PeerCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    MCPeerID *peer = _session.connectedPeers[indexPath.row];
    cell.nameLabel.text = peer.displayName;

    NSDictionary *data = _peerData[peer];
    NSNumber *latency = data[@"latency"];
    if (latency) {
        cell.latencyLabel.text = [NSString stringWithFormat:@"%.1f ms", [latency doubleValue] * 1000.0];
    } else {
        cell.latencyLabel.text = nil;
    }

    NSNumber *throughput = data[@"throughput"];
    if (throughput) {
        cell.throughputLabel.text = [NSString stringWithFormat:@"%.1f Kbps", [throughput doubleValue] / 1000 * 8];
    } else {
        cell.throughputLabel.text = nil;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    MCPeerID *peer = _session.connectedPeers[indexPath.row];
    NSLog(@"Testing latency and throughput of %@", peer);
    NSMutableDictionary *peerData = _peerData[peer];

    NSData *ping = [@"ping" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    if ([_session sendData:ping toPeers:@[peer] withMode:MCSessionSendDataReliable error:&error]) {
        peerData[@"pingSent"] = @([NSDate timeIntervalSinceReferenceDate]);
    } else {
        NSLog(@"Error sending ping: %@", error);
    }
}

#pragma mark - MCBrowserViewController delegate

- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    return YES;
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
}

#pragma mark - MCSession delegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnecting:
            NSLog(@"Connecting to %@", peerID);
            break;

        case MCSessionStateConnected:
            NSLog(@"Connected to %@", peerID);
            _peerData[peerID] = [NSMutableDictionary dictionary];
            break;

        case MCSessionStateNotConnected:
            NSLog(@"Lost connection to %@", peerID);
            [_peerData removeObjectForKey:peerID];
            break;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    const int dataSize = 64 * 1024;

    NSLog(@"Received data, %lu bytes", (unsigned long)[data length]);

    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([string isEqualToString:@"ping"]) {
        NSData *pong = [@"pong" dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        [session sendData:pong toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error];
    } else if ([string isEqualToString:@"pong"]) {
        NSTimeInterval pongReceived = [NSDate timeIntervalSinceReferenceDate];
        NSMutableDictionary *peerData = _peerData[peerID];
        if (peerData) {
            NSTimeInterval pingSent = [peerData[@"pingSent"] doubleValue];
            NSTimeInterval latency = pongReceived - pingSent;
            [peerData removeObjectForKey:@"pingSent"];
            peerData[@"latency"] = @(latency);

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });

            char *bytes = malloc(dataSize);
            if (bytes) {
                memset(bytes, '.', dataSize);
                bytes[0] = 'd';
                bytes[1] = 'a';
                bytes[2] = 't';
                bytes[3] = 'a';
                NSData *blob = [NSData dataWithBytesNoCopy:bytes length:dataSize];
                NSError *error;
                if ([session sendData:blob toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error]) {
                    peerData[@"dataSent"] = @([NSDate timeIntervalSinceReferenceDate]);
                } else {
                    NSLog(@"Error sending throughput blob: %@", error);
                }
            } else {
                NSLog(@"Failed to malloc memory for throughput blob, errno=%d", errno);
            }
        }
    } else if ([string hasPrefix:@"data"]) {
        NSData *received = [@"received" dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        [session sendData:received toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error];
    } else if ([string isEqualToString:@"received"]) {
        NSTimeInterval received = [NSDate timeIntervalSinceReferenceDate];
        NSMutableDictionary *peerData = _peerData[peerID];
        if (peerData) {
            NSTimeInterval sent = [peerData[@"dataSent"] doubleValue];
            NSTimeInterval roundtrip = received - sent;
            NSLog(@"%d bytes in %.6f seconds", dataSize, roundtrip);
            double throughput = (double)dataSize / roundtrip;
            [peerData removeObjectForKey:@"dataSent"];
            peerData[@"throughput"] = @(throughput);

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
}

@end
