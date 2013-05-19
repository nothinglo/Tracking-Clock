//
//  UGFriendTableViewController.h
//  Tracking Clock
//
//  Created by nothinglo on 13/5/18.
//  Copyright (c) 2013年 nothinglo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "JSONKit.h"

@interface UGFriendTableViewController : UITableViewController<UIAlertViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate> {
    IBOutlet UISearchBar *searchBar;
}

@property (strong, nonatomic) NSArray *allFriendDatas;
@property (strong, nonatomic) NSMutableArray *filteredFriendDatas;

@property (strong, nonatomic) NSArray *allFriendImagesURLs;
@property (strong, nonatomic) NSMutableArray *filteredFriendImagesURLs;

@property (strong, nonatomic) UIActivityIndicatorView *loadingIndicator;
@property (strong, nonatomic) UIImageView *waitingBackground;

@end
