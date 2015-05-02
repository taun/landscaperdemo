//
//  ABXNotificationsViewController.m
//  Sample Project
//
//  Created by Stuart Hall on 18/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXNotificationsViewController.h"

#import "ABXNotificationTableViewCell.h"
#import "NSString+ABXLocalized.h"

@interface ABXNotificationsViewController ()

@property (nonatomic, strong) NSArray *notifications;

@end

@implementation ABXNotificationsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [@"Notifications" localizedString];
    
    if (![ABXApiClient isInternetReachable]) {
        [self.activityView stopAnimating];
        [self showError:[@"No Internet" localizedString]];
    }
    else {
        [self fetchNotifications];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

- (void)onDone
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Fetching

- (void)fetchNotifications
{
    [ABXNotification fetch:^(NSArray *notifications, ABXResponseCode responseCode, NSInteger httpCode, NSError *error) {
        [self.activityView stopAnimating];
        if (responseCode == ABXResponseCodeSuccess) {
            self.notifications = notifications;
            [self.tableView reloadData];
            
            if (notifications.count == 0) {
                [self showError:[@"No Notifications" localizedString]];
            }
        }
        else {
            [self showError:[@"Notifications Error" localizedString]];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NotificationCell";
    
    ABXNotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[ABXNotificationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row < self.notifications.count) {
        [cell setNotification:self.notifications[indexPath.row]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.notifications.count) {
        return [ABXNotificationTableViewCell heightForNotification:self.notifications[indexPath.row]
                                               withWidth:CGRectGetWidth(self.tableView.frame)];
    }
    return 44;
}


@end
