//
//  UGFriendCell.h
//  Tracking Clock
//
//  Created by nothinglo on 13/5/18.
//  Copyright (c) 2013年 nothinglo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UGCheckButton.h"

@interface UGFriendCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *friendImage;
@property (strong, nonatomic) IBOutlet UILabel *friendName;
@property (strong, nonatomic) IBOutlet UGCheckButton *checkMark;

@end
