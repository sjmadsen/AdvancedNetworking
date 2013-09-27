//
//  PeerCell.h
//  PeerThroughput
//
//  Created by Steve Madsen on 9/26/13.
//  Copyright (c) 2013 Light Year Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PeerCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *latencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *throughputLabel;

@end
