//
//  MDBMainLibraryTabBarController.m
//  FractalScapes
//
//  Created by Taun Chapman on 05/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBMainLibraryTabBarController.h"

#import "ABX.h"

@interface MDBMainLibraryTabBarController ()

@end

@implementation MDBMainLibraryTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.delegate = self;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void) viewDidAppear:(BOOL)animated {
    
    // must be after child setup
    [super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    UIViewController* subNavViewController = self.selectedViewController.childViewControllers[0];
    if ([subNavViewController isKindOfClass: [ABXBaseListViewController class]]) {
        [self setupFAQViewController:(ABXFAQsViewController*)subNavViewController];
    }
}

-(void) setupFAQViewController: (ABXFAQsViewController*)controller
{
}


@end
