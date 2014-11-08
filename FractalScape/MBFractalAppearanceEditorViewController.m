//
//  MBFractalAppearanceEditorViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/05/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalAppearanceEditorViewController.h"

@interface MBFractalAppearanceEditorViewController ()

-(void)setupChildViewController:(UIViewController<FractalControllerProtocol>*)fractalController;

@end

@implementation MBFractalAppearanceEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.delegate = self;
}
-(void) viewWillAppear:(BOOL)animated {

    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIDeviceOrientationUnknown) {
        self.preferredContentSize = _portraitSize;
    } else if (orientation == UIDeviceOrientationPortrait) {
        self.preferredContentSize = _portraitSize;
    } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        self.preferredContentSize = _portraitSize;
    } else if (orientation == UIDeviceOrientationLandscapeLeft) {
        self.preferredContentSize = _landscapeSize;
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        self.preferredContentSize = _landscapeSize;
    } else if (orientation == UIDeviceOrientationFaceUp) {
        self.preferredContentSize = _portraitSize;
    } else if (orientation == UIDeviceOrientationFaceDown) {
        self.preferredContentSize = _portraitSize;
    }
    
    
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
-(void) setupChildViewController:(UIViewController<FractalControllerProtocol>*)fractalController {
    fractalController.fractalUndoManager = self.fractalUndoManager;
    fractalController.fractal = self.fractal;
}
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (size.width > size.height) {
        self.preferredContentSize = _landscapeSize;
    } else {
        self.preferredContentSize = _portraitSize;
    }
}
#pragma mark - TabBarDelegateProtocol
-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self setupChildViewController: (UIViewController<FractalControllerProtocol>*)viewController];
}
@end
