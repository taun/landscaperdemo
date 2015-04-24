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
#import "MBFractalLibraryViewController.h"
#import "MDBCloudManager.h"
#import "MDBDocumentController.h"
#import "MDBDocumentUtilities.h"
#import "MDBFractalInfo.h"
#import "MDBFractalDocumentCoordinator.h"
#import "MDBFractalDocumentLocalCoordinator.h"
#import "MDBFractalDocumentCloudCoordinator.h"
#import "MDBFractalCloudBrowser.h"


#import "UIDevice_Hardware.h"

// View controller segue identifiers.
NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerToEditDocumentListControllerSegueIdentifier = @"showEditFractalDocumentsList";
NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier = @"showNewFractalDocument";
NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier = @"showFractalDocument";
NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier = @"showFractalDocumentFromUserActivity";


@interface MBAppDelegate ()

@property (nonatomic, strong) MDBAppModel                       *appModel;
@property (nonatomic, readonly) UINavigationController          *primaryViewController;
@property (nonatomic, readonly) MBFractalLibraryViewController  *documentsViewController;
@property (nonatomic, readonly) MDBFractalCloudBrowser          *cloudBrowserViewController;
@property (nonatomic, strong) UIImage                           *backgroundImage;
@end

@implementation MBAppDelegate

@synthesize window = _window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    srand48(time(0)); // for use of randomize function in other parts of app
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleUbiquityIdentityDidChangeNotification:) name:NSUbiquityIdentityDidChangeNotification object: nil];

    _appModel = [MDBAppModel new];
    [[MDBCloudManager sharedManager] setAppModel: _appModel];
    [[MDBCloudManager sharedManager] runHandlerOnFirstLaunch:^{
        [MDBDocumentUtilities copyInitialDocuments];
    }];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[NSUserDefaults standardUserDefaults] synchronize];
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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    [self setupUserStoragePreferences];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    // documentCoordinatorer only supports a single user activity type; if you support more than one the type is available from the `userActivity` parameter.
    if (restorationHandler && self.documentsViewController)
    {
        restorationHandler(@[self.documentsViewController]);
        return true;
    }
    
    return false;
}

#pragma mark - Getters & Setters
- (UINavigationController *)primaryViewController {
    return self.documentsViewController.navigationController;
}

- (MBFractalLibraryViewController *)documentsViewController {
    UITabBarController* tabBar = [[self.window.rootViewController childViewControllers]firstObject];
    MBFractalLibraryViewController *documentsViewController = [tabBar.viewControllers firstObject];
    return documentsViewController;
}

- (MDBFractalCloudBrowser *)cloudBrowserViewController {
    UITabBarController* tabBar = [[self.window.rootViewController childViewControllers]firstObject];
    MDBFractalCloudBrowser *cloudBrowser = [tabBar.viewControllers lastObject];
    return cloudBrowser;
}


#pragma mark - Notifications

- (void)handleUbiquityIdentityDidChangeNotification:(NSNotification *)notification
{
    [self.primaryViewController popToRootViewControllerAnimated:YES];
    
    [self setupUserStoragePreferences];
}

#pragma mark - User Storage Preferences

- (void)setupUserStoragePreferences {
    MDBAPPStorageState storageState = [MDBCloudManager sharedManager].storageState;
    
    // Check to see if the account has changed since the last time the method was called. If it has,
    // let the user know that their documents have changed. If they've already chosen local storage
    // (i.e. not iCloud), don't notify them since there's no impact.
    if (storageState.accountDidChange) {
        [self notifyUserOfAccountChange];
    }
    
    if (storageState.cloudAvailable) {
        if (storageState.storageOption == MDBAPPStorageNotSet) {
            // iCloud is available, but we need to ask the user what they prefer.
            [self promptUserForStorageOption];
        }
        else {
            // The user has already selected a specific storage option. Set up the list controller to
            // use that storage option.
            [self configureDocumentController:storageState.accountDidChange];
        }
    }
    else {
        // iCloud is not available, so we'll reset the storage option and configure the list controller.
        // The next time that the user signs in with an iCloud account, he or she can change provide
        // their desired storage option.
        if (storageState.storageOption != MDBAPPStorageNotSet) {
            [MDBCloudManager sharedManager].storageOption = MDBAPPStorageNotSet;
        }
        
        [self configureDocumentController:storageState.accountDidChange];
    }
    self.documentsViewController.appModel = _appModel;
}

#pragma mark - Alerts

- (void)notifyUserOfAccountChange
{
    NSString *title = NSLocalizedString(@"iCloud Sign Out", nil);
    NSString *message = NSLocalizedString(@"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents.", nil);
    NSString *okActionTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *signedOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [signedOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
    
    [self.documentsViewController presentViewController: signedOutController animated:YES completion:nil];
}

- (void)promptUserForStorageOption
{
    NSString *title = NSLocalizedString(@"Choose Storage Option", nil);
    NSString *message = NSLocalizedString(@"Do you want to store documents in iCloud or only on this device?", nil);
    NSString *localOnlyActionTitle = NSLocalizedString(@"Local Only", nil);
    NSString *cloudActionTitle = NSLocalizedString(@"iCloud", nil);
    
    UIAlertController *storageController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *localOption = [UIAlertAction actionWithTitle:localOnlyActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MDBCloudManager sharedManager].storageOption = MDBAPPStorageLocal;
        
        [self configureDocumentController:YES];
    }];
    
    [storageController addAction:localOption];
    
    UIAlertAction *cloudOption = [UIAlertAction actionWithTitle:cloudActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MDBDocumentUtilities migrateLocalDocumentsToCloud];
        
        [MDBCloudManager sharedManager].storageOption = MDBAPPStorageCloud;
        
        [self configureDocumentController:YES];
    }];
    
    [storageController addAction:cloudOption];
    
    [self.documentsViewController presentViewController:storageController animated:YES completion:nil];
}

#pragma mark - Convenience

- (void)configureDocumentController:(BOOL)accountChanged {
    id<MDBFractalDocumentCoordinator> documentCoordinator;
    
    if ([MDBCloudManager sharedManager].storageOption != MDBAPPStorageCloud)
    {
        // This will be called if the storage option is either MDBAPPStorageLocal or MDBAPPStorageNotSet.
        documentCoordinator = [[MDBFractalDocumentLocalCoordinator alloc] initWithPathExtension: kMDBFractalDocumentFileExtension];
    }
    else
    {
        documentCoordinator = [[MDBFractalDocumentCloudCoordinator alloc] initWithPathExtension: kMDBFractalDocumentFileExtension];
    }
    
    if (!self.appModel.documentController)
    {
        self.appModel.documentController = [[MDBDocumentController alloc] initWithDocumentCoordinator: documentCoordinator sortComparator:^NSComparisonResult(MDBFractalInfo *lhs, MDBFractalInfo *rhs) {
            return [rhs.changeDate compare: lhs.changeDate];
        }];
        
//        self.documentsViewController.documentController = self.appModel.documentController;
//        self.cloudBrowserViewController.documentController = self.appModel.documentController;
    }
    else if (accountChanged)
    {
        self.appModel.documentController.documentCoordinator = documentCoordinator;
//        self.documentsViewController.navigationItem.title = [self.appModel.documentController.documentCoordinator isMemberOfClass: [MDBFractalDocumentLocalCoordinator class]] ? @"Local Library" : @"Cloud Library";
    }
}

@end
