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

@interface MDBFractalDocumentLocalCoordinator ()
@property (nonatomic, strong) NSPredicate       *predicate;
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

#pragma mark - MDBFractalDocumentCoordinator

- (void)startQuery {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0ul);
    
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Fetch the list documents from container documents directory.
        NSArray *localDocumentURLs = [fileManager contentsOfDirectoryAtURL:[MDBDocumentUtilities localDocumentsDirectory] includingPropertiesForKeys: @[NSURLContentModificationDateKey] options:NSDirectoryEnumerationSkipsPackageDescendants error:nil];
        
        NSArray *localFractalDocumentURLs = [localDocumentURLs filteredArrayUsingPredicate: self.predicate];
        
        if (localFractalDocumentURLs && localFractalDocumentURLs.count > 0) {
            [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs: localFractalDocumentURLs removedURLs:@[] updatedURLs:@[]];
        }
    });
}

- (void)stopQuery {
    // Nothing to do here since the documents are local and everything gets funnelled this class
    // if the storage is local.
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
    
    return [documentURLWithoutExtension URLByAppendingPathExtension: kMDBFractalDocumentFileExtension];
}

@end
