//
//  PeersViewController.h
//  PeerThroughput
//
//  Created by Steve Madsen on 9/26/13.
//  Copyright (c) 2013 Light Year Software, LLC. All rights reserved.
//

@import UIKit;
@import MultipeerConnectivity;

@interface PeersViewController : UITableViewController <MCBrowserViewControllerDelegate, MCAdvertiserAssistantDelegate, MCSessionDelegate>

@end
