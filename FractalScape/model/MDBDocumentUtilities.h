//
//  MDBDocumentUtilities.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/03/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LSFractal;
@class MDBFractalDocument;

@interface MDBDocumentUtilities : NSObject

+ (NSURL *)localDocumentsDirectory;

+ (void)copyInitialDocuments;

+ (void)migrateLocalDocumentsToCloud;

+ (void)readDocumentAtURL:(NSURL *)url withCompletionHandler:(void (^)(MDBFractalDocument *document, NSError *error))completionHandler;

+ (void)createDocumentWithFractal:(LSFractal *)fractal atURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler;

+ (void)removeFractalAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler;

@end
