//
//  MDBAppModel.h
//  FractalScapes
//
//  Created by Taun Chapman on 04/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;
@import StoreKit;

#import "MDCKCloudManagerAppModelProtocol.h"

@class MBAppDelegate;
@class MDBDocumentController;
@class MDLCloudKitManager;
@class MDBCloudManager;
@class MDBPurchaseManager;
@class LSDrawingRuleType;

extern NSString *const kMDBFractalScapesFirstLaunchUserDefaultsKey;
extern NSString *const kMDBFractalCloudContainer;

/*!
 2020 hindsight, should have just left all this in the AppDelegate and inplace of passing around an appModel, 
 accessed the AppDelegate. Everything has moved here making this the same as the AppDelegate without any reduction 
 in complexity.
 */
@interface MDBAppModel : NSObject <MDCKCloudManagerAppModelProtocol>

@property(nonatomic,weak) MBAppDelegate                         *delegate;
@property(nonatomic,readonly) NSString                          *versionBuildString;
@property(nonatomic,readonly) NSString                          *versionString;
@property(nonatomic,readonly) NSString                          *buildString;
@property(nonatomic,readonly) BOOL                              loadDemoFiles;
@property(nonatomic,readonly) BOOL                              cloudIdentityChangedState;
@property(nonatomic,strong) MDBDocumentController               *documentController;
@property(nonatomic,readonly) MDBCloudManager                   *cloudDocumentManager;
@property(nonatomic,readonly) MDLCloudKitManager                *cloudKitManager;
@property(nonatomic,readonly) MDBPurchaseManager                *purchaseManager;
@property(nonatomic,readonly) BOOL                              allowPremium;
@property(nonatomic,readonly) BOOL                              useWatermark;
@property(nonatomic,readonly) BOOL                              promptedForDiscovery;
@property(nonatomic,readonly) BOOL                              welcomeDone;
@property(nonatomic,readonly) BOOL                              editorIntroDone;
@property(nonatomic,readonly) BOOL                              userCanMakePayments;

@property(nonatomic,readonly) LSDrawingRuleType               *sourceDrawingRules;
@property(nonatomic,readonly) NSArray                         *sourceColorCategories;


-(void)loadInitialDocuments;
/*!
 Needs to check storage state and revert to root controller if changed.
 Needs to update all of the settings in userDefaults for controller KVO.
    Don't reload settings if cloud identity changed?
 */
-(void)handleDidBecomeActive;
-(void)handleMoveToBackground;
/*!
 Checks if the cloud identity changed
 */
-(void)setupUserStoragePreferences;
-(void)demoFilesLoaded;

-(void)exitWelcomeState;
-(void)exitEditorIntroState;

-(void)enterCloudIdentityChangedState;
-(void)exitCloudIdentityChangedState;

-(void)setShowParallax: (BOOL)show;
-(BOOL)showParallax;

-(void)setShowPerformanceData: (BOOL)show;
-(BOOL)showPerformanceData;

-(void)setFullScreenState: (BOOL)on;
-(BOOL)fullScreenState;

-(void)setShowHelpTips: (BOOL)show;
-(BOOL)showHelpTips;

-(void)___setAllowPremium: (BOOL)on;
-(void)___setUseWatermark: (BOOL)on;

#pragma mark - In-App Purchasing
-(BOOL)loadAdditionalColorsFromPlistFileNamed: (NSString*)fileName;

@end
