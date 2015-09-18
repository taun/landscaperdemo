//
//  MDBAppModel.m
//  FractalScapes
//
//  Created by Taun Chapman on 04/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBAppModel.h"
#import "MBFractalPrefConstants.h"
#import "MDBDocumentController.h"
#import "MDBFractalDocument.h"
#import "MBColorCategory.h"
#import "LSDrawingRuleType.h"
#import "MDBFractalInfo.h"
#import "MDLCloudKitManager.h"
#import "MDBCloudManager.h"
#import "MDBDocumentUtilities.h"
#import "MDBFractalDocumentLocalCoordinator.h"
#import "MDBFractalDocumentCloudCoordinator.h"
#import "MBAppDelegate.h"
#import "MDBPurchaseManager.h"
#import "MDBPurchaseViewController.h"


NSString *const kMDBFractalScapesFirstLaunchUserDefaultsKey = @"kMDBFractalScapesFirstLaunchUserDefaultsKey";
NSString *const kMDBFractalCloudContainer = @"iCloud.com.moedae.FractalScapes";

NSString* const  kPrefParalax = @"com.moedae.FractalScapes.paralax";
NSString* const  kPrefShowPerformanceData = @"com.moedae.FractalScapes.showPerformanceData";
NSString* const  kPrefFullScreenState = @"com.moedae.FractalScapes.fullScreenState";
NSString* const  kPrefShowHelpTips = @"com.moedae.FractalScapes.showEditHelp";
NSString* const  kPrefVersion = @"com.moedae.FractalScapes.AppVersion";
NSString* const  kPrefPromptedDiscoveryUsed = @"com.moedae.FractalScapes.CKDiscoveryPromptUsed";
NSString* const  kPrefWelcomeDone = @"com.moedae.FractalScapes.WelcomeDone";
NSString* const  kPrefEditorIntroDone = @"com.moedae.FractalScapes.EditorIntroDone";

@interface MDBAppModel ()

@property(nonatomic,readwrite,getter=isCloudIdentityChanged) BOOL       cloudIdentityChanged;

@property (nonatomic,assign,readwrite) BOOL        allowPremiumOverride;
@property (nonatomic,assign,readwrite) BOOL        useWatermarkOverride;

@property(nonatomic,readwrite,strong) LSDrawingRuleType               *sourceDrawingRules;
@property(nonatomic,readwrite,strong) NSArray                         *sourceColorCategories;

@end


@implementation MDBAppModel

@synthesize cloudKitManager = _cloudKitManager;
@synthesize cloudDocumentManager = _cloudDocumentManager;
@synthesize purchaseManager = _purchaseManager;
@synthesize resourceCache = _resourceCache;

-(void)___setAllowPremium:(BOOL)on
{
    self.allowPremiumOverride = on;
}

-(void)___setUseWatermark:(BOOL)on
{
    self.useWatermarkOverride = on;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self registerDefaults];
        _cloudDocumentManager = [MDBCloudManager new];
        _purchaseManager = [MDBPurchaseManager newManagerWithModel: self];
    }
    return self;
}

-(NSCache *)resourceCache
{
    if (!_resourceCache) _resourceCache = [NSCache new];
    return _resourceCache;
}

-(MDLCloudKitManager*)cloudKitManager
{
    if (!_cloudKitManager) {
        _cloudKitManager = [[MDLCloudKitManager alloc] initWithIdentifier: kMDBFractalCloudContainer andRecordType: CKFractalRecordType];
        
        NSSortDescriptor* byModDate = [NSSortDescriptor sortDescriptorWithKey: @"modificationDate" ascending: NO];
        NSSortDescriptor* byName = [NSSortDescriptor sortDescriptorWithKey: CKFractalRecordNameField ascending: YES];
        
        _cloudKitManager.defaultSortDescriptors = @[byModDate, byName];
    }
    return _cloudKitManager;
}

-(MDBPurchaseManager *)purchaseManager
{
    if (!_purchaseManager)
    {
        _purchaseManager = [MDBPurchaseManager new];
        _purchaseManager.appModel = self;
    }
    
    return _purchaseManager;
}

- (void)registerDefaults
{
    //    // since no default values have been set, create them here
    
    NSDictionary *appDefaults =  [NSDictionary dictionaryWithObjectsAndKeys:  @YES, kPrefParalax, @YES, kPrefFullScreenState, @YES, kPrefShowHelpTips, nil];
    //
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults: appDefaults];
    
    [userDefaults registerDefaults:@{kMDBFractalScapesFirstLaunchUserDefaultsKey: @YES }];
    
    [userDefaults setValue: self.versionBuildString forKey: kPrefVersion];
    
    [userDefaults synchronize];
}

-(NSString *)versionString
{
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    return appVersionString;
}

-(NSString *)buildString
{
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    return appBuildString;
}

-(NSString *)versionBuildString
{
    return [NSString stringWithFormat:@"%@ (%@)", self.versionString, self.buildString];
}

-(BOOL)allowPremium
{
    return (self.purchaseManager.isPremiumPaidFor || self.allowPremiumOverride);
}

-(BOOL)useWatermark
{
    return (!self.purchaseManager.isPremiumPaidFor || self.useWatermarkOverride);
}


-(void)demoFilesLoaded
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: NO forKey: kMDBFractalScapesFirstLaunchUserDefaultsKey];
    [defaults synchronize];
}

-(BOOL)loadDemoFiles
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: kMDBFractalScapesFirstLaunchUserDefaultsKey];
}

-(void)enterCloudIdentityChangedState
{
    self.cloudIdentityChanged = YES;
}

-(void)exitCloudIdentityChangedState
{
    self.cloudIdentityChanged = NO;
}

-(void)exitWelcomeState
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: YES forKey: kPrefWelcomeDone];
}
-(BOOL)welcomeDone
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: kPrefWelcomeDone];
}
-(void)exitEditorIntroState
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: YES forKey: kPrefEditorIntroDone];
}
-(BOOL)editorIntroDone
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: kPrefEditorIntroDone];
}

-(void)setShowParallax:(BOOL)show
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: show forKey: kPrefParalax];
    [defaults synchronize];
}

-(BOOL)showParallax
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: kPrefParalax];
}

-(void)setShowPerformanceData:(BOOL)show
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: show forKey: kPrefShowPerformanceData];
    [defaults synchronize];
}

-(BOOL)showPerformanceData
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: kPrefShowPerformanceData];
}

-(void)setFullScreenState:(BOOL)on
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: on forKey: kPrefFullScreenState];
    [defaults synchronize];
}

-(BOOL)fullScreenState
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: kPrefFullScreenState];
}

-(void)setShowHelpTips:(BOOL)show
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: show forKey: kPrefShowHelpTips];
    [defaults synchronize];
}

-(BOOL)showHelpTips
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL show = [defaults boolForKey: kPrefShowHelpTips];
    return show;
}

-(BOOL)userCanMakePayments
{
    BOOL can = self.purchaseManager.userCanMakePayments;
    return can;
}

/*!
 Someday, prompt the user if they want to discover new fractals using cloud kit.
 This will track whether the user has been prompted yet.
 
 @return
 */
-(BOOL)promptedForDiscovery
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL value = [defaults boolForKey: kPrefPromptedDiscoveryUsed];
    return value;
}

-(LSDrawingRuleType*)sourceDrawingRules
{
    if (!_sourceDrawingRules) {
        _sourceDrawingRules = [LSDrawingRuleType newLSDrawingRuleTypeFromDefaultPListDictionary];
    }
    return _sourceDrawingRules;
}

-(NSArray*)sourceColorCategories
{
    if (!_sourceColorCategories)
    {
        _sourceColorCategories = [MBColorCategory loadAllDefaultCategories];
    }
    return _sourceColorCategories;
}

-(BOOL)loadAdditionalColorsFromPlistFileNamed:(NSString *)fileName
{
    BOOL success = NO;
    
    NSArray* additionalColorsArray = [MBColorCategory loadAdditionalCategoriesFromPListFileNamed: fileName];
    if (additionalColorsArray.count > 0)
    {
        self.sourceColorCategories = [self.sourceColorCategories arrayByAddingObjectsFromArray: additionalColorsArray];
        success = YES;
    }
    return success;
}

#pragma mark - State Changes?

-(void)loadInitialDocuments
{
    [MDBDocumentUtilities copyInitialDocuments];
}

-(void)handleDidBecomeActive
{
//    [self setupUserStoragePreferences];
}

#pragma mark - User Storage Preferences

- (void)setupUserStoragePreferences
{
    [MDBDocumentUtilities waitUntilDoneCopying];
    
    MDBAPPStorageState storageState = self.cloudDocumentManager.storageState;
    
    // Check to see if the account has changed since the last time the method was called. If it has,
    // let the user know that their documents have changed. If they've already chosen local storage
    // (i.e. not iCloud), don't notify them since there's no impact.
    if (storageState.accountDidChange) {
        [self notifyUserOfAccountChange];
    }
    
    if (storageState.cloudAvailable) {
        if (storageState.storageOption == MDBAPPStorageNotSet) {
            // iCloud is available, but we need to ask the user what they prefer.
            //            [self promptUserForStorageOption];
            
            // Default to cloud storage if available rather than asking.
            [MDBDocumentUtilities migrateLocalDocumentsToCloud];
            
            self.cloudDocumentManager.storageOption = MDBAPPStorageCloud;
            
            [self configureDocumentController:YES];
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
            self.cloudDocumentManager.storageOption = MDBAPPStorageNotSet;
        }
        
        [self configureDocumentController:storageState.accountDidChange];
    }
    //    self.documentsViewController.appModel = _appModel;
    //    self.cloudBrowserViewController.appModel = _appModel;
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleUbiquityIdentityDidChangeNotification:) name: NSUbiquityIdentityDidChangeNotification object: nil];
}

#pragma mark - Alerts

- (void)notifyUserOfAccountChange
{
    NSString *title = NSLocalizedString(@"iCloud Account Changed", nil);
    NSString *message = NSLocalizedString(@"You have changed the account used to store documents. Change the account back to access those documents or keep this account and move on.", nil);
    NSString *okActionTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *signedOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [signedOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
    
    [self.delegate.documentsViewController presentViewController: signedOutController animated:YES completion:nil];
}

- (void)promptUserForStorageOption
{
    NSString *title = NSLocalizedString(@"Choose Storage Option", nil);
    NSString *message = NSLocalizedString(@"Do you want to store documents in iCloud or only on this device?", nil);
    NSString *localOnlyActionTitle = NSLocalizedString(@"Local Only", nil);
    NSString *cloudActionTitle = NSLocalizedString(@"iCloud", nil);
    
    UIAlertController *storageController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *localOption = [UIAlertAction actionWithTitle:localOnlyActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.cloudDocumentManager.storageOption = MDBAPPStorageLocal;
        
        [self configureDocumentController:YES];
    }];
    
    [storageController addAction:localOption];
    
    UIAlertAction *cloudOption = [UIAlertAction actionWithTitle:cloudActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MDBDocumentUtilities migrateLocalDocumentsToCloud];
        
        self.cloudDocumentManager.storageOption = MDBAPPStorageCloud;
        
        [self configureDocumentController:YES];
    }];
    
    [storageController addAction:cloudOption];
    
    [self.delegate.documentsViewController presentViewController:storageController animated:YES completion:nil];
}

#pragma mark - Convenience

- (void)configureDocumentController:(BOOL)accountChanged {
    id<MDBFractalDocumentCoordinator> documentCoordinator;
    
    if (self.cloudDocumentManager.storageOption != MDBAPPStorageCloud)
    {
        // This will be called if the storage option is either MDBAPPStorageLocal or MDBAPPStorageNotSet.
        documentCoordinator = [[MDBFractalDocumentLocalCoordinator alloc] initWithPathExtension: kMDBFractalDocumentFileExtension];
    }
    else
    {
        documentCoordinator = [[MDBFractalDocumentCloudCoordinator alloc] initWithPathExtension: kMDBFractalDocumentFileExtension];
    }
    
    if (!self.documentController)
    {
        self.documentController = [[MDBDocumentController alloc] initWithDocumentCoordinator: documentCoordinator sortComparator: ^NSComparisonResult(MDBFractalInfo *lhs, MDBFractalInfo *rhs) {
            NSComparisonResult initialResult = [rhs.changeDate compare: lhs.changeDate];
            NSComparisonResult finalResult;
            
            if (initialResult == NSOrderedSame)
            {
                finalResult = -1 * [rhs.identifier compare: lhs.identifier];
            }
            else
            {
                finalResult = initialResult;
            }
            
            return finalResult;
        }];
        
        //        self.documentsViewController.documentController = self.appModel.documentController;
        //        self.cloudBrowserViewController.documentController = self.appModel.documentController;
    }
    else if (accountChanged)
    {
        self.documentController.documentCoordinator = documentCoordinator;
        //        self.documentsViewController.navigationItem.title = [self.appModel.documentController.documentCoordinator isMemberOfClass: [MDBFractalDocumentLocalCoordinator class]] ? @"Local Library" : @"Cloud Library";
    }
}

#pragma mark - In-App Purchasing

/*!
 Need to observer appModel in other controllers for change in purchase state.
 If the purchase state changes, call this method to present a common alert.
 
 @param currentController
 */
-(void)presentSuccessfulPurchaseOnContoller: (UIViewController*)currentController
{
    NSLog(@"Not yet implemented");
}

-(void)confirmedDesireToPurchase
{
    NSLog(@"Purchase Not yet implemented");
}


#pragma mark - Notifications

-(void)handleMoveToBackground
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSUbiquityIdentityDidChangeNotification object: nil];
}

- (void)handleUbiquityIdentityDidChangeNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSUbiquityIdentityDidChangeNotification object: nil];
    [self.delegate.primaryViewController popToRootViewControllerAnimated:YES];
    
    [self setupUserStoragePreferences];
}

@end
