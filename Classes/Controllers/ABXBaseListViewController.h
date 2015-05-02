//
//  ABXBaseListViewController.h
//  Sample Project
//
//  Created by Stuart Hall on 22/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ABXBaseListViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UILabel *errorLabel;

+ (void)showFromController:(UIViewController*)controller;

- (void)showError:(NSString*)error;

@end
