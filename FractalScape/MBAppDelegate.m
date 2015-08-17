//
//  MBAppDelegate.m
//  FractalScape
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBAppDelegate.h"

#import "MDBAppModel.h"
#import "MBLSFractalEditViewController.h"
#import "MDBCloudManager.h"
#import "MDBDocumentController.h"
#import "MDBDocumentUtilities.h"
#import "MDBFractalInfo.h"
#import "MDBFractalDocumentCoordinator.h"
#import "MDBFractalDocumentLocalCoordinator.h"
#import "MDBFractalDocumentCloudCoordinator.h"
#import "FractalScapeIconSet.h"
#import "MDBMainLibraryTabBarController.h"
#import "MDBFractalCloudBrowser.h"
#import "MBFractalLibraryViewController.h"

//#import "ABX.h"

#import "UIDevice_Hardware.h"

// View controller segue identifiers.
NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerToEditDocumentListControllerSegueIdentifier = @"showEditFractalDocumentsList";
NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier = @"showNewFractalDocument";
NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier = @"showFractalDocument";
NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier = @"showFractalDocumentFromUserActivity";


@interface MBAppDelegate ()

@property (nonatomic, readonly) MDBMainLibraryTabBarController  *mainTabController;
@property (nonatomic, strong) UIImage                           *backgroundImage;
@end

@implementation MBAppDelegate

@synthesize window = _window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
//    [[UITabBar appearance] setTintColor:[FractalScapeIconSet betaColor]];

    srand48(time(0)); // for use of randomize function in other parts of app
    
    // No longer necessary, app is now killed if iCloud status changes

    _appModel = [MDBAppModel new];
    _appModel.delegate = self;
    
    self.mainTabController.appModel = _appModel;
    
//    [[ABXApiClient instance] setApiKey:@"a02e2366313edf6d321e3eda0e3fcf613fd4ab72"];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.appModel handleMoveToBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
#pragma message "TODO uidocument fix"
//    editController.showPerformanceData = showPerformanceDataSetting;
//    NSLog(@"");
}
/*!
 Annotation: Blog
    Called after the root view has fully loaded and appeared.
    Called when app brought to foreground but viewDidAppear is not called.
        Means app settings can be changed and viewDidAppear doesn't get called but this method is called.
    Means any view which uses a defaults setting needs to listen for UIApplicationDidBecomeActiveNotification or be notified directly.
 
    Controllers need to know: 
        was a setting changed? - if so reload/re-appear, can monitor appModel property changes and have appModel reload all settings on active.
        was the iCloud identity changed? - so pop to library and reload
 
 @param application the application singleton
 */
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    [self.appModel handleDidBecomeActive];
}

/*!
 Doesn't yet do anythig since there is no Mac app to use continuity.
 
 */
//- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
//    // documentCoordinatorer only supports a single user activity type; if you support more than one the type is available from the `userActivity` parameter.
//    id strongController = self.documentsViewController;
//    
//    if (restorationHandler && strongController)
//    {
//        restorationHandler(@[strongController]);
//        return true;
//    }
//    
//    return false;
//}

#pragma mark - Getters & Setters
-(MDBMainLibraryTabBarController*)mainTabController
{
    MDBMainLibraryTabBarController* tabBar = (MDBMainLibraryTabBarController*)self.window.rootViewController;
    return tabBar;
}

- (UINavigationController *)primaryViewController
{
    return [self.documentsViewController navigationController];
}

- (MBFractalLibraryViewController *)documentsViewController
{
    MBFractalLibraryViewController *documentsViewController = [self.mainTabController.viewControllers firstObject];
    return documentsViewController;
}

- (MDBFractalCloudBrowser *)cloudBrowserViewController
{
    MDBFractalCloudBrowser *cloudBrowser = [self.mainTabController.viewControllers lastObject];
    return cloudBrowser;
}


@end
