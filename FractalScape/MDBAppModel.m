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
#import "MDLCloudKitManager.h"
#import "MDBFractalDocument.h"

NSString *const kMDBFractalScapesFirstLaunchUserDefaultsKey = @"kMDBFractalScapesFirstLaunchUserDefaultsKey";
NSString *const kMDBFractalCloudContainer = @"iCloud.com.moedae.FractalScapes";

@implementation MDBAppModel

@synthesize cloudManager = _cloudManager;

-(BOOL)allowPremium
{
    return YES;
}

-(BOOL)useWatermark
{
    return YES;
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
        _cloudManager = [[MDLCloudKitManager alloc] initWithIdentifier: kMDBFractalCloudContainer];
        
        NSSortDescriptor* byModDate = [NSSortDescriptor sortDescriptorWithKey: @"modificationDate" ascending: NO];
        NSSortDescriptor* byName = [NSSortDescriptor sortDescriptorWithKey: CKFractalRecordNameField ascending: YES];
        
        _cloudManager.defaultSortDescriptors = @[byModDate, byName];
    }
    return _cloudManager;
}

@end
