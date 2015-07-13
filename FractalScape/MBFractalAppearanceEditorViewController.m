//
//  MBFractalAppearanceEditorViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/05/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalAppearanceEditorViewController.h"
#import "UIDevice_Hardware.h"
#import "MDBFractalFiltersControllerViewController.h"

@interface MBFractalAppearanceEditorViewController ()

-(void)setupChildViewController:(UIViewController<FractalControllerProtocol>*)fractalController;

@end

@implementation MBFractalAppearanceEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if ([UIScreen mainScreen].scale == 1.0)
    { // not retina device
        NSMutableArray* childControllers = [self.childViewControllers mutableCopy];
        UIViewController* filterController;
        
        for (UIViewController* controller in childControllers)
        {
            UINavigationController* navCon = (UINavigationController*)controller;
            UIViewController* viewController = [navCon.childViewControllers firstObject];
            if ([viewController isKindOfClass: [MDBFractalFiltersControllerViewController class]])
            {
                filterController = navCon;
                break;
            }
        }
        if (filterController)
        {
            [childControllers removeObject: filterController];
            [self setViewControllers: childControllers];
        }
    }
    
    self.delegate = self;
}
-(void) viewWillAppear:(BOOL)animated {

//    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//    if (orientation == UIDeviceOrientationUnknown) {
//        self.preferredContentSize = _portraitSize;
//    } else if (orientation == UIDeviceOrientationPortrait) {
//        self.preferredContentSize = _portraitSize;
//    } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
//        self.preferredContentSize = _portraitSize;
//    } else if (orientation == UIDeviceOrientationLandscapeLeft) {
//        self.preferredContentSize = _landscapeSize;
//    } else if (orientation == UIDeviceOrientationLandscapeRight) {
//        self.preferredContentSize = _landscapeSize;
//    } else if (orientation == UIDeviceOrientationFaceUp) {
//        self.preferredContentSize = _portraitSize;
//    } else if (orientation == UIDeviceOrientationFaceDown) {
//        self.preferredContentSize = _portraitSize;
//    }
//    
    
    [super viewWillAppear:animated];
}
-(void) viewDidAppear:(BOOL)animated {
    [self setupChildViewController:(UIViewController<FractalControllerProtocol> *)self.selectedViewController];

    // must be after child setup
    [super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void) setupChildViewController: (UIViewController*)controller {
    UINavigationController* navCon = (UINavigationController*)controller;
    UIViewController<FractalControllerProtocol>*fractalController = (UIViewController<FractalControllerProtocol>*)navCon.topViewController;
    fractalController.fractalUndoManager = self.fractalUndoManager;
    fractalController.fractalDocument = self.fractalDocument;
    fractalController.fractalControllerDelegate = self.fractalControllerDelegate;
}
//-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    if (size.width > size.height)
//    {
//        if (!CGSizeEqualToSize(self.preferredContentSize, _landscapeSize))
//        {
//            self.preferredContentSize = _landscapeSize;
//        }
//    } else
//    {
//        if (!CGSizeEqualToSize(self.preferredContentSize, _portraitSize))
//        {
//            self.preferredContentSize = _portraitSize;
//        }
//    }
//    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
//}
#pragma mark - TabBarDelegateProtocol
-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self setupChildViewController: (UIViewController<FractalControllerProtocol>*)viewController];
}
@end
