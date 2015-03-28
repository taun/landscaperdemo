//  Created by Taun Chapman on 09/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import UIKit;
@import Foundation;
@import CloudKit;


extern NSString * const FractalNameField;
extern NSString * const FractalDescriptorField;
extern NSString * const FractalDocumentField;
extern NSString * const FractalThumbnailAssetField;

@interface MDLCloudKitManager : NSObject

#pragma mark - Daisy Cloud
- (void)fetchPublicPlantRecordsWithCompletionHandler:(void (^)(NSArray *records))completionHandler;


#pragma mark - sample cloud
- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable))completionHandler;
- (void)discoverUserInfo:(void (^)(CKDiscoveredUserInfo *user))completionHandler;

- (void)uploadAssetWithURL:(NSURL *)assetURL completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)addRecordWithName:(NSString *)name location:(CLLocation *)location completionHandler:(void (^)(CKRecord *record))completionHandler;

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)queryForRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSArray *records))completionHandler;

- (void)saveRecord:(CKRecord *)record;
- (void)deleteRecord:(CKRecord *)record;
- (void)fetchRecordsWithType:(NSString *)recordType completionHandler:(void (^)(NSArray *records))completionHandler;
- (void)queryForRecordsWithReferenceNamed:(NSString *)referenceRecordName completionHandler:(void (^)(NSArray *records))completionHandler;

@property (nonatomic, readonly, getter=isSubscribed) BOOL subscribed;
- (void)subscribe;
- (void)unsubscribe;

@end
