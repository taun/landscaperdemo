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
#import "LSFractal.h"
#import "MDBFractalInfo.h"
#import "MDLCloudKitManager.h"
#import "MDBCloudManager.h"
#import "MDBDocumentUtilities.h"
#import "MDBFractalDocumentLocalCoordinator.h"
#import "MDBFractalDocumentCloudCoordinator.h"
#import "MBAppDelegate.h"
#import "MDBPurchaseManager.h"
#import "MDBPurchaseViewController.h"

#import <Crashlytics/Crashlytics.h>


NSString *const kMDBFractalScapesFirstLaunchUserDefaultsKey = @"kMDBFractalScapesFirstLaunchUserDefaultsKey";
NSString *const kMDBFractalCloudContainer = @"iCloud.com.moedae.FractalScapes";

NSString* const  kPrefParalax = @"com.moedae.FractalScapes.paralax";
NSString* const  kPrefOrigin = @"com.moedae.FractalScapes.hideOrigin";
NSString* const  kPrefWatermark = @"com.moedae.FractalScapes.watermark";
NSString* const  kPrefShowPerformanceData = @"com.moedae.FractalScapes.showPerformanceData";
NSString* const  kPrefFullScreenState = @"com.moedae.FractalScapes.fullScreenState";
NSString* const  kPrefShowHelpTips = @"com.moedae.FractalScapes.showEditHelp";
NSString* const  kPrefVersion = @"com.moedae.FractalScapes.AppVersion";
NSString* const  kPrefPromptedDiscoveryUsed = @"com.moedae.FractalScapes.CKDiscoveryPromptUsed";
NSString* const  kPrefWelcomeDone = @"com.moedae.FractalScapes.WelcomeDone";
NSString* const  kPrefEditorIntroDone = @"com.moedae.FractalScapes.EditorIntroDone";
NSString* const  kPrefAnalytics = @"com.moedae.FractalScapes.collectAnalytics";


@interface MDBAppModel ()

@property(nonatomic,readwrite,getter=isCloudIdentityChanged) BOOL       cloudIdentityChanged;

@property (nonatomic,assign,readwrite) BOOL        allowPremiumOverride;
@property (nonatomic,assign,readwrite) BOOL        useWatermarkOverride;

@property(nonatomic,readwrite,strong) LSDrawingRuleType               *sourceDrawingRules;
@property(nonatomic,readwrite,strong) NSArray                         *sourceColorCategories;

// iOS 10 Haptic additions
@property(nonatomic,strong) UIImpactFeedbackGenerator*                  selectionFeedbackGenerator;

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

-(void)___setUseWatermark:(BOOL)show
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: show forKey: kPrefWatermark];
    [defaults synchronize];

    self.useWatermarkOverride = show;
}

-(BOOL)useWatermarkOverride
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: kPrefWatermark];
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

-(BOOL)isCloudAvailable
{
    return self.cloudDocumentManager.storageState.cloudAvailable;
}

-(void)sendUserToSystemiCloudSettings: (id)sender
{
    // Cloud —> prefs:root=CASTLE
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: UIApplicationOpenSettingsURLString]];
}


-(void)pushToPublicCloudFractalInfos:(NSSet *)setOfFractalInfos onController:(UIViewController *)viewController
{
    NSMutableArray* records = [NSMutableArray arrayWithCapacity: setOfFractalInfos.count];
    
    for (MDBFractalInfo* fractalInfo in setOfFractalInfos)
    {
        if (fractalInfo.document)
        {
            id<MDBFractaDocumentProtocol> fractalDocument = fractalInfo.document;
            LSFractal* fractal = fractalDocument.fractal;
            
            if (fractal.name != nil)  [Answers logShareWithMethod: @"FractalCloud" contentName: fractal.name contentType:@"Fractal" contentId: fractal.name customAttributes: nil];
            
            CKRecord* record;
            record = [[CKRecord alloc] initWithRecordType: CKFractalRecordType];
            record[CKFractalRecordNameField] = fractal.name;
            record[CKFractalRecordNameInsensitiveField] = [fractal.name lowercaseString];
            record[CKFractalRecordDescriptorField] = fractal.descriptor;
            
            
            NSURL* fractalURL = [fractalDocument.fileURL URLByAppendingPathComponent: kMDBFractalFileName];
            record[CKFractalRecordFractalDefinitionAssetField] = [[CKAsset alloc] initWithFileURL: fractalURL];
            
            NSURL* thumbnailURL = [fractalDocument.fileURL URLByAppendingPathComponent: kMDBThumbnailFileName];
            record[CKFractalRecordFractalThumbnailAssetField] = [[CKAsset alloc] initWithFileURL: thumbnailURL];
            
            [records addObject: record];
        }
    }
    
    [self.cloudKitManager savePublicRecords: records qualityOfService: NSQualityOfServiceUserInitiated withCompletionHandler:^(NSError *error) {
        if (error) {
            [Answers logCustomEventWithName: @"LibraryShare" customAttributes: @{@"Action": @"FractalCloud", @"Error":@(error.code)}];
        }
        [self showAlertTitled: @"Thanks for sharing!" potentialError: error onController: viewController];
    }];
}

-(void)showAlertActionsToAddiCloud: (id)sender onController:(UIViewController *)viewController
{
    NSString* title = NSLocalizedString(@"Login to iCloud", nil);
    NSString* message;
//    if (self.allowPremium)
//    {
//    }
//    else
//    {
//        message = NSLocalizedString(@"You must have your device logged into iCloud AND Upgrade to Pro", nil);
//    }
    message = NSLocalizedString(@"Sharing uses your iCloud account", nil);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle: NSLocalizedString(@"Go to iCloud Settings",nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [Answers logCustomEventWithName: @"LibraryShare" customAttributes: @{@"Action": @"iCloudSettings"}];
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [self sendUserToSystemiCloudSettings: sender];
                                   }];
    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Maybe Later",nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [Answers logCustomEventWithName: @"LibraryShare" customAttributes: @{@"Action": @"iCloudLater"}];
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    [alert addAction: defaultAction];
    
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

-(void)showAlertTitled:(NSString *)title potentialError:(NSError *)error onController:(UIViewController *)viewController
{
    NSString* message;
    
    if (!error)
    {
        title = title;
    }
    else
    {
        title = error.localizedDescription;
        message = error.localizedRecoverySuggestion;
    }
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"OK",nil)
                                                            style: UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    
    [alert addAction: defaultAction];
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [viewController presentViewController:alert animated:YES completion:nil];
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
    
    NSDictionary *appDefaults =  @{kPrefParalax:@YES,
                                   kPrefFullScreenState:@YES,
                                   kPrefShowHelpTips:@YES,
                                   kPrefWatermark:@YES,
                                   kPrefOrigin:@NO };
    //
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults: appDefaults];
    
    [userDefaults registerDefaults:@{kMDBFractalScapesFirstLaunchUserDefaultsKey: @YES }];
    
    [userDefaults setValue: self.versionBuildString forKey: kPrefVersion];
    
    [userDefaults synchronize];
    
    self.allowPremiumOverride = YES;
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
    
    return [defaults boolForKey: kMDBFractalScapesFirstLaunchUserDefaultsKey];;
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

-(void)setHideOrigin:(BOOL)show
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: show forKey: kPrefOrigin];
    [defaults synchronize];
}

-(BOOL)hideOrigin
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey: kPrefOrigin];
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
    [self setupUserStoragePreferences];
}

#pragma mark - User Storage Preferences

- (void)setupUserStoragePreferences
{
    if (self.loadDemoFiles)
    {
        [MDBDocumentUtilities waitUntilDoneCopying];
        [self demoFilesLoaded];
    }
    
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
            
            [self configureDocumentController: YES];
        }
        else {
            // The user has already selected a specific storage option. Set up the list controller to
            // use that storage option.
            [self configureDocumentController: storageState.accountDidChange];
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

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSUbiquityIdentityDidChangeNotification object: nil];
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
    id<MDBFractalDocumentCoordinator> documentCoordinator = self.documentController.documentCoordinator;
    
    BOOL localOption = self.cloudDocumentManager.storageOption != MDBAPPStorageCloud;
    BOOL optionChanged = documentCoordinator && (([documentCoordinator isKindOfClass: [MDBFractalDocumentCloudCoordinator class]] && localOption) || ([documentCoordinator isKindOfClass: [MDBFractalDocumentLocalCoordinator class]] && !localOption));
    
    if (optionChanged || accountChanged)
    {
        [self.delegate.primaryViewController popToRootViewControllerAnimated:YES];
    }
    
    if (!documentCoordinator || optionChanged)
    {
        if (localOption)
        {
            // This will be called if the storage option is either MDBAPPStorageLocal or MDBAPPStorageNotSet.
            documentCoordinator = [[MDBFractalDocumentLocalCoordinator alloc] initWithPathExtension: kMDBFractalDocumentFileExtension];
        }
        else
        {
            documentCoordinator = [[MDBFractalDocumentCloudCoordinator alloc] initWithPathExtension: kMDBFractalDocumentFileExtension];
        }
        
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
    else if (accountChanged || optionChanged)
    {
        self.documentController.documentCoordinator = documentCoordinator;
        //        self.documentsViewController.navigationItem.title = [self.appModel.documentController.documentCoordinator isMemberOfClass: [MDBFractalDocumentLocalCoordinator class]] ? @"Local Library" : @"Cloud Library";
    }
}

-(void)copyToAppStorageFromURL:(NSURL *)sourceURL andRemoveOriginal: (BOOL) remove
{
    BOOL localOption = self.cloudDocumentManager.storageOption != MDBAPPStorageCloud;

    if (localOption)
    {
        [MDBDocumentUtilities copyToAppLocalFromInboxUrl: sourceURL andRemoveOriginal: remove];
    }
    else
    {
        [MDBDocumentUtilities copyToAppCloudFromInboxUrl: sourceURL andRemoveOriginal: remove];
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
    //    [self.documentController closeAllDocuments]; // Was too agressive and causing blank documents due to documents not being re-opened on selection.
//    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSUbiquityIdentityDidChangeNotification object: nil];
}

- (void)handleUbiquityIdentityDidChangeNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSUbiquityIdentityDidChangeNotification object: nil];
    [self.delegate.primaryViewController popToRootViewControllerAnimated:YES];
    
    [self setupUserStoragePreferences];
}

@end
