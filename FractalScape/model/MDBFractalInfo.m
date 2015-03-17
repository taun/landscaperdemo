//
//  MDBFractalInfo.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/04/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalInfo.h"
#import "MDBDocumentUtilities.h"

@interface MDBFractalInfo ()

@property(nonatomic,copy,readwrite) NSString                *name;
@property(nonatomic,copy,readwrite) NSString                *descriptor;
@property(nonatomic,strong,readwrite) MDBFractalCategory    *category;
@property(nonatomic,strong,readwrite) UIImage            *thumbnail;
@property (nonatomic, strong) dispatch_queue_t              fetchQueue;

@end

@implementation MDBFractalInfo

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    
    if (self) {
        
        _fetchQueue = dispatch_queue_create("com.moedae.FractalScapes.info", DISPATCH_QUEUE_SERIAL);
        _URL = URL;
    }
    
    return self;
}

#pragma mark - Property Overrides

- (NSString *)identifier {
    NSString *identifier = self.URL.lastPathComponent;
    
    return identifier.stringByDeletingPathExtension;
}

- (void)fetchInfoWithCompletionHandler:(void (^)(void))completionHandler {
    dispatch_async(self.fetchQueue, ^{
        // If the descriptor has been set, the info has been fetched.
        if (self.name) {
            completionHandler();
            
            return;
        }
        
        [MDBDocumentUtilities readDocumentAtURL: self.URL withCompletionHandler:^(MDBFractalDocument *document, NSError *error) {
            dispatch_async(self.fetchQueue, ^{
                if (document) {
                    NSError* thumbnailError;
                    
                    self.name = document.fractal.name;
                    self.descriptor = document.fractal.descriptor;
                    self.category = document.fractal.category;
                    UIImage* thumbnail;
                    BOOL haveThumbnail = [self.URL getPromisedItemResourceValue: &thumbnail forKey: NSThumbnail1024x1024SizeKey error: &thumbnailError];
                    if (haveThumbnail && thumbnail)
                    {
                        self.thumbnail = [thumbnail copy];
                    }
                }
                else {
                    // what to do here? if no document why would there be info?
                }
                
                completionHandler();
            });
        }];
    });
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[MDBFractalInfo class]]) {
        return NO;
    }
    
    return [self.URL isEqual:[object URL]];
}


@end
