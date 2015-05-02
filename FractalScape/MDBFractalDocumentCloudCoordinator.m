//
//  MDBFractalDocumentCloudCoordinator.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalDocumentCloudCoordinator.h"
#import "MDBCloudManager.h"
#import "MDBDocumentUtilities.h"

@interface MDBFractalDocumentCloudCoordinator ()
@property (nonatomic, strong) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong) dispatch_queue_t documentsDirectoryQueue;
@property (nonatomic, strong) NSURL *documentsDirectory;
@end

@implementation MDBFractalDocumentCloudCoordinator

@synthesize delegate = _delegate;
@synthesize documentsDirectory = _documentsDirectory;

-(instancetype)copyWithZone:(NSZone *)zone
{
    MDBFractalDocumentCloudCoordinator* newCoord = [[[self class]alloc]initWithPredicate: self.metadataQuery.predicate];
    return newCoord;
}

- (instancetype)initWithPredicate:(NSPredicate *)predicate {
    self = [super init];
    
    if (self) {
        _documentsDirectoryQueue = dispatch_queue_create("com.moedae.FractalScapes.cloudDocumentCoordinator", 0ul);
        
        _metadataQuery = [[NSMetadataQuery alloc] init];
        _metadataQuery.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope];
        
        _metadataQuery.predicate = predicate;
        
        dispatch_barrier_async(_documentsDirectoryQueue, ^{
            NSURL *cloudContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
            
            self->_documentsDirectory = [cloudContainerURL URLByAppendingPathComponent:@"Documents"];
        });
        
        // Observe the query.
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self selector:@selector(metadataQueryDidFinishGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:_metadataQuery];
        
        [notificationCenter addObserver:self selector:@selector(metadataQueryDidUpdate:) name:NSMetadataQueryDidUpdateNotification object:_metadataQuery];
    }
    
    return self;
}

- (instancetype)initWithPathExtension:(NSString *)pathExtension {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)", NSMetadataItemURLKey, pathExtension];
    
    self = [self initWithPredicate:predicate];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.lastPathComponent = %@)", NSMetadataItemURLKey, lastPathComponent];
    
    self = [self initWithPredicate:predicate];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

#pragma mark - Lifetime

- (void)dealloc {
    // Stop observing the query.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:self.metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidUpdateNotification object:self.metadataQuery];
}

#pragma mark - Property Overrides

- (NSURL *)documentsDirectory {
    __block NSURL *documentsDirectory;
    
    dispatch_sync(self.documentsDirectoryQueue, ^{
        documentsDirectory = self->_documentsDirectory;
    });
    
    return documentsDirectory;
}

#pragma mark - MDBFractalDocumentCoordinator

- (void)startQuery {
    [self.metadataQuery startQuery];
}

- (void)stopQuery {
    [self.metadataQuery stopQuery];
}

- (BOOL)canCreateFractalWithIdentifier:(NSString *)name {
    if (name.length <= 0) {
        return NO;
    }
    
    NSURL *documentURL = [self documentURLForName:name];
    
    return ![[NSFileManager defaultManager] fileExistsAtPath:documentURL.path];
}

- (void)removeFractalAtURL:(NSURL *)URL {
    [MDBDocumentUtilities removeDocumentAtURL:URL withCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate documentCoordinatorDidFailRemovingDocumentAtURL:URL withError:error];
        }
        else {
            [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs:@[] removedURLs:@[URL] updatedURLs:@[]];
        }
    }];
}

#pragma mark - NSMetadataQuery Notifications

- (void)metadataQueryDidFinishGathering:(NSNotification *)notification {
    [self.metadataQuery disableUpdates];
    
    NSMutableArray *insertedURLs = [NSMutableArray arrayWithCapacity:self.metadataQuery.results.count];
    for (NSMetadataItem *metadataItem in self.metadataQuery.results) {
        NSURL *insertedURL = [metadataItem valueForAttribute:NSMetadataItemURLKey];
        
        [insertedURLs addObject:insertedURL];
    }
    
    [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs:insertedURLs removedURLs:@[] updatedURLs:@[]];
    
    [self.metadataQuery enableUpdates];
}

- (void)metadataQueryDidUpdate:(NSNotification *)notification {
    [self.metadataQuery disableUpdates];
    
    NSArray *insertedURLs;
    NSArray *removedURLs;
    NSArray *updatedURLs;
    
    NSArray *insertedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey];
    if (insertedMetadataItemsOrNil.count > 0) {
        NSMetadataItem* firstItem = (NSMetadataItem*)insertedMetadataItemsOrNil[0];
        NSArray* attributes = firstItem.attributes;
        NSDictionary* values = [firstItem valuesForAttributes: attributes];
        NSLog(@"InsertedMetadataItems: %@", values);

        insertedURLs = [self URLsByMappingMetadataItems:insertedMetadataItemsOrNil];
    }
    
    NSArray *removedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey];
    if (removedMetadataItemsOrNil.count > 0) {
        removedURLs = [self URLsByMappingMetadataItems:removedMetadataItemsOrNil];
    }
    
    NSArray *updatedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];
    if (updatedMetadataItemsOrNil.count > 0) {
        NSMetadataItem* firstItem = (NSMetadataItem*)updatedMetadataItemsOrNil[0];
        NSArray* attributes = firstItem.attributes;
        NSDictionary* values = [firstItem valuesForAttributes: attributes];
        NSLog(@"UpdatedMetadataItems: %@", values);
        
        NSIndexSet *indexesOfCompletelyDownloadedUpdatedMetadataItems = [updatedMetadataItemsOrNil indexesOfObjectsPassingTest:^BOOL(NSMetadataItem *updatedMetadataItem, NSUInteger idx, BOOL *stop) {
            NSString *downloadStatus = [updatedMetadataItem valueForAttribute: NSMetadataUbiquitousItemDownloadingStatusKey];
            BOOL downloadedIsCurrent = [downloadStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusCurrent];
            
            NSInteger isUploading = [[updatedMetadataItem valueForAttribute: NSMetadataUbiquitousItemIsUploadingKey] integerValue];
            
            BOOL keep = downloadedIsCurrent && !isUploading;
//            NSString *downloadStatus = [updatedMetadataItem valueForAttribute: NSMetadataUbiquitousItemDownloadingStatusKey];
//            BOOL justDownloadedNewOne = [downloadStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusDownloaded];
//            
//            NSInteger isDownloaded = [[updatedMetadataItem valueForAttribute: NSMetadataUbiquitousItemIsDownloadedKey] integerValue];
//            
//            BOOL keep = justDownloadedNewOne && !isDownloaded;
            
            return keep;
        }];
        
        NSArray *completelyDownloadedUpdatedMetadataItems = [updatedMetadataItemsOrNil objectsAtIndexes:indexesOfCompletelyDownloadedUpdatedMetadataItems];
        
        updatedURLs = [self URLsByMappingMetadataItems: completelyDownloadedUpdatedMetadataItems];
    }
    
    // Make sure that the arrays are all initialized before calling the didUpdateContents method.
    insertedURLs = insertedURLs ?: @[];
    removedURLs = removedURLs ?: @[];
    updatedURLs = updatedURLs ?: @[];
    
    NSLog(@"insertedURLs: %@; removedURLS: %@; updatedURLS: %@", insertedURLs, removedURLs, updatedURLs);
    [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs:insertedURLs removedURLs:removedURLs updatedURLs:updatedURLs];
    
    [self.metadataQuery enableUpdates];
}

#pragma mark - Convenience

- (NSURL *)documentURLForName:(NSString *)name
{
    NSURL *documentURLWithoutExtension = [self.documentsDirectory URLByAppendingPathComponent: name];
    
    return [documentURLWithoutExtension URLByAppendingPathExtension: kMDBFractalDocumentFileExtension];
}

- (NSArray *)URLsByMappingMetadataItems:(NSArray *)metadataItems {
    NSMutableArray *URLs = [NSMutableArray arrayWithCapacity:metadataItems.count];
    
    for (NSMetadataItem *metadataItem in metadataItems) {
        NSURL *URL = [metadataItem valueForAttribute:NSMetadataItemURLKey];
        
        [URLs addObject:URL];
    }
    
    return URLs;
}
@end
