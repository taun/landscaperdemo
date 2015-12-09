//
//  MDBFractalDocumentLocalCoordinator.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalDocumentLocalCoordinator.h"
#import "MDBCloudManager.h"
#import "MDBDocumentUtilities.h"
#import "MDBURLPlusMetaData.h"

@interface MDBFractalDocumentLocalCoordinator ()
@property (nonatomic, strong) NSPredicate       *predicate;
@property (nonatomic, strong) NSSet             *insertedFiles;
@property (nonatomic, strong) NSSortDescriptor  *urlArraySortDescriptor;
@property (nonatomic, strong) dispatch_queue_t  queryQueue;
@end


@implementation MDBFractalDocumentLocalCoordinator

@synthesize delegate = _delegate;

#pragma mark - Initializers

-(instancetype)copyWithZone:(NSZone *)zone
{
    MDBFractalDocumentLocalCoordinator* newCoord = [[[self class]alloc]initWithPredicate: self.predicate];
    return newCoord;
}

- (instancetype)initWithPredicate:(NSPredicate *)predicate {
    self = [super init];
    
    if (self) {
        _predicate = predicate;
        _queryQueue = dispatch_queue_create("com.moedae.FractalScapes.localDocumentCoordinator", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (instancetype)initWithPathExtension:(NSString *)pathExtension {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(pathExtension = %@)", pathExtension];
    
    self = [self initWithPredicate:predicate];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(lastPathComponent = %@)", lastPathComponent];
    
    self = [self initWithPredicate:predicate];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

//-(NSMutableSet*)insertedFiles
//{
//    if (!_insertedFiles) {
//        _insertedFiles = [NSMutableSet new];
//    }
//    return _insertedFiles;
//}

-(NSSortDescriptor*)urlArraySortDescriptor
{
    if (!_urlArraySortDescriptor) {
        _urlArraySortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"lastPathComponent" ascending: YES];
    }
    return _urlArraySortDescriptor;
}


#pragma mark - MDBFractalDocumentCoordinator

- (void)startQuery {
    
    dispatch_async(self.queryQueue, ^{
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Fetch the list documents from container documents directory.
        NSArray *localDocumentURLs = [fileManager contentsOfDirectoryAtURL:[MDBDocumentUtilities localDocumentsDirectory] includingPropertiesForKeys: @[NSURLContentModificationDateKey] options:NSDirectoryEnumerationSkipsPackageDescendants error:nil];
        
        NSArray *localFractalDocumentURLs = [localDocumentURLs filteredArrayUsingPredicate: self.predicate];
        
        NSSet* currentFractalDocumentsSet = [NSSet setWithArray: localFractalDocumentURLs];
        
        // if missing from inserted, needs to be inserted
        // inserts are currentList minus already inserted
        NSMutableSet* newInserts = [currentFractalDocumentsSet mutableCopy];
        [newInserts  minusSet: self.insertedFiles];
        
        // if in inserted, needs to be updated
        // updates are intersection of currentList and already inserted
        NSMutableSet* updates = [currentFractalDocumentsSet mutableCopy];
        [updates intersectSet: self.insertedFiles];
        
        // removed is already inserted minus current
        NSMutableSet* removed = [self.insertedFiles mutableCopy];
        [removed minusSet: currentFractalDocumentsSet];
        
        self.insertedFiles = currentFractalDocumentsSet;
        
        if (newInserts.count > 0 || updates.count > 0 || removed.count > 0) {
            NSArray* insertedURLsArray = [newInserts sortedArrayUsingDescriptors: @[self.urlArraySortDescriptor]];
            NSArray* updatedURLsArray = [updates sortedArrayUsingDescriptors: @[self.urlArraySortDescriptor]];
            NSArray* removedURLsArray = [removed sortedArrayUsingDescriptors: @[self.urlArraySortDescriptor]];
            [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs: [MDBURLPlusMetaData newArrayFromURLArray: insertedURLsArray]
                                                                    removedURLs: [MDBURLPlusMetaData newArrayFromURLArray: removedURLsArray]
                                                                    updatedURLs: [MDBURLPlusMetaData newArrayFromURLArray: updatedURLsArray]];
        }
    });
}

- (void)stopQuery {
    // Nothing to do here since the documents are local and everything gets funnelled this class
    // if the storage is local.
}

- (void)removeFractalAtURL:(NSURL *)URL {
    [MDBDocumentUtilities removeDocumentAtURL:URL withCompletionHandler:^(NSError *error) {
        
        id<MDBFractalDocumentCoordinatorDelegate> strongDelegate = self.delegate;
        
        if (error) {
            [strongDelegate documentCoordinatorDidFailRemovingDocumentAtURL:URL withError:error];
        }
        else {
            [strongDelegate documentCoordinatorDidUpdateContentsWithInsertedURLs:@[] removedURLs:@[URL] updatedURLs:@[]];
        }
    }];
}

- (BOOL)canCreateFractalWithIdentifier:(NSString *)name {
    if (name.length <= 0) {
        return NO;
    }
    
    NSURL *documentURL = [self documentURLForName:name];
    
    return ![[NSFileManager defaultManager] fileExistsAtPath:documentURL.path];
}

#pragma mark - Convenience

- (NSURL *)documentURLForName:(NSString *)name {
    NSURL *documentURLWithoutExtension = [[MDBDocumentUtilities localDocumentsDirectory] URLByAppendingPathComponent:name];
    NSURL *documentWithExtension = [documentURLWithoutExtension URLByAppendingPathExtension: kMDBFractalDocumentFileExtension];
    return documentWithExtension;
}

@end
