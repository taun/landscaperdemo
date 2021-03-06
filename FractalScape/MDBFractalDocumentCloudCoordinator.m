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
#import "MDBURLPlusMetaData.h"


@interface MDBFractalDocumentCloudCoordinator ()
@property (nonatomic, strong) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong) dispatch_queue_t documentsDirectoryQueue;
@property (nonatomic, strong) NSURL *documentsDirectory;
@end

@implementation MDBFractalDocumentCloudCoordinator

@synthesize delegate = _delegate;
@synthesize documentsDirectory = _documentsDirectory;

-(BOOL)isCloudBased
{
    return YES;
}

-(instancetype)copyWithZone:(NSZone *)zone
{
    MDBFractalDocumentCloudCoordinator* newCoord = [[[self class]alloc]initWithPredicate: self.metadataQuery.predicate];
    return newCoord;
}

- (instancetype)initWithPredicate:(NSPredicate *)predicate
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectoryQueue = dispatch_queue_create("com.moedae.FractalScapes.cloudDocumentCoordinator", DISPATCH_QUEUE_SERIAL);
        
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

- (instancetype)initWithPathExtension:(NSString *)pathExtension
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)", NSMetadataItemURLKey, pathExtension];
    
    self = [self initWithPredicate:predicate];
    
    if (self)
    {
        // No need for additional initialization.
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.lastPathComponent = %@)", NSMetadataItemURLKey, lastPathComponent];
    
    self = [self initWithPredicate:predicate];
    
    if (self)
    {
        // No need for additional initialization.
    }
    
    return self;
}

#pragma mark - Lifetime

- (void)dealloc
{
    // Stop observing the query.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:self.metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidUpdateNotification object:self.metadataQuery];
}

#pragma mark - Property Overrides

- (NSURL *)documentsDirectory
{
    __block NSURL *documentsDirectory;
    
    dispatch_sync(self.documentsDirectoryQueue, ^{
        documentsDirectory = self->_documentsDirectory;
    });
    
    return documentsDirectory;
}

#pragma mark - MDBFractalDocumentCoordinator

- (void)startQuery
{
    [self.metadataQuery startQuery];
}

- (void)stopQuery
{
    [self.metadataQuery stopQuery];
}

- (BOOL)canCreateFractalWithIdentifier:(NSString *)name
{
    if (name.length <= 0)
    {
        return NO;
    }
    
    NSURL *documentURL = [self documentURLForName:name];
    
    return ![[NSFileManager defaultManager] fileExistsAtPath:documentURL.path];
}

- (void)removeFractalAtURL:(NSURL *)URL
{
    [MDBDocumentUtilities removeDocumentAtURL:URL withCompletionHandler:^(NSError *error) {
        if (error)
        {
            [self.delegate documentCoordinatorDidFailRemovingDocumentAtURL:URL withError:error];
        }
        else
        {
            [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs:@[] removedURLs:@[[MDBURLPlusMetaData urlPlusMetaWithFileURL: URL metaData: nil]] updatedURLs:@[]];
        }
    }];
}

#pragma mark - NSMetadataQuery Notifications

- (void)metadataQueryDidFinishGathering:(NSNotification *)notification
{
    [self.metadataQuery disableUpdates];
    
    NSMutableArray *insertedURLs = [NSMutableArray arrayWithCapacity:self.metadataQuery.results.count];
    
    for (NSMetadataItem *metadataItem in self.metadataQuery.results)
    {
        NSURL *insertedURL = [metadataItem valueForAttribute: NSMetadataItemURLKey];
        
        [insertedURLs addObject: [MDBURLPlusMetaData urlPlusMetaWithFileURL: insertedURL metaData: metadataItem]];
    }
    
    [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs: insertedURLs removedURLs:@[] updatedURLs:@[]];
    
    [self.metadataQuery enableUpdates];
}

- (void)metadataQueryDidUpdate:(NSNotification *)notification
{
    [self.metadataQuery disableUpdates];
    
    NSArray *insertedURLs;
    NSArray *removedURLs;
    NSArray *updatedURLs;
    
    NSArray *insertedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey];
    if (insertedMetadataItemsOrNil.count > 0)
    {
        NSMetadataItem* firstItem = (NSMetadataItem*)insertedMetadataItemsOrNil[0];
        NSArray* attributes = firstItem.attributes;
        NSDictionary* values = [firstItem valuesForAttributes: attributes];
//        NSLog(@"InsertedMetadataItems: %@", values);

        insertedURLs = [self URLsByMappingMetadataItems:insertedMetadataItemsOrNil];
    }
    
    NSArray *removedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey];
    if (removedMetadataItemsOrNil.count > 0)
    {
        removedURLs = [self URLsByMappingMetadataItems:removedMetadataItemsOrNil];
    }
    
    NSArray *updatedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];
    if (updatedMetadataItemsOrNil.count > 0)
    {
        updatedURLs = [self URLsByMappingMetadataItems: updatedMetadataItemsOrNil];
    }
    
    NSIndexSet* indexesOfRemovedItemsToKeep = [removedURLs indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        BOOL keep = NO;
        MDBURLPlusMetaData* removedUrl = (MDBURLPlusMetaData*)obj;
        for (MDBURLPlusMetaData* url in updatedURLs)
        {
            if ([removedUrl isEqual: url])
            {
                keep = YES;
                break;
            }
        }
        return keep;
    }];
    
    NSMutableArray* mutableRemovedURLs = [removedURLs mutableCopy];
    [mutableRemovedURLs removeObjectsAtIndexes: indexesOfRemovedItemsToKeep];
    
    removedURLs = [mutableRemovedURLs copy];
    
    // Make sure that the arrays are all initialized before calling the didUpdateContents method.
    insertedURLs = insertedURLs ?: @[];
    removedURLs = removedURLs ?: @[];
    updatedURLs = updatedURLs ?: @[];
    
//    NSLog(@"insertedURLs: %@; removedURLS: %@; updatedURLS: %@", insertedURLs, removedURLs, updatedURLs);
    [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs: insertedURLs
                                                            removedURLs: removedURLs
                                                            updatedURLs: updatedURLs];
    
    [self.metadataQuery enableUpdates];
}

#pragma mark - Convenience

- (NSURL *)documentURLForName:(NSString *)name
{
    NSURL *documentURLWithoutExtension = [self.documentsDirectory URLByAppendingPathComponent:name];
    NSURL *documentWithExtension = [documentURLWithoutExtension URLByAppendingPathExtension: kMDBFractalDocumentFileExtension];
    return documentWithExtension;
}

- (NSArray <MDBURLPlusMetaData*>*)URLsByMappingMetadataItems:(NSArray *)metadataItems
{
    NSMutableArray *URLs = [NSMutableArray arrayWithCapacity: metadataItems.count];
    
    for (NSMetadataItem *metadataItem in metadataItems)
    {
        NSURL *URL = [metadataItem valueForAttribute: NSMetadataItemURLKey];
        
        [URLs addObject: [MDBURLPlusMetaData urlPlusMetaWithFileURL: URL metaData: metadataItem]];
    }
    
    return URLs;
}
@end
