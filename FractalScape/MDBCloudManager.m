//
//  MDBCloudManager.m
//  FractalScapes
//
//  Created by Taun Chapman on 02/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBCloudManager.h"


NSString *const kMDBCloudManagerUserActivityFractalIdentifierUserInfoKey = @"fractalIdentifier";

NSString *const kMDBFractalDocumentFileUTI = @"com.moedae.fractal";
NSString *const kMDBFractalDocumentFileExtension = @"fractal";

NSString *const kMDBICloudManagerFirstLaunchUserDefaultsKey = @"kMDBICloudManagerFirstLaunchUserDefaultsKey";
NSString *const kMDBICloudManagerStorageOptionUserDefaultsKey = @"kMDBICloudManagerStorageOptionUserDefaultsKey";
NSString *const kMDBICloudManagerStoredUbiquityIdentityTokenKey = @"com.moedae.FractalScapes.UbiquityIdentityToken";

NSString* const kMDBICloudStateUpdateNotification = @"kMDBICloudStateUpdateNotification";
NSString* const kMDBUbiquitousContainerFetchingWillBeginNotification = @"kMDBUbiquitousContainerFetchingWillBeginNotification";
NSString* const kMDBUbiquitousContainerFetchingDidEndNotification = @"kMDBUbiquitousContainerFetchingDidEndNotification";


@interface MDBCloudManager ()

@end

@implementation MDBCloudManager

+(MDBCloudManager*)sharedManager
{
    static MDBCloudManager* sharedManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //
        sharedManager = [MDBCloudManager new];
    });
    
    return sharedManager;
}

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults registerDefaults:@{
                                 kMDBICloudManagerFirstLaunchUserDefaultsKey: @YES,
#if TARGET_PLATFORM_IPHONE
                                 kMDBICloudManagerStorageOptionUserDefaultsKey: @(MDBAPPStorageNotSet)
#endif
                                 }];
    
    if ([defaults boolForKey:kMDBICloudManagerFirstLaunchUserDefaultsKey]) {
        [defaults setBool:NO forKey: kMDBICloudManagerFirstLaunchUserDefaultsKey];
        
        firstLaunchHandler();
    }
}

- (MDBAPPStorage)storageOption {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey: kMDBICloudManagerStorageOptionUserDefaultsKey];
    
    return (MDBAPPStorage)value;
}

- (void)setStorageOption:(MDBAPPStorage)storageOption {
    [[NSUserDefaults standardUserDefaults] setInteger:storageOption forKey: kMDBICloudManagerStorageOptionUserDefaultsKey];
}

- (BOOL)isCloudAvailable {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

- (MDBAPPStorageState)storageState {
    return (MDBAPPStorageState) {
        .storageOption = self.storageOption,
        .accountDidChange = [self hasUbiquityIdentityChanged],
        .cloudAvailable = self.isCloudAvailable
    };
}

#pragma mark - Ubiquity Identity Token Handling (Account Change Info)

- (BOOL)hasUbiquityIdentityChanged {
    BOOL hasChanged = NO;
    
    id<NSObject, NSCopying, NSCoding> currentToken = [NSFileManager defaultManager].ubiquityIdentityToken;
    id<NSObject, NSCopying, NSCoding> storedToken = [self storedUbiquityIdentityToken];
    
    BOOL currentTokenNilStoredNonNil = !currentToken && storedToken;
    BOOL storedTokenNilCurrentNonNil = !storedToken && currentToken;
    BOOL currentNotEqualStored = currentToken && storedToken && ![currentToken isEqual:storedToken];
    
    if (currentTokenNilStoredNonNil || storedTokenNilCurrentNonNil || currentNotEqualStored) {
        [self persistAccount];
        
        hasChanged = YES;
    }
    
    return hasChanged;
}

- (void)persistAccount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id<NSObject, NSCopying, NSCoding> token = [NSFileManager defaultManager].ubiquityIdentityToken;
    
    if (token) {
        // The account has changed.
        NSData *ubiquityIdentityTokenArchive = [NSKeyedArchiver archivedDataWithRootObject:token];
        
        [defaults setObject:ubiquityIdentityTokenArchive forKey: kMDBICloudManagerStoredUbiquityIdentityTokenKey];
    }
    else {
        // There is no signed-in account.
        [defaults removeObjectForKey: kMDBICloudManagerStoredUbiquityIdentityTokenKey];
    }
}

- (id<NSObject, NSCopying, NSCoding>)storedUbiquityIdentityToken {
    id<NSObject, NSCopying, NSCoding> storedToken = nil;
    
    // Determine if the iCloud account associated with this device has changed since the last time the user launched the app.
    NSData *ubiquityIdentityTokenArchive = [[NSUserDefaults standardUserDefaults] objectForKey: kMDBICloudManagerStoredUbiquityIdentityTokenKey];
    
    if (ubiquityIdentityTokenArchive) {
        storedToken = [NSKeyedUnarchiver unarchiveObjectWithData:ubiquityIdentityTokenArchive];
    }
    
    return storedToken;
}


@end