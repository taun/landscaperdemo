//
//  MDBDocumentController.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/03/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;

#import "MDBDocumentController.h"
#import "MDBFractalDocumentCoordinator.h"
#import "MDBFractalInfo.h"
#import "MDBFractalDocument.h"
#import "MDBURLPlusMetaData.h"


//#define MDB_QUEUE_LOG

@interface MDBDocumentController () <MDBFractalDocumentCoordinatorDelegate>

@property (atomic, strong, readwrite) NSMutableArray*                      fractalInfos;

/*!
 * The \c MDBFractalDocumentInfo objects that are cached by the \c MDBFractalDocumentController to allow for users of the
 * \c MDBFractalDocumentController class to easily subscript the controller.
 */
@property (nonatomic, strong) NSMutableArray *privateFractalInfos;

/*!
 * @return A private, local queue to the \c MDBFractalDocumentController that is used to perform updates on
 *         \c documentInfos.
 */
@property (nonatomic, strong) dispatch_queue_t fractalReadQueue;
@property (nonatomic, strong) dispatch_queue_t fractalUpdateQueue;

@end




@implementation MDBDocumentController

@synthesize documentCoordinator = _documentCoordinator;

#pragma mark - Initialization

- (instancetype)initWithDocumentCoordinator:(id<MDBFractalDocumentCoordinator>)documentCoordinator sortComparator:(NSComparisonResult (^)(MDBFractalInfo *, MDBFractalInfo *))sortComparator {
    self = [super init];
    
    if (self) {
        _documentCoordinator = documentCoordinator;
        _sortComparator = sortComparator;
        
        _fractalUpdateQueue = dispatch_queue_create("com.moedae.FractalScapes.documentcontroller.update", DISPATCH_QUEUE_SERIAL);
        _fractalReadQueue = _fractalUpdateQueue;
        //        _fractalReadQueue = dispatch_queue_create("com.moedae.FractalScapes.documentcontroller.read", DISPATCH_QUEUE_SERIAL);
        _privateFractalInfos = [NSMutableArray array];
        _fractalInfos = [NSMutableArray array];
        
        _documentCoordinator.delegate = self;
        
//        [_documentCoordinator startQuery];
    }
    
    return self;
}

- (id) debugQuickLookObject
{
    return [self debugDescription];
}

-(NSString*)debugDescription
{
    //    NSString* ddesc = [NSString stringWithFormat: @"Name: %@\nDescription: %@\nLevels: %lu\nStarting Rules: %@\nReplacement Rules: %@",_name,_descriptor,_level,[self startingRulesAsString],[self replacementRulesAsPListArray]];
    NSString* ddesc = [NSString stringWithFormat: @"FractalInfos: %@",_fractalInfos];
    return ddesc;
}

-(void)closeAllDocuments
{
    for (MDBFractalInfo* info in self.fractalInfos)
    {
        [info closeDocument];
    }
}

-(void)dealloc
{
    _documentCoordinator.delegate = nil;
}

#pragma mark - Property Overrides

//- (NSInteger)count {
//    return self.privateFractalInfos.count;
//}

- (void)setDocumentCoordinator:(id<MDBFractalDocumentCoordinator>)documentCoordinator {
    if (![_documentCoordinator isEqual:documentCoordinator]) {
        id<MDBFractalDocumentCoordinator> oldDocumentCoordinator = _documentCoordinator;
        _documentCoordinator = documentCoordinator;
        
        [oldDocumentCoordinator stopQuery];
        
        // Map the fractalInfo objects protected by documentInfoQueue.
        __block NSArray *allURLs;
        dispatch_sync(self.fractalUpdateQueue, ^{
#ifdef MDB_QUEUE_LOG
            NSLog(@"%@ %@ queue: %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),self.fractalUpdateQueue);
#endif
            allURLs = [self.fractalInfos valueForKey:@"urlPlusMeta"];
        });
        
        [self processContentChangesWithInsertedURLs:@[] removedURLs: allURLs updatedURLs:@[]];
        
        oldDocumentCoordinator.delegate = nil;
        _documentCoordinator.delegate = self;
        
//        [_documentCoordinator startQuery];
    }
}


#pragma mark - Subscripting
/*!
 File handling notes:
 
 FractalInfo is really redudndant. Can't get any info without loading the full document and the document is very lightweight (<1k + thumbnail) so just load it?
 
 Problem is we don't want cloud thumbnails in memory until the collectionCell needs it.
 
 Can't load thumbnail separately without using a fileWrapper style document. Also works better for cloud storage?
 
 FractalInfo = fractal text part of fileWrapper contents.
 Thumbnail = separate file.
 
 */
//- (MDBFractalInfo *)objectAtIndexedSubscript:(NSInteger)index
//{
//    // Fetch the appropriate document info protected by documentInfoQueue.
//    __block MDBFractalInfo *fractalInfo = nil;
//    
//    dispatch_sync(self.fractalUpdateQueue, ^{
//#ifdef MDB_QUEUE_LOG
//        NSLog(@"%@ %@ queue: %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),self.fractalUpdateQueue);
//#endif
//        fractalInfo = self.privateFractalInfos[index];
//    });
//    
//    return fractalInfo;
//}

//-(NSUInteger) indexOfObject: (id) object
//{
//    __block NSUInteger index;
//    
//    dispatch_sync(self.fractalUpdateQueue, ^{
//        index = [self.privateFractalInfos indexOfObject: object];
//    });
//    
//    return index;
//}

-(MDBFractalInfo*)controllerFractalInfoFor:(MDBFractalInfo *)fractalInfo
{
    __block MDBFractalInfo *controllerFractalInfo = nil;
    dispatch_sync(self.fractalUpdateQueue, ^{
#ifdef MDB_QUEUE_LOG
        NSLog(@"%@ %@ queue: %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),self.fractalUpdateQueue);
#endif
        NSUInteger index = [self.fractalInfos indexOfObject: fractalInfo];
        if (index != NSNotFound) {
            controllerFractalInfo = self.fractalInfos[index];
        }
    });
    
    return controllerFractalInfo;
}


#pragma mark - Inserting / Removing / Managing / Updating MDBFractalDocumentInfo Objects

- (void)removeFractalInfo:(MDBFractalInfo *)fractalInfo
{
    [self.documentCoordinator removeFractalAtURL: fractalInfo.urlPlusMeta.fileURL];
}

- (MDBFractalInfo*)createFractalInfoForFractal:(LSFractal *)fractal withDocumentDelegate: (id)delegate
{
    NSString* newIdentifier;
    NSInteger numTries = 10;
    do
    {
        newIdentifier = [[NSUUID UUID] UUIDString];
        numTries--;
    } while (![self canCreateFractalInfoWithIdentifier: newIdentifier] && numTries > 0);
    
    if (numTries == 0) {
        NSLog(@"%@, %@ Error, too may tries to get a unique identifier.",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    }
    
    NSURL* documentURL = [self.documentCoordinator documentURLForName: newIdentifier];

    MDBFractalInfo* newFractalInfo = [MDBFractalInfo newFractalInfoWithURLPlusMeta: [MDBURLPlusMetaData urlPlusMetaWithFileURL: documentURL metaData: nil]
                                                                        forFractal: fractal documentDelegate: delegate];
    
        //
        //        dispatch_async(self.fractalUpdateQueue, ^{
#ifdef MDB_QUEUE_LOG
        NSLog(@"%@ %@ queue: %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),self.fractalUpdateQueue);
#endif
//        id<MDBFractalDocumentControllerDelegate> strongDelegate = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [newFractalInfo.document saveToURL: newFractalInfo.document.fileURL forSaveOperation: UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                
                if (success && !self.documentCoordinator.isCloudBased)
                {
                    [self willChange: NSKeyValueChangeInsertion valuesAtIndexes: [NSIndexSet indexSetWithIndex: 0] forKey:@"fractalInfos"];
                    
                    [self.fractalInfos insertObject: newFractalInfo atIndex: 0];
                    
                    [self didChange: NSKeyValueChangeInsertion valuesAtIndexes: [NSIndexSet indexSetWithIndex: 0] forKey:@"fractalInfos"];
                }
            }];
        });
    
    return newFractalInfo;
}

- (BOOL)canCreateFractalInfoWithIdentifier:(NSString *)name
{
    return [self.documentCoordinator canCreateFractalWithIdentifier:name];
}

- (void)setFractalInfoHasNewContents:(MDBFractalInfo *)fractalInfo
{
    dispatch_async(self.fractalUpdateQueue, ^{
        // Remove the old document info and replace it with the new one.
#ifdef MDB_QUEUE_LOG
        NSLog(@"%@ %@ queue: %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),self.fractalUpdateQueue);
#endif
//        id<MDBFractalDocumentControllerDelegate> strongDelegate = self.delegate;
        NSInteger indexOfFractalInfo = [self.fractalInfos indexOfObject: fractalInfo];
        
//        NSIndexPath* indexPath = [NSIndexPath indexPathForRow: indexOfFractalInfo inSection: 0];
//        NSIndexPath* destination = [NSIndexPath indexPathForRow: 0 inSection: 0];
        
        if (indexOfFractalInfo == NSNotFound)
        {
//            NSLog  (@"%@, Error: FractalInfo not found: %@",NSStringFromSelector(_cmd), fractalInfo);
        }
        else if (indexOfFractalInfo == 0)
        {
//            [strongDelegate documentControllerWillChangeContent:self];
#pragma message "TODO: These can probably be async"
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSMutableArray* mutableArray = [self mutableArrayValueForKey: @"fractalInfos"];
                mutableArray[indexOfFractalInfo] = fractalInfo;
            });
                          
//            [strongDelegate documentController: self didUpdateFractalInfosAtIndexPaths: @[indexPath] totalRows: self.fractalInfos.count];
//            [strongDelegate documentControllerDidChangeContent:self];
        }
        else
        {
//            self.fractalInfos[indexOfFractalInfo] = fractalInfo;
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSMutableArray* mutableArray = [self mutableArrayValueForKey: @"fractalInfos"];
                [mutableArray removeObject: fractalInfo];
                [mutableArray insertObject: fractalInfo atIndex: 0];
            });
            
//            [strongDelegate documentControllerWillChangeContent:self];
//            [strongDelegate documentController: self didMoveFractalInfoAtIndexPath: indexPath toIndexPath: destination];
//            [strongDelegate documentController: self didUpdateFractalInfosAtIndexPaths: @[destination] totalRows: self.fractalInfos.count];
//            [strongDelegate documentControllerDidChangeContent:self];
        }
    });
}

- (void)documentCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray <MDBURLPlusMetaData*> *)insertedURLs removedURLs:(NSArray <MDBURLPlusMetaData*> *)removedURLs updatedURLs:(NSArray <MDBURLPlusMetaData*> *)updatedURLs
{
    [self processContentChangesWithInsertedURLs: insertedURLs removedURLs: removedURLs updatedURLs: updatedURLs];
}

- (void)documentCoordinatorDidFailCreatingDocumentAtURL:(NSURL *)URL withError:(NSError *)error
{
    MDBFractalInfo *fractalInfo = [[MDBFractalInfo alloc] initWithURLPlusMeta: [MDBURLPlusMetaData urlPlusMetaWithFileURL: URL metaData: nil]];
    
    [self.delegate documentController:self didFailCreatingFractalInfo:fractalInfo withError:error];
}

- (void)documentCoordinatorDidFailRemovingDocumentAtURL:(NSURL *)URL withError:(NSError *)error
{
    MDBFractalInfo *fractalInfo = [[MDBFractalInfo alloc] initWithURLPlusMeta: [MDBURLPlusMetaData urlPlusMetaWithFileURL: URL metaData: nil]];
    
    [self.delegate documentController:self didFailRemovingFractalInfo: fractalInfo withError:error];
}

#pragma mark - Change Processing

/*!
 * Processes inteneded changes to the \c MDBFractalDocumentController object's \c MDBFractalDocumentInfo collection. This
 * implementation performs the updates and determines where each of these URLs were located so that
 * the controller can forward the new / removed / updated indexes as well.
 *
 * @param insertedURLs The \c NSURL instances that are newly tracked.
 * @param removedURLs The \c NSURL instances that have just been untracked.
 * @param updatedURLs The \c NSURL instances that have had their underlying model updated.
 */
- (void)processContentChangesWithInsertedURLs:(NSArray <MDBURLPlusMetaData*> *)insertedURLs removedURLs:(NSArray <MDBURLPlusMetaData*> *)removedURLs updatedURLs:(NSArray <MDBURLPlusMetaData*> *)updatedURLs {
    NSArray *insertedFractalInfos = [self fractalInfosByMappingURLs: insertedURLs];
    NSArray *removedFractalInfos = [self fractalInfosByMappingURLs: removedURLs];
    NSArray *updatedFractalInfos = [self fractalInfosByMappingURLs: updatedURLs];
    
    if (!insertedURLs && !removedURLs && !updatedURLs) {
        return;
    }
    
    dispatch_async(self.fractalReadQueue, ^{
        // Filter out all documents that are already included in the tracked documents.
#ifdef MDB_QUEUE_LOG
        NSLog(@"%@ %@ queue: %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),self.fractalReadQueue);
#endif
        NSIndexSet *indexesOfTrackedremovedFractalInfos = [removedFractalInfos indexesOfObjectsPassingTest:^BOOL(MDBFractalInfo *fractalInfo, NSUInteger idx, BOOL *stop) {
            return [self.fractalInfos containsObject:fractalInfo];
        }];
        
        NSIndexSet *indexesOfUntrackedInsertedFractalInfos = [insertedFractalInfos indexesOfObjectsPassingTest:^BOOL(MDBFractalInfo *fractalInfo, NSUInteger idx, BOOL *stop) {
            return ![self.fractalInfos containsObject:fractalInfo];
        }];
        
        if (indexesOfUntrackedInsertedFractalInfos.count == 0 && indexesOfTrackedremovedFractalInfos.count == 0 && updatedURLs.count == 0) {
            return;
        }
        
        NSArray *trackedRemovedFractalInfos = [removedFractalInfos objectsAtIndexes: indexesOfTrackedremovedFractalInfos];
        NSArray *untrackedInsertedFractalInfos = [insertedFractalInfos objectsAtIndexes: indexesOfUntrackedInsertedFractalInfos];
        
//        [self.delegate documentControllerWillChangeContent:self];
        
        // Remove all of the removed documents. We need to send the delegate the removed indexes before
        // the documentInfos array is mutated to reflect the new changes. To do that, we'll build up the
        // array of removed indexes *before* we mutate it.
        if (trackedRemovedFractalInfos && trackedRemovedFractalInfos.count > 0)
        {
            [self notifyAndRemoveInfos: trackedRemovedFractalInfos];
        }
        
        // Add the new documents.
        if (untrackedInsertedFractalInfos && untrackedInsertedFractalInfos.count > 0)
        {
            [self notifyAndInsertAndSortUntrackedFractalInfos: untrackedInsertedFractalInfos];
        }
        
        // Update the old documents.
        if (updatedFractalInfos && updatedFractalInfos.count > 0)
        {
            NSMutableArray* reallyUpdatedInfos = [NSMutableArray arrayWithCapacity: updatedFractalInfos.count];
            NSMutableArray* statusUpdatedInfos = [NSMutableArray arrayWithCapacity: updatedFractalInfos.count];
           
            for (MDBFractalInfo*updatedInfo in updatedFractalInfos)
            {
                NSUInteger index = [self.fractalInfos indexOfObject: updatedInfo]; // searches based on URL match
                
                if (index != NSNotFound) // this should always be the case otherwise it would have been "inserted" not "updated"
                {
                    MDBFractalInfo* currentInfo = self.fractalInfos[index];
                    
                    NSComparisonResult dateComparison = [updatedInfo.changeDate compare: currentInfo.changeDate];
                    
                    [currentInfo updateMetaDataWith: updatedInfo.urlPlusMeta.metaDataItem];

                    if (dateComparison == NSOrderedSame || updatedInfo.isUploading || updatedInfo.isDownloading)
                    {
                        [statusUpdatedInfos addObject: currentInfo];
                    }
                    else if (dateComparison == NSOrderedAscending)
                    { // current is newer
                        [reallyUpdatedInfos addObject: currentInfo];
                    }
                    else if (dateComparison == NSOrderedDescending)
                    { // updated is newer
                        [reallyUpdatedInfos addObject: updatedInfo];
                    }
                }
            }
            
            if (statusUpdatedInfos.count > 0)
            {
                [self notifyInfosStatusChange: statusUpdatedInfos];
            }
            
            // remove really updated infos
            if (reallyUpdatedInfos.count > 0)
            {
                NSUInteger index = [self.fractalInfos indexOfObject: reallyUpdatedInfos[0]];
                
                if (index == 0 && reallyUpdatedInfos.count == 1)
                {
                    // just update
                    [self notifyAndUpdateInfos: reallyUpdatedInfos];
                }
                else
                {
                    [self notifyAndRemoveInfos: reallyUpdatedInfos];
                    // insert and sort
                    [self notifyAndInsertAndSortUntrackedFractalInfos: reallyUpdatedInfos];
                }
            }
        }
        
//        [self.delegate documentControllerDidChangeContent:self];
    });
}

-(void)notifyInfosStatusChange: (NSArray*)changedFractalInfos
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (MDBFractalInfo* info in changedFractalInfos)
        {
            [info setFileStatusChanged: info.fileStatusChanged + 1]; // being observed by collection cells status badge
        }
    });
}

-(void)notifyAndUpdateInfos: (NSArray*)updatedFractalInfos
{
    NSMutableIndexSet* updatedIndexes = [NSMutableIndexSet new];
    
    for (MDBFractalInfo *updatedFractalInfo in updatedFractalInfos)
    {
        NSUInteger updateIndex = [self.fractalInfos indexOfObject: updatedFractalInfo];
        if (updateIndex != NSNotFound)
        {
            [updatedIndexes addIndex: updateIndex];
        }
        NSAssert(updateIndex != NSNotFound, @"An updated fractal info should always already be tracked in the fractal infos.");
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self willChange: NSKeyValueChangeReplacement valuesAtIndexes: updatedIndexes forKey:@"fractalInfos"];
        {
            for (MDBFractalInfo* info in updatedFractalInfos)
            {
                NSUInteger updateIndex = [self.fractalInfos indexOfObject: info];
                if (updateIndex != NSNotFound)
                {
                    self.fractalInfos[updateIndex] = info;
                }
            }
        }
        [self didChange: NSKeyValueChangeReplacement valuesAtIndexes: updatedIndexes forKey:@"fractalInfos"];
    });
}

-(void)notifyAndRemoveInfos: (NSArray*)removedFractalInfos
{
    // remove really updated infos
    NSMutableIndexSet* removedIndexes = [NSMutableIndexSet new];
    
    for (MDBFractalInfo *removedFractalInfo in removedFractalInfos)
    {
        NSUInteger removedIndex = [self.fractalInfos indexOfObject: removedFractalInfo];
        if (removedIndex != NSNotFound)
        {
            [removedIndexes addIndex: removedIndex];
        }
        NSAssert(removedIndex != NSNotFound, @"A removed fractal info should always already be tracked in the fractal infos.");
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self willChange: NSKeyValueChangeRemoval valuesAtIndexes: removedIndexes forKey:@"fractalInfos"];
        {
                [self.fractalInfos removeObjectsAtIndexes: removedIndexes];
        }
        [self didChange: NSKeyValueChangeRemoval valuesAtIndexes: removedIndexes forKey:@"fractalInfos"];
    });

}
-(void)notifyAndInsertAndSortUntrackedFractalInfos: (NSArray*)untrackedInsertedFractalInfos
{
    NSMutableIndexSet* sortedIndexes = [NSMutableIndexSet new];
    
    NSArray* sortedUntrackedInfos = untrackedInsertedFractalInfos;
    
    NSMutableArray* integratedSortedFractalInfos = [self.fractalInfos mutableCopy];
    
    [integratedSortedFractalInfos addObjectsFromArray: untrackedInsertedFractalInfos];
    
    if (self.sortComparator)
    {
        [integratedSortedFractalInfos sortUsingComparator: self.sortComparator];
        sortedUntrackedInfos = [untrackedInsertedFractalInfos sortedArrayUsingComparator: self.sortComparator];
    }
    
    for (MDBFractalInfo* insertedInfo in sortedUntrackedInfos)
    {
        NSUInteger index = [integratedSortedFractalInfos indexOfObject: insertedInfo];
        if (index != NSNotFound)
        {
            [sortedIndexes addIndex: index];
        }
    }
    
    [sortedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        MDBFractalInfo* infoToInsert = integratedSortedFractalInfos[idx];
        dispatch_sync(dispatch_get_main_queue(), ^{
            {
                NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex: idx];
                [self willChange: NSKeyValueChangeInsertion valuesAtIndexes: indexSet forKey:@"fractalInfos"];
                [self.fractalInfos insertObject: infoToInsert atIndex: idx];
                [self didChange: NSKeyValueChangeInsertion valuesAtIndexes: indexSet forKey:@"fractalInfos"];
            }
        });
    }];
    
}

#pragma mark - Convenience

- (NSArray *)fractalInfosByMappingURLs:(NSArray <MDBURLPlusMetaData*> *)metaArray {
    NSMutableArray *fractalInfos = [NSMutableArray arrayWithCapacity: metaArray.count];
    
    for (MDBURLPlusMetaData *plusMeta in metaArray) {
        MDBFractalInfo *fractalInfo = [[MDBFractalInfo alloc] initWithURLPlusMeta: plusMeta];
        
        [fractalInfos addObject: fractalInfo];
    }
    
    return fractalInfos;
}

@end
