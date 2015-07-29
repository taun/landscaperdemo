//
//  MDBCloudManager.h
//  FractalScapes
//
//  Created by Taun Chapman on 02/26/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;

@class MDBAppModel;

typedef NS_ENUM(NSInteger, MDBAPPStorage) {
    MDBAPPStorageNotSet = 0,
    MDBAPPStorageCloud,
    MDBAPPStorageLocal
};

typedef struct MDBAPPStorageState {
    MDBAPPStorage storageOption;
    BOOL accountDidChange;
    BOOL cloudAvailable;
} MDBAPPStorageState;

extern NSString *const kMDBCloudManagerUserActivityFractalIdentifierUserInfoKey;

extern NSString *const kMDBFractalDocumentFileUTI;
extern NSString *const kMDBFractalDocumentFileExtension;

extern NSString* const kMDBICloudStateUpdateNotification;
extern NSString* const kMDBUbiquitousContainerFetchingWillBeginNotification;
extern NSString* const kMDBUbiquitousContainerFetchingDidEndNotification;



@interface MDBCloudManager : NSObject

@property (nonatomic, weak) MDBAppModel                         *appModel;
@property (nonatomic, readonly, getter=isCloudAvailable) BOOL   cloudAvailable;
@property (nonatomic, readonly) MDBAPPStorageState              storageState;
@property (nonatomic) MDBAPPStorage                             storageOption;


@end
