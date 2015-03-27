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

//#define MDB_QUEUE_LOG

@interface MDBDocumentController () <MDBFractalDocumentCoordinatorDelegate>

/*!
 * The \c MDBFractalDocumentInfo objects that are cached by the \c MDBFractalDocumentController to allow for users of the
 * \c MDBFractalDocumentController class to easily subscript the controller.
 */
@property (nonatomic, strong) NSMutableArray *fractalInfos;

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
        _fractalInfos = [NSMutableArray array];
        
        _documentCoordinator.delegate = self;
        
        [_documentCoordinator startQuery];
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


#pragma mark - Property Overrides

- (NSInteger)count {
    return self.fractalInfos.count;
}

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
            allURLs = [self.fractalInfos valueForKey:@"URL"];
        });
        [self processContentChangesWithInsertedURLs:@[] removedURLs:allURLs updatedURLs:@[]];
        
        _documentCoordinator.delegate = self;
        oldDocumentCoordinator.delegate = nil;
        
        [_documentCoordinator startQuery];
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
- (MDBFractalInfo *)objectAtIndexedSubscript:(NSInteger)index {
    // Fetch the appropriate document info protected by documentInfoQueue.
    __block MDBFractalInfo *fractalInfo = nil;
    
    dispatch_sync(self.fractalUpdateQueue, ^{
#ifdef MDB_QUEUE_LOG
        NSLog(@"%@ %@ queue: %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),self.fractalUpdateQueue);
#endif
        fractalInfo = self.fractalInfos[index];
    });
    
    return fractalInfo;
}

#pragma mark - Inserting / Removing / Managing / Updating MDBFractalDocumentInfo Objects

- (void)removeFractalInfo:(MDBFractalInfo *)fractalInfo
{
    [self.documentCoordinator removeFractalAtURL: fractalInfo.URL];
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

    MDBFractalInfo* newFractalInfo = [MDBFractalInfo newFractalInfoWithURL: documentURL forFractal: fractal documentDelegate: delegate];
    
    [newFractalInfo.document saveToURL: newFractalInfo.document.fileURL forSaveOperation: UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        //
        dispatch_async(self.fractalUpdateQueue, ^{
#ifdef MDB_QUEUE_LOG
            NSLog(@"%@ %@ queue: %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),self.fractalUpdateQueue);
#endif
            id<MDBFractalDocumentControllerDelegate> strongDelegate = self.delegate;
            if (![self.fractalInfos containsObject: newFractalInfo]) {
                [strongDelegate documentControllerWillChangeContent:self];
                
                [self.fractalInfos addObject: newFractalInfo];
                NSInteger indexOfFractalInfo = [self.fractalInfos indexOfObject: newFractalInfo];
                NSIndexPath* indexPath = [NSIndexPath indexPathForRow: indexOfFractalInfo inSection: 0];
                [strongDelegate documentController:self didInsertFractalInfosAtIndexPaths: @[indexPath] totalRows: self.count];
                
                [strongDelegate documentControllerDidChangeContent:self];
            };
        });
    }];
    
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
        id<MDBFractalDocumentControllerDelegate> strongDelegate = self.delegate;
        NSInteger indexOfFractalInfo = [self.fractalInfos indexOfObject: fractalInfo];
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow: indexOfFractalInfo inSection: 0];
        
        if (indexOfFractalInfo != NSNotFound)
        {
            self.fractalInfos[indexOfFractalInfo] = fractalInfo;
            
            [strongDelegate documentControllerWillChangeContent:self];
            [strongDelegate documentController:self didUpdateFractalInfosAtIndexPaths: @[indexPath] totalRows: self.count];
            [strongDelegate documentControllerDidChangeContent:self];
        } else
        {
            NSLog(@"%@, FractalInfo not found: %@",NSStringFromSelector(_cmd), fractalInfo);
        }
    });
}

- (void)documentCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs removedURLs:(NSArray *)removedURLs updatedURLs:(NSArray *)updatedURLs
{
    [self processContentChangesWithInsertedURLs:insertedURLs removedURLs:removedURLs updatedURLs:updatedURLs];
}

- (void)documentCoordinatorDidFailCreatingDocumentAtURL:(NSURL *)URL withError:(NSError *)error
{
    MDBFractalInfo *fractalInfo = [[MDBFractalInfo alloc] initWithURL:URL];
    
    [self.delegate documentController:self didFailCreatingFractalInfo:fractalInfo withError:error];
}

- (void)documentCoordinatorDidFailRemovingDocumentAtURL:(NSURL *)URL withError:(NSError *)error
{
    MDBFractalInfo *fractalInfo = [[MDBFractalInfo alloc] initWithURL:URL];
    
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
- (void)processContentChangesWithInsertedURLs:(NSArray *)insertedURLs removedURLs:(NSArray *)removedURLs updatedURLs:(NSArray *)updatedURLs {
    NSArray *insertedFractalInfos = [self fractalInfosByMappingURLs:insertedURLs];
    NSArray *removedFractalInfos = [self fractalInfosByMappingURLs:removedURLs];
    NSArray *updatedFractalInfos = [self fractalInfosByMappingURLs:updatedURLs];
    
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
        
        NSArray *trackedRemovedFractalInfos = [removedFractalInfos objectsAtIndexes:indexesOfTrackedremovedFractalInfos];
        NSArray *untrackedInsertedFractalInfos = [insertedFractalInfos objectsAtIndexes: indexesOfUntrackedInsertedFractalInfos];
        
        [self.delegate documentControllerWillChangeContent:self];
        
        // Remove all of the removed documents. We need to send the delegate the removed indexes before
        // the documentInfos array is mutated to reflect the new changes. To do that, we'll build up the
        // array of removed indexes *before* we mutate it.
        if (trackedRemovedFractalInfos && trackedRemovedFractalInfos.count > 0) {
            NSMutableArray *indexesOfTrackedremovedFractalInfosInFractalInfos = [NSMutableArray arrayWithCapacity:trackedRemovedFractalInfos.count];
            for (MDBFractalInfo *trackedremovedFractalInfo in trackedRemovedFractalInfos)
            {
                NSInteger indexOfTrackedremovedFractalInfoInFractalInfos = [self.fractalInfos indexOfObject: trackedremovedFractalInfo];
                
                [indexesOfTrackedremovedFractalInfosInFractalInfos addObject: [NSIndexPath indexPathForRow: indexOfTrackedremovedFractalInfoInFractalInfos inSection: 0]];
            }
            
            [trackedRemovedFractalInfos enumerateObjectsUsingBlock:^(MDBFractalInfo *removedFractalInfo, NSUInteger idx, BOOL *stop) {
                [self.fractalInfos removeObject: removedFractalInfo];
            }];
            [self.delegate documentController: self didRemoveFractalInfosAtIndexPaths: indexesOfTrackedremovedFractalInfosInFractalInfos totalRows: self.count];
        }
        
        // Add the new documents.
        if (untrackedInsertedFractalInfos && untrackedInsertedFractalInfos.count > 0) {
            NSInteger preInsertCount = self.fractalInfos.count;
            [self.fractalInfos addObjectsFromArray: untrackedInsertedFractalInfos];
            
            // Now sort the document after all the inserts.
            if (self.sortComparator)
            {
                [self.fractalInfos sortUsingComparator: self.sortComparator];
            }
            
            NSMutableArray* insertedIndexPaths = [NSMutableArray arrayWithCapacity: untrackedInsertedFractalInfos.count];
            for (MDBFractalInfo *untrackedInsertedFractalInfo in untrackedInsertedFractalInfos)
            {
                [insertedIndexPaths addObject: [NSIndexPath indexPathForRow: [self.fractalInfos indexOfObject: untrackedInsertedFractalInfo] inSection: 0]];
            }
            [self.delegate documentController: self didInsertFractalInfosAtIndexPaths: insertedIndexPaths totalRows: self.count];
        }
        
        // Update the old documents.
        if (updatedFractalInfos && updatedFractalInfos.count > 0) {
            NSMutableArray* updatedIndexPaths = [NSMutableArray arrayWithCapacity: updatedFractalInfos.count];
            for (MDBFractalInfo *updatedFractalInfo in updatedFractalInfos) {
                NSInteger updatedIndex = [self.fractalInfos indexOfObject: updatedFractalInfo];
                [updatedIndexPaths addObject: [NSIndexPath indexPathForRow: updatedIndex inSection: 0]];
                
                NSAssert(updatedIndex != NSNotFound, @"An updated fractal info should always already be tracked in the fractal infos.");
                
                self.fractalInfos[updatedIndex] = updatedFractalInfo;
            }
            [self.delegate documentController: self didUpdateFractalInfosAtIndexPaths: updatedIndexPaths totalRows: self.count];
        }
        
        [self.delegate documentControllerDidChangeContent:self];
    });
}

-(void)resortFractalInfos
{
    if (self.sortComparator)
    {
        dispatch_async(self.fractalReadQueue, ^{
            [self.fractalInfos sortUsingComparator: self.sortComparator];
        });
    }
}
#pragma mark - Convenience

- (NSArray *)fractalInfosByMappingURLs:(NSArray *)URLs {
    NSMutableArray *fractalInfos = [NSMutableArray arrayWithCapacity:URLs.count];
    
    for (NSURL *URL in URLs) {
        MDBFractalInfo *fractalInfo = [[MDBFractalInfo alloc] initWithURL:URL];
        
        [fractalInfos addObject:fractalInfo];
    }
    
    return fractalInfos;
}

@end
