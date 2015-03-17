//
//  MDBDocumentController.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/03/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBDocumentController.h"
#import "MDBFractalDocumentCoordinator.h"
#import "MDBFractalInfo.h"

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
@property (nonatomic, strong) dispatch_queue_t fractalInfoQueue;

/*!
 * The sort comparator that's set in initialization. The sort predicate ensures a strict sort ordering
 * of the \c documentInfos array. If \c sortComparator is nil, the sort order is ignored.
 */
@property (nonatomic, copy) NSComparisonResult (^sortComparator)(MDBFractalInfo *lhs, MDBFractalInfo *rhs);


@end

@implementation MDBDocumentController
@synthesize documentCoordinator = _documentCoordinator;

#pragma mark - Initialization

- (instancetype)initWithDocumentCoordinator:(id<MDBFractalDocumentCoordinator>)documentCoordinator sortComparator:(NSComparisonResult (^)(MDBFractalInfo *, MDBFractalInfo *))sortComparator {
    self = [super init];
    
    if (self) {
        _documentCoordinator = documentCoordinator;
        _sortComparator = sortComparator;
        
        _fractalInfoQueue = dispatch_queue_create("com.moedae.FractalScapes.documentcontroller", DISPATCH_QUEUE_SERIAL);
        _fractalInfos = [NSMutableArray array];
        
        _documentCoordinator.delegate = self;
        
        [_documentCoordinator startQuery];
    }
    
    return self;
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
        dispatch_sync(self.fractalInfoQueue, ^{
            allURLs = [self.fractalInfos valueForKey:@"URL"];
        });
        [self processContentChangesWithInsertedURLs:@[] removedURLs:allURLs updatedURLs:@[]];
        
        _documentCoordinator.delegate = self;
        oldDocumentCoordinator.delegate = nil;
        
        [_documentCoordinator startQuery];
    }
}

#pragma mark - Subscripting

- (MDBFractalInfo *)objectAtIndexedSubscript:(NSInteger)index {
    // Fetch the appropriate document info protected by documentInfoQueue.
    __block MDBFractalInfo *fractalInfo = nil;
    
    dispatch_sync(self.fractalInfoQueue, ^{
        fractalInfo = self.fractalInfos[index];
    });
    
    return fractalInfo;
}

#pragma mark - Inserting / Removing / Managing / Updating MDBFractalDocumentInfo Objects

- (void)removeFractalInfo:(MDBFractalInfo *)fractalInfo
{
    [self.documentCoordinator removeFractalAtURL:fractalInfo.URL];
}

- (void)createFractalInfoForFractal:(LSFractal *)fractal withIdentifier: (NSString *)name
{
    [self.documentCoordinator createURLForFractal: fractal withIdentifier: name];
}

- (BOOL)canCreateFractalInfoWithIdentifier:(NSString *)name
{
    return [self.documentCoordinator canCreateFractalWithIdentifier:name];
}

- (void)setFractalInfoHasNewContents:(MDBFractalInfo *)fractalInfo
{
    dispatch_async(self.fractalInfoQueue, ^{
        // Remove the old document info and replace it with the new one.
        NSInteger indexOfFractalInfo = [self.fractalInfos indexOfObject: fractalInfo];
        self.fractalInfos[indexOfFractalInfo] = fractalInfo;
        
        [self.delegate documentControllerWillChangeContent:self];
        [self.delegate documentController:self didUpdateFractalInfo: fractalInfo atIndex:indexOfFractalInfo];
        [self.delegate documentControllerDidChangeContent:self];
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
    
    dispatch_async(self.fractalInfoQueue, ^{
        // Filter out all documents that are already included in the tracked documents.
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
        NSMutableArray *indexesOfTrackedremovedFractalInfosInFractalInfos = [NSMutableArray arrayWithCapacity:trackedRemovedFractalInfos.count];
        for (MDBFractalInfo *trackedremovedFractalInfo in trackedRemovedFractalInfos) {
            NSInteger indexOfTrackedremovedFractalInfoInFractalInfos = [self.fractalInfos indexOfObject:trackedremovedFractalInfo];
            
            [indexesOfTrackedremovedFractalInfosInFractalInfos addObject:@(indexOfTrackedremovedFractalInfoInFractalInfos)];
        }
        
        [trackedRemovedFractalInfos enumerateObjectsUsingBlock:^(MDBFractalInfo *removedFractalInfo, NSUInteger idx, BOOL *stop) {
            [self.fractalInfos removeObject:removedFractalInfo];
            
            NSNumber *indexOfTrackedremovedFractalInfoInFractalInfos = indexesOfTrackedremovedFractalInfosInFractalInfos[idx];
            
            [self.delegate documentController:self didremoveFractalInfo: removedFractalInfo atIndex: indexOfTrackedremovedFractalInfoInFractalInfos.integerValue];
        }];
        
        // Add the new documents.
        [self.fractalInfos addObjectsFromArray:untrackedInsertedFractalInfos];
        
        // Nor sort the document after all the inserts.
        if (self.sortComparator) {
            [self.fractalInfos sortUsingComparator:self.sortComparator];
        }
        
        for (MDBFractalInfo *untrackedInsertedFractalInfo in untrackedInsertedFractalInfos) {
            NSInteger insertedIndex = [self.fractalInfos indexOfObject:untrackedInsertedFractalInfo];
            
            [self.delegate documentController:self didInsertFractalInfo: untrackedInsertedFractalInfo atIndex:insertedIndex];
        }
        
        // Update the old documents.
        for (MDBFractalInfo *updatedFractalInfo in updatedFractalInfos) {
            NSInteger updatedIndex = [self.fractalInfos indexOfObject: updatedFractalInfo];
            
            NSAssert(updatedIndex != NSNotFound, @"An updated fractal info should always already be tracked in the fractal infos.");
            
            self.fractalInfos[updatedIndex] = updatedFractalInfo;
            [self.delegate documentController: self didUpdateFractalInfo: updatedFractalInfo atIndex: updatedIndex];
        }
        
        [self.delegate documentControllerDidChangeContent:self];
    });
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
