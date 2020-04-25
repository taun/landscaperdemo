//
//  MBFractalAppearanceEditorViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/05/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalAppearanceEditorViewController.h"
#import "MDBFractalFiltersControllerViewController.h"
#import "MBFractalRulesEditorViewController.h"


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
        [self removeEditorOfClass: [MDBFractalFiltersControllerViewController class]];
    }
    
    self.delegate = self;
}

-(void)removeEditorOfClass: (Class)aClass
{
    NSMutableArray* childControllers = [self.childViewControllers mutableCopy];
    UIViewController* controllerToRemove;
    
    for (UIViewController* controller in childControllers)
    {
        UINavigationController* navCon = (UINavigationController*)controller;
        UIViewController* viewController = [navCon.childViewControllers firstObject];
        if ([viewController isKindOfClass: aClass])
        {
            controllerToRemove = navCon;
            break;
        }
    }
    if (controllerToRemove)
    {
        [childControllers removeObject: controllerToRemove];
        [self setViewControllers: childControllers];
    }
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
    fractalController.appModel = self.appModel;
    fractalController.fractalDocument = self.fractalDocument;
    fractalController.fractalControllerDelegate = self.fractalControllerDelegate;
}

#pragma mark - TabBarDelegateProtocol
-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self setupChildViewController: (UIViewController<FractalControllerProtocol>*)viewController];

    UINavigationController* navCon = (UINavigationController*)viewController;
    NSString* selectedViewName = NSStringFromClass([[navCon.viewControllers firstObject] class]);
}
@end
