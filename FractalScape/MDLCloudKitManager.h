//  Created by Taun Chapman on 09/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import UIKit;
@import Foundation;
@import CloudKit;

@interface MDLCloudKitManager : NSObject

@property(nonatomic,strong)NSArray*     defaultSortDescriptors;

-(instancetype)initWithIdentifier: (NSString*)containerIdentifier;

#pragma mark - CloudKit
- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable))completionHandler;
- (void)discoverUserInfo:(void (^)(CKDiscoveredUserInfo *user))completionHandler;

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)queryForRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSArray *records))completionHandler;

- (void)savePublicRecord:(CKRecord *)record withCompletionHandler:(void (^)(NSError* error))completionHandler;
- (void)deletePublicRecord:(CKRecord *)record;
- (void)fetchPublicRecordsWithType:(NSString *)recordType predicate: (NSPredicate*)predicate sortDescriptor: (NSArray*) descriptors completionHandler:(void (^)(NSArray *records, NSError* error))completionHandler;
- (void)queryForPublicRecordsWithReferenceNamed:(NSString *)referenceRecordName completionHandler:(void (^)(NSArray *records))completionHandler;

@property (nonatomic, readonly, getter=isSubscribed) BOOL subscribed;
- (void)subscribe;
- (void)unsubscribe;

@end
