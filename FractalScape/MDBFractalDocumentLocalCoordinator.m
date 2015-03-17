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
@property (nonatomic, strong) NSPredicate *predicate;
@end


@implementation MDBFractalDocumentLocalCoordinator

@synthesize delegate = _delegate;

#pragma mark - Initializers

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
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Fetch the list documents from container documents directory.
        NSArray *localDocumentURLs = [fileManager contentsOfDirectoryAtURL:[MDBDocumentUtilities localDocumentsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsPackageDescendants error:nil];
        
        NSArray *localFractalDocumentURLs = [localDocumentURLs filteredArrayUsingPredicate:self.predicate];
        
        if (localFractalDocumentURLs.count > 0) {
            [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs: localFractalDocumentURLs removedURLs:@[] updatedURLs:@[]];
        }
    });
}

- (void)stopQuery {
    // Nothing to do here since the documents are local and everything gets funnelled this class
    // if the storage is local.
}

- (void)removeFractalAtURL:(NSURL *)URL {
    [MDBDocumentUtilities removeFractalAtURL:URL withCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate documentCoordinatorDidFailRemovingDocumentAtURL:URL withError:error];
        }
        else {
            [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs:@[] removedURLs:@[URL] updatedURLs:@[]];
        }
    }];
}

- (void)createURLForFractal:(LSFractal *)fractal withIdentifier:(NSString *)name
{
    NSURL *documentURL = [self documentURLForName: name];
    
    [MDBDocumentUtilities createDocumentWithFractal: fractal atURL: documentURL withCompletionHandler:^(NSError *error) {
        if (error)
        {
            [self.delegate documentCoordinatorDidFailCreatingDocumentAtURL: documentURL withError:error];
        }
        else {
            [self.delegate documentCoordinatorDidUpdateContentsWithInsertedURLs:@[documentURL] removedURLs:@[] updatedURLs:@[]];
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
