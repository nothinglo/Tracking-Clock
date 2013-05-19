//
//  UGFriendTableViewController.m
//  Tracking Clock
//
//  Created by nothinglo on 13/5/18.
//  Copyright (c) 2013年 nothinglo. All rights reserved.
//

#import "UGFriendTableViewController.h"
#import "UGFriendCell.h"
#import "UGDataSource.h"
#import "AsyncImageView.h"
#import <QuartzCore/QuartzCore.h>

static NSString *UGFriendTablePictureByID = @"https://graph.facebook.com/%@/picture?type=normal";

NSString * const UGFriendTableDictKeyData = @"data";
NSString * const UGFriendTableDictKeyName = @"name";
NSString * const UGFriendTableDictKeyID = @"id";

@interface UGFriendTableViewController ()

@end

@implementation UGFriendTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
#pragma mark - Method

- (void)accessFacebookAccountWithPermission:(NSArray *)permissions Handler:(void (^)(ACAccount *account))handler {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *facebookAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    NSDictionary *facebookRequestOptions = @{
                                             ACFacebookAppIdKey: @"441031075986395",
                                             ACFacebookPermissionsKey: permissions,
                                             ACFacebookAudienceKey: ACFacebookAudienceOnlyMe,
                                             };
    [accountStore requestAccessToAccountsWithType:facebookAccountType
                                          options:facebookRequestOptions
                                       completion:^(BOOL granted, NSError *error) {
                                           if (granted) {
                                               NSArray *accounts = [accountStore
                                                                    accountsWithAccountType:facebookAccountType];
                                               ACAccount *account = [accounts lastObject];
                                               if (handler) handler(account);
                                           } else {
                                               NSLog(@"Auth Error: %@", [error localizedDescription]);
                                           }
                                       }];
}

#pragma mark - Layout

- (void)setViewLayout {
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.waitingBackground = [[UIImageView alloc] initWithFrame:self.tableView.bounds];
    self.waitingBackground.image = [UIImage imageNamed:@"Default.png"];
    self.waitingBackground.alpha = 0.5;
    self.loadingIndicator.center = CGPointMake(160, 165);
    
    [self.tableView addSubview:self.waitingBackground];
    [self.tableView addSubview:self.loadingIndicator];
}
#pragma mark - AlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if(buttonIndex == 1) {
        [self loadingFriendsData];
    }
}
- (void)loadingFriendsData {
    [self.loadingIndicator startAnimating];
    
    [self accessFacebookAccountWithPermission:@[@"user_about_me"] Handler:^(ACAccount *facebookAccount){
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                requestMethod:SLRequestMethodGET
                                                          URL:[NSURL URLWithString:@"https://graph.facebook.com/me/friends"]
                                                   parameters:@{}];
        request.account = facebookAccount;
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if (!error) {
                NSDictionary *responseDict = [responseData objectFromJSONData];
                self.allFriendDatas = responseDict[UGFriendTableDictKeyData];
                NSMutableArray *imageURLs = [NSMutableArray new];
                for(NSDictionary *friend in self.allFriendDatas) {
                    NSString *path =
                    [NSString stringWithFormat:UGFriendTablePictureByID, friend[UGFriendTableDictKeyID]];
                    [imageURLs addObject:[NSURL URLWithString:path]];
                }
                self.allFriendImagesURLs = [NSArray arrayWithArray:imageURLs];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.loadingIndicator stopAnimating];
                    self.waitingBackground.hidden = YES;
                    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
                });
            } else {
                NSLog(@"%@", [error localizedDescription]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:@"Please check your internet connection"
                                                                       delegate:self
                                                              cancelButtonTitle:@"Cancel"
                                                              otherButtonTitles:@"Refresh", nil];
                    [alertView show];
                });
            }
        }];
    }];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.filteredFriendDatas = [NSMutableArray new];
    self.filteredFriendImagesURLs = [NSMutableArray new];
    [self setViewLayout];
    [self loadingFriendsData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredFriendDatas count];
    } else {
        return [self.allFriendDatas count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"friendCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UGFriendCell *friendCell = (UGFriendCell *)cell;
    if(tableView == self.searchDisplayController.searchResultsTableView) {
        friendCell.friendName.text = self.filteredFriendDatas[indexPath.row][UGFriendTableDictKeyName];
        [[AsyncImageLoader sharedLoader] cancelLoadingImagesForTarget:friendCell.friendImage];
        friendCell.friendImage.imageURL = [self.filteredFriendImagesURLs objectAtIndex:indexPath.row];
    } else {
        friendCell.friendName.text = self.allFriendDatas[indexPath.row][UGFriendTableDictKeyName];
        [[AsyncImageLoader sharedLoader] cancelLoadingImagesForTarget:friendCell.friendImage];
        friendCell.friendImage.imageURL = [self.allFriendImagesURLs objectAtIndex:indexPath.row];
    }
    return cell;
}

#pragma mark - searchDisplayController Delegate

- (void)searchForTerm:(NSString *)searchText {
    [self.filteredFriendDatas removeAllObjects];
    [self.filteredFriendImagesURLs removeAllObjects];
    for (NSUInteger index = 0; index < [self.allFriendDatas count]; ++index)
    {
        NSDictionary *friend = [self.allFriendDatas objectAtIndex:index];
        NSRange nameRange = [friend[UGFriendTableDictKeyName] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if(nameRange.location != NSNotFound)
        {
            [self.filteredFriendDatas addObject:friend];
            [self.filteredFriendImagesURLs addObject:[self.allFriendImagesURLs objectAtIndex:index]];
        }
    }
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self searchForTerm:searchString];
    return YES;
}
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    tableView.rowHeight = 55;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
