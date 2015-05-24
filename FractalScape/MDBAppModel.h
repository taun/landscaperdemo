//
//  MDBAppModel.h
//  FractalScapes
//
//  Created by Taun Chapman on 04/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;

@class MDBDocumentController;
@class MDLCloudKitManager;

extern NSString *const kMDBFractalScapesFirstLaunchUserDefaultsKey;
extern NSString *const kMDBFractalCloudContainer;

@interface MDBAppModel : NSObject

@property(nonatomic,assign,getter=isFirstLaunch) BOOL           firstLaunch;
@property(nonatomic,strong) MDBDocumentController               *documentController;
@property(nonatomic,readonly) MDLCloudKitManager                *cloudManager;
@property(nonatomic,readonly) BOOL                              allowPremium;
@property(nonatomic,readonly) BOOL                              useWatermark;
@end
