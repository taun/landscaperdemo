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


NSString *const kMDBFractalScapesFirstLaunchUserDefaultsKey = @"kMDBFractalScapesFirstLaunchUserDefaultsKey";


@implementation MDBAppModel

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

@end
