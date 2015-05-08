//
//  MDBDocumentUtilities.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/03/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBDocumentUtilities.h"
#import "MDBFractalDocument.h"
#import "LSFractal.h"
#import "MDBCloudManager.h"

@implementation MDBDocumentUtilities


+ (NSURL *)localDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
}

+ (void)copyInitialDocuments
{
    NSArray *defaultListURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension: kMDBFractalDocumentFileExtension subdirectory:@""];
    
    [self copyURLToDocumentsDirectory: defaultListURLs];
}

+(void)waitUntilDoneCopying
{
    [[self queue] waitUntilAllOperationsAreFinished];
}

+ (void)migrateLocalDocumentsToCloud {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Note the call to -URLForUbiquityContainerIdentifier: should be on a background queue.
        NSURL *cloudDirectoryURL = [fileManager URLForUbiquityContainerIdentifier:nil];
        
        NSURL *documentsDirectoryURL = [cloudDirectoryURL URLByAppendingPathComponent:@"Documents"];
        
        NSArray *localDocumentURLs = [fileManager contentsOfDirectoryAtURL:[self localDocumentsDirectory] includingPropertiesForKeys:nil options:0 error:nil];
        
        for (NSURL *URL in localDocumentURLs) {
            if ([URL.pathExtension isEqualToString: kMDBFractalDocumentFileExtension]) {
                [self makeItemUbiquitousAtURL:URL documentsDirectoryURL:documentsDirectoryURL];
            }
        }
    });
}

+ (void)makeItemUbiquitousAtURL:(NSURL *)sourceURL documentsDirectoryURL:(NSURL *)documentsDirectoryURL {
    NSString *destinationFileName = sourceURL.lastPathComponent;
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *destinationURL = [documentsDirectoryURL URLByAppendingPathComponent:destinationFileName];
    
    if ([fileManager fileExistsAtPath:destinationURL.path]) {
        return;
    }
    
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(defaultQueue, ^{
        [fileManager setUbiquitous:YES itemAtURL:sourceURL destinationURL:destinationURL error:nil];
    });
}

+ (void)readDocumentAtURL:(NSURL *)url withCompletionHandler:(void (^)(MDBFractalDocument *document, NSError *error))completionHandler {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    // `url` may be a security scoped resource.
    BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];
    
    NSFileAccessIntent *readingIntent = [NSFileAccessIntent readingIntentWithURL:url options:NSFileCoordinatorReadingWithoutChanges];
    [fileCoordinator coordinateAccessWithIntents:@[readingIntent] queue:[self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            if (successfulSecurityScopedResourceAccess) {
                [url stopAccessingSecurityScopedResource];
            }
            
            if (completionHandler) {
                completionHandler(nil, accessError);
            }
            
            return;
        }
        
        // Local variables that will be used as parameters to `completionHandler`.
        MDBFractalDocument *deserializedDocument = [[MDBFractalDocument alloc] initWithFileURL: readingIntent.URL];
        
        if (deserializedDocument.documentState & UIDocumentStateClosed)
        {
            [deserializedDocument openWithCompletionHandler:^(BOOL success) {
                if (successfulSecurityScopedResourceAccess)
                {
                    [url stopAccessingSecurityScopedResource];
                }
                if (completionHandler)
                {
                    NSError* docError;
                    
                    if (!success)
                    {
                        docError = [NSError errorWithDomain: @"FractalScape" code: deserializedDocument.loadResult userInfo: nil];
                    }
                    completionHandler(deserializedDocument, docError);
                }
            }];
        }
        
    }];
}

+ (void)createDocumentWithFractal:(LSFractal *)fractal atURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *))completionHandler {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    NSFileAccessIntent *writingIntent = [NSFileAccessIntent writingIntentWithURL:url options:NSFileCoordinatorWritingForReplacing];
    [fileCoordinator coordinateAccessWithIntents:@[writingIntent] queue:[self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            if (completionHandler) {
                completionHandler(accessError);
            }
            
            return;
        }
        
        MDBFractalDocument* newDocument = [[MDBFractalDocument alloc]initWithFileURL: writingIntent.URL];
        newDocument.fractal = fractal;
        
        [newDocument saveToURL: newDocument.fileURL forSaveOperation: UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            //
            if (completionHandler)
            {
                completionHandler(nil);
            }
        }];
        
        
    }];
}

+ (void)removeDocumentAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    // `url` may be a security scoped resource.
    BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];
    
    NSFileAccessIntent *writingIntent = [NSFileAccessIntent writingIntentWithURL:url options:NSFileCoordinatorWritingForDeleting];
    [fileCoordinator coordinateAccessWithIntents:@[writingIntent] queue:[self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            if (completionHandler) {
                completionHandler(accessError);
            }
            
            return;
        }
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        NSError *error;
        
        [fileManager removeItemAtURL:writingIntent.URL error:&error];
        
        if (successfulSecurityScopedResourceAccess) {
            [url stopAccessingSecurityScopedResource];
        }
        
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

#pragma mark - Convenience

+ (void)copyURLToDocumentsDirectory:(NSArray *)urls {
    
    NSMutableArray* toURLS = [NSMutableArray arrayWithCapacity: urls.count];
    
    for (NSURL* url in urls)
    {
        NSURL *toURL = [[MDBDocumentUtilities localDocumentsDirectory] URLByAppendingPathComponent: url.lastPathComponent];
        
        // If the file already exists, don't attempt to copy the version from the bundle.
        if (![[NSFileManager defaultManager] fileExistsAtPath: toURL.path])
        {
            [toURLS addObject: @[url ,toURL]];;
        }
    }
    
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    __block NSError *error;
    
    BOOL successfulSecurityScopedResourceAccess = [[MDBDocumentUtilities localDocumentsDirectory] startAccessingSecurityScopedResource];
    
    NSMutableArray* intents = [NSMutableArray arrayWithCapacity: toURLS.count*2];
    
    for (NSArray* urlToURL in toURLS)
    {
        NSFileAccessIntent *movingIntent = [NSFileAccessIntent writingIntentWithURL: urlToURL[0] options:NSFileCoordinatorWritingForMoving];
        NSFileAccessIntent *replacingIntent = [NSFileAccessIntent writingIntentWithURL: urlToURL[1] options:NSFileCoordinatorWritingForReplacing];
        [intents addObject: movingIntent];
        [intents addObject: replacingIntent];
    }

    [fileCoordinator coordinateAccessWithIntents: intents queue:[self queue] byAccessor:^(NSError *accessError) {
        if (accessError) {
            // An error occured when trying to coordinate moving URL to toURL. In your app, handle this gracefully.
            NSLog(@"Couldn't move files: %@ error: %@.", toURLS, accessError.localizedDescription);
            
            return;
        }
        
        BOOL success = NO;
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        for (int i = 0; i < intents.count; i+=2) {
            NSFileAccessIntent* moveIntent = (NSFileAccessIntent*)intents[i];
            NSFileAccessIntent* replaceIntent = (NSFileAccessIntent*)intents[i+1];
            
            success = [fileManager copyItemAtURL: moveIntent.URL toURL: replaceIntent.URL error: &error];
            
            if (success)
            {
                NSDictionary *fileAttributes = @{ NSFileExtensionHidden: @YES };
                
                [fileManager setAttributes:fileAttributes ofItemAtPath: replaceIntent.URL.path error:nil];
            }
        }
        
        
        if (successfulSecurityScopedResourceAccess)
        {
            [[MDBDocumentUtilities localDocumentsDirectory] stopAccessingSecurityScopedResource];
        }
        
        if (!success) {
            // An error occured when moving URL to toURL. In your app, handle this gracefully.
            NSLog(@"Couldn't move files: %@.", intents);
        }
    }];
}

/*!
An internal queue to the MDBDocumentUtilities class that is used for NSFileCoordinator callbacks.
 */
+ (NSOperationQueue *)queue {
    static NSOperationQueue *queue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
}

@end
