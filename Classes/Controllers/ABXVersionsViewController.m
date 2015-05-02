//
//  ABXVersionsViewController.m
//
//  Created by Stuart Hall on 22/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXVersionsViewController.h"

#import "ABXVersion.h"
#import "ABXVersionTableViewCell.h"
#import "NSString+ABXLocalized.h"

@interface ABXVersionsViewController ()

@property (nonatomic, strong) NSArray *versions;

@end

@implementation ABXVersionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [@"Versions" localizedString];
    
    if (![ABXApiClient isInternetReachable]) {
        [self.activityView stopAnimating];
        [self showError:[@"No Internet" localizedString]];
    }
    else {
        [self fetchVersions];
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

- (void)fetchVersions
{
    [ABXVersion fetch:^(NSArray *versions, ABXResponseCode responseCode, NSInteger httpCode, NSError *error) {
        [self.activityView stopAnimating];
        if (responseCode == ABXResponseCodeSuccess) {
            self.versions = versions;
            [self.tableView reloadData];
            
            if (versions.count == 0) {
                [self showError:[@"No Versions" localizedString]];
            }
        }
        else {
            [self showError:[@"Versions Error" localizedString]];
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
    return self.versions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VersionCell";
    
    ABXVersionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[ABXVersionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row < self.versions.count) {
        [cell setVersion:self.versions[indexPath.row]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.versions.count) {
        return [ABXVersionTableViewCell heightForVersion:self.versions[indexPath.row]
                                               withWidth:CGRectGetWidth(self.tableView.frame)];
    }
    return 0;
}


@end
