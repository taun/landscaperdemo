//
//  ABXBaseListViewController.m
//  Sample Project
//
//  Created by Stuart Hall on 22/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXBaseListViewController.h"

#import "ABXNavigationController.h"

#import "NSString+ABXLocalized.h"

@interface ABXBaseListViewController()

@end

@implementation ABXBaseListViewController

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource= nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (void)showFromController:(UIViewController*)controller
{
    ABXBaseListViewController *viewController = [[self alloc] init];
    UINavigationController *nav = [[ABXNavigationController alloc] initWithRootViewController:viewController];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Show as a sheet on iPad
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [controller presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UI

- (void)setupUI
{
    // Table view
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.dataSource = (id<UITableViewDataSource>)self;
    self.tableView.delegate = (id<UITableViewDelegate>)self;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 44)];
    self.tableView.tableFooterView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    // Powered by
    UIButton *appbotButton = [UIButton buttonWithType:UIButtonTypeCustom];
    appbotButton.frame = CGRectMake(0, CGRectGetHeight(self.view.frame) - 33, CGRectGetWidth(self.view.frame), 33);
    appbotButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    [appbotButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [appbotButton setTitle:[[@"Powered by" localizedString] stringByAppendingString:@" Appbot"] forState:UIControlStateNormal];
    appbotButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    appbotButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [appbotButton addTarget:self action:@selector(onAppbot) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:appbotButton];
    
    // Powered by seperator
    UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 33, CGRectGetWidth(self.view.frame), 1)];
    seperator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    seperator.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [self.view addSubview:seperator];
    
    // Activity Indicator
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityView.center = CGPointMake(CGRectGetMidX(self.view.bounds), 100);
    [self.activityView startAnimating];
    self.activityView.hidesWhenStopped = YES;
    self.activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.activityView];
    
    // Only show the close button if we are at the root controller
    if (self.navigationController.viewControllers.count == 1) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                 target:self
                                                 action:@selector(onDone)];
    }
}

#pragma mark - Buttons

- (void)onDone
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onAppbot
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://appbot.co"]];
}

#pragma mark - Errors

- (void)showError:(NSString*)error
{
    if (!self.errorLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 150, CGRectGetWidth(self.tableView.bounds) - 20, 100)];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.text = error;
        label.font = [UIFont systemFontOfSize:15];
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:label];
        self.errorLabel = label;
    }
    else {
        self.errorLabel.text = error;
        self.errorLabel.hidden = NO;
    }
}

@end
