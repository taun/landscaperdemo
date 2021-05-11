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

@property (assign) BOOL     isBackgroundSetup;

@end

@implementation MDBTutorialMasterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.isBackgroundSetup)
    {
        UIView *backgroundView = [[UIView alloc] initWithFrame: self.view.bounds];
        backgroundView.backgroundColor = UIColor.systemBlueColor;

        UIImageView* imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"documentThumbnailPlaceholder1024"]];
        [backgroundView addSubview: imageView];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *viewsDictionary;
        UIVisualEffectView* visualEffectView;
        
        if (@available(iOS 13.0, *)) {
            visualEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleSystemMaterial]];
        } else {
            // Fallback on earlier versions
            visualEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleLight]];
       }
        [backgroundView addSubview: visualEffectView];
        visualEffectView.translatesAutoresizingMaskIntoConstraints = NO;
        viewsDictionary = NSDictionaryOfVariableBindings(imageView, visualEffectView);

        [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|" options:0 metrics:nil views:viewsDictionary]];
        [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics:nil views:viewsDictionary]];
        [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[visualEffectView]|" options:0 metrics:nil views:viewsDictionary]];
        [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[visualEffectView]|" options:0 metrics:nil views:viewsDictionary]];
        
        self.tableView.backgroundView = backgroundView;
        
        self.isBackgroundSetup = YES;
    }
}

@end
