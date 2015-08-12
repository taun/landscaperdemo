//
//  MDBTutorialMasterTableViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 07/19/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBTutorialMasterTableViewController.h"
#import "MDBTutorialDetailContainerViewController.h"
#import "MDBAppModel.h"



@interface MDBTutorialMasterTableViewController ()

@end

@implementation MDBTutorialMasterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    if (self.defaultController) {
//        UIViewController* childController = [self.storyboard instantiateViewControllerWithIdentifier: self.defaultController];
//        [self.splitViewController showDetailViewController: childController sender: self];
//    }
    
    UIView *backgroundView = [[UIView alloc] initWithFrame: self.view.bounds];
//    backgroundView.backgroundColor = [UIColor yellowColor];
    backgroundView.backgroundColor = self.view.tintColor;
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"documentThumbnailPlaceholder1024"]];
    [backgroundView addSubview: imageView];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIVisualEffectView* visualEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleExtraLight]];
    [backgroundView addSubview: visualEffectView];
    visualEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(imageView, visualEffectView);
    [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|" options:0 metrics:nil views:viewsDictionary]];
    [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics:nil views:viewsDictionary]];
    [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[visualEffectView]|" options:0 metrics:nil views:viewsDictionary]];
    [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[visualEffectView]|" options:0 metrics:nil views:viewsDictionary]];
    
    self.tableView.backgroundView = backgroundView;
}
//HelpIntroductionControllerSegue

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
