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
#import "MDLCloudKitManager.h"


NSString *const kMDBFractalScapesFirstLaunchUserDefaultsKey = @"kMDBFractalScapesFirstLaunchUserDefaultsKey";
NSString *const kMDBFractalCloudContainer = @"iCloud.com.moedae.FractalScapes";

NSString* const  kPrefLastEditedFractalURI = @"com.moedae.FractalScapes.lastEditedFractalURI";
NSString* const  kPrefParalax = @"com.moedae.FractalScapes.paralax";
NSString* const  kPrefShowPerformanceData = @"com.moedae.FractalScapes.showPerformanceData";
NSString* const  kPrefFullScreenState = @"com.moedae.FractalScapes.fullScreenState";
NSString* const  kPrefShowHelpTips = @"com.moedae.FractalScapes.showEditHelp";

@implementation MDBAppModel

@synthesize cloudManager = _cloudManager;

-(BOOL)allowPremium
{
    return NO;
}

-(BOOL)useWatermark
{
    return YES;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self registerDefaults];
    }
    return self;
}

-(MDLCloudKitManager*)cloudManager
{
    if (!_cloudManager) {
        _cloudManager = [[MDLCloudKitManager alloc] initWithIdentifier: kMDBFractalCloudContainer andRecordType: CKFractalRecordType];
        
        NSSortDescriptor* byModDate = [NSSortDescriptor sortDescriptorWithKey: @"modificationDate" ascending: NO];
        NSSortDescriptor* byName = [NSSortDescriptor sortDescriptorWithKey: CKFractalRecordNameField ascending: YES];
        
        _cloudManager.defaultSortDescriptors = @[byModDate, byName];
    }
    return _cloudManager;
}

- (void)registerDefaults
{
    //    // since no default values have been set, create them here
    NSDictionary *appDefaults =  [NSDictionary dictionaryWithObjectsAndKeys:  @YES, kPrefParalax, @NO, kPrefFullScreenState, @YES, kPrefShowHelpTips, nil];
    //
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults: appDefaults];
    
    [userDefaults registerDefaults:@{kMDBFractalScapesFirstLaunchUserDefaultsKey: @YES }];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"];
    NSString* fullVersion = [NSString stringWithFormat: @"%@(%@)", version, build];
    [userDefaults setValue: version forKey: fullVersion];
    
    [userDefaults synchronize];
    
    _firstLaunch = [userDefaults boolForKey: kMDBFractalScapesFirstLaunchUserDefaultsKey];
    
    if (_firstLaunch)
    {
        [userDefaults setBool: NO forKey: kMDBFractalScapesFirstLaunchUserDefaultsKey];
    }
}

-(NSString *)versionBuildString
{
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    return [NSString stringWithFormat:@"%@ (%@)", appVersionString, appBuildString];
}

-(void)setLastEditedURL:(NSURL *)lastEdited
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setURL: lastEdited forKey: kPrefLastEditedFractalURI];
    [defaults synchronize];
}

-(NSURL *)lastEditedURL
{
    NSURL* selectedFractalURL;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    selectedFractalURL = [defaults URLForKey: kPrefLastEditedFractalURI];
    return selectedFractalURL;
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

@end
