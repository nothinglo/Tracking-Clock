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

NSString * const UGFriendTableDictKeyData = @"data";
NSString * const UGFriendTableDictKeyName = @"name";
NSString * const UGFriendTableDictKeyID = @"id";

@interface UGFriendTableViewController ()

@end

@implementation UGFriendTableViewController

- (void)viewWillDisappear:(BOOL)animated {
    searchBar.delegate = nil;
    self.searchDisplayController.delegate = nil;
}
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
                                               double delayInSeconds = 0.5;
                                               dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                               dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                   [self.navigationController popViewControllerAnimated:YES];
                                               });
                                           }
                                       }];
}

#pragma mark - Layout

- (void)setViewLayout {
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.waitingBackground = [[UIImageView alloc] initWithFrame:self.tableView.bounds];
    self.waitingBackground.image = [UIImage imageNamed:@"Default.png"];
    self.waitingBackground.alpha = 0.7;
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
                                                   parameters:@{@"fields":@"id,name,picture"}];
        request.account = facebookAccount;
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if (!error) {
                NSDictionary *responseDict = [responseData objectFromJSONData];
                self.allFriendDatas = responseDict[UGFriendTableDictKeyData];
                self.allFriendCheckMark = [NSMutableArray new];
                NSMutableArray *imageURLs = [NSMutableArray new];
                for(NSDictionary *friend in self.allFriendDatas) {
                    NSString *path = friend[@"picture"][@"data"][@"url"];
                    [imageURLs addObject:[NSURL URLWithString:path]];
                    [self.allFriendCheckMark addObject:[NSNumber numberWithBool:NO]];
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
                    if(searchBar.delegate != nil)
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
    self.filteredFriendCheckMark = [NSMutableArray new];
    self.turnOFF = [UIImage imageNamed:@"cb_mono_off@2x.png"];
    self.turnON = [UIImage imageNamed:@"cb_mono_on@2x.png"];
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
        UIImage *image = [[self.filteredFriendCheckMark objectAtIndex:indexPath.row][@"mark"] boolValue] ? self.turnON : self.turnOFF;
        [friendCell.checkMark setBackgroundImage:image forState:UIControlStateNormal];
        friendCell.checkMark.indexInFilter = indexPath.row;
        friendCell.checkMark.indexInAll = -1;
    } else {
        friendCell.friendName.text = self.allFriendDatas[indexPath.row][UGFriendTableDictKeyName];
        friendCell.friendImage.image = nil;
        [[AsyncImageLoader sharedLoader] cancelLoadingImagesForTarget:friendCell.friendImage];
        friendCell.friendImage.imageURL = [self.allFriendImagesURLs objectAtIndex:indexPath.row];
        UIImage *image = [[self.allFriendCheckMark objectAtIndex:indexPath.row] boolValue] ? self.turnON : self.turnOFF;
        [friendCell.checkMark setBackgroundImage:image forState:UIControlStateNormal];
        friendCell.checkMark.indexInAll = indexPath.row;
        friendCell.checkMark.indexInFilter = -1;
    }
    return cell;
}
#pragma mark - searchDisplayController Delegate

- (void)searchForTerm:(NSString *)searchText {
    [self.filteredFriendDatas removeAllObjects];
    [self.filteredFriendImagesURLs removeAllObjects];
    [self.filteredFriendCheckMark removeAllObjects];
    for (NSUInteger index = 0; index < [self.allFriendDatas count]; ++index)
    {
        NSDictionary *friend = [self.allFriendDatas objectAtIndex:index];
        NSRange nameRange = [friend[UGFriendTableDictKeyName] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if(nameRange.location != NSNotFound)
        {
            [self.filteredFriendDatas addObject:friend];
            [self.filteredFriendImagesURLs addObject:[self.allFriendImagesURLs objectAtIndex:index]];
            NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [self.allFriendCheckMark objectAtIndex:index], @"mark",
                                        [NSNumber numberWithInteger:index], @"indexOfAll",
                                        nil];
            [self.filteredFriendCheckMark addObject:dic];
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

- (IBAction)tapTheCheckButton:(id)sender {
    UGCheckButton *button = (UGCheckButton *)sender;
    if(button.indexInAll >= 0) {
        BOOL value = ![self.allFriendCheckMark[button.indexInAll] boolValue];
        UIImage *image = value ? self.turnON : self.turnOFF;
        [button setBackgroundImage:image forState:UIControlStateNormal];
        [self.allFriendCheckMark replaceObjectAtIndex:button.indexInAll withObject:[NSNumber numberWithBool:value]];
    } else {
        BOOL value = ![self.filteredFriendCheckMark[button.indexInFilter][@"mark"] boolValue];
        UIImage *image = value ? self.turnON : self.turnOFF;
        [button setBackgroundImage:image forState:UIControlStateNormal];
        NSNumber *obj = [NSNumber numberWithBool:value];
        NSNumber *indexOfAll = [self.filteredFriendCheckMark objectAtIndex:button.indexInFilter][@"indexOfAll"];
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                                obj, @"mark",
                                indexOfAll, @"indexOfAll",
                                nil];
        [self.filteredFriendCheckMark replaceObjectAtIndex:button.indexInFilter withObject:dic];
        [self.allFriendCheckMark replaceObjectAtIndex:[indexOfAll integerValue] withObject:obj];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[indexOfAll integerValue] inSection:0];
        NSArray *arrayOfIndexPath = [NSArray arrayWithObject:indexPath];
        [self.tableView reloadRowsAtIndexPaths:arrayOfIndexPath withRowAnimation:UITableViewRowAnimationNone];
    }
}
@end
