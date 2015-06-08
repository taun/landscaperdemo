//
//  MDBMainLibraryTabBarController.m
//  FractalScapes
//
//  Created by Taun Chapman on 05/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBMainLibraryTabBarController.h"
#import "MBFractalLibraryViewController.h"
#import "MDBFractalCloudBrowser.h"

#import "ABX.h"
#import "MDBAppModel.h"

@interface MDBMainLibraryTabBarController ()

@end

@implementation MDBMainLibraryTabBarController

@synthesize cloudController = _cloudController;
@synthesize libraryController = _libraryController;


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
    
    [self sendAppModelToTabSubControllers];
    // must be after child setup
    [super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
//{
//    UIViewController* subNavViewController = self.selectedViewController.childViewControllers[0];
//    if ([subNavViewController isKindOfClass: [ABXBaseListViewController class]]) {
//        [self setupFAQViewController:(ABXFAQsViewController*)subNavViewController];
//    } else if ([subNavViewController isKindOfClass: [MBFractalLibraryViewController class]]){
//        MBFractalLibraryViewController* libraryController = (MBFractalLibraryViewController*)subNavViewController;
//        libraryController.appModel = self.appModel;
//    }else if ([subNavViewController isKindOfClass: [MDBFractalCloudBrowser class]]){
//        MDBFractalCloudBrowser* cloudController = (MDBFractalCloudBrowser*)subNavViewController;
//        cloudController.appModel = self.appModel;
//    }
//
//}

-(void)sendAppModelToTabSubControllers
{
    for (id subController in self.childViewControllers) {
        UINavigationController* baseNavCon = (UINavigationController*)subController;
        
        UIViewController* realController = baseNavCon.childViewControllers[0];
        
        if ([realController isKindOfClass: [MBFractalLibraryViewController class]])
        {
            _libraryController = (MBFractalLibraryViewController*)realController;
            _libraryController.appModel = self.appModel;
        }
        else if ([realController isKindOfClass: [MDBFractalCloudBrowser class]])
        {
            _cloudController = (MDBFractalCloudBrowser*)realController;
            _cloudController.appModel = self.appModel;
        }
        else if ([realController respondsToSelector: NSSelectorFromString(@"setAppModel:")]) {
            [realController performSelector: NSSelectorFromString(@"setAppModel:") withObject: self.appModel];
        }
    }
}

-(void) setupFAQViewController: (ABXFAQsViewController*)controller
{
}


@end
