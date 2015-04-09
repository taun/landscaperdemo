//
//  MDBFractalInfo.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/04/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalInfo.h"
#import "MDBDocumentUtilities.h"
#import "MDBFractalDocument.h"

@interface MDBFractalInfo ()
@property(nonatomic,strong,readwrite) MDBFractalDocument    *document;
@property (nonatomic,strong) dispatch_queue_t              fetchQueue;
@end

@implementation MDBFractalInfo

+ (instancetype)newFractalInfoWithURL: (NSURL*)url forFractal:(LSFractal *)fractal documentDelegate: (id)delegate
{
    MDBFractalInfo* newInfo = [[[self class]alloc] initWithURL: url];
    MDBFractalDocument* newDocument = [[MDBFractalDocument alloc] initWithFileURL: newInfo.URL];
    newDocument.fractal = fractal;
    newDocument.delegate = delegate;
    newInfo.document = newDocument;
        
    return newInfo;
}

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    
    if (self)
    {
        _fetchQueue = dispatch_queue_create("com.moedae.FractalScapes.info", DISPATCH_QUEUE_SERIAL);
        _URL = URL;
        [self updateChangeDate];
    }
    
    return self;
}

-(void)updateChangeDate
{
    NSError* error;
    NSDate* modDate;
    [_URL getResourceValue: &modDate forKey: NSURLContentModificationDateKey error: &error];
    if (modDate && !error)
    {
        _changeDate = modDate;
    } else if (error)
    {
        _changeDate = [NSDate date];
        //            NSLog(@"%@, %@ Warning: %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),error);
    }
}

#pragma mark - Property Overrides

- (NSString *)identifier {
    NSString *identifier = self.URL.lastPathComponent;
    
    return identifier.stringByDeletingPathExtension;
}

-(void) unCacheDocument
{
    _document = nil;
}

- (void)fetchDocumentWithCompletionHandler:(void (^)(void))completionHandler {
    dispatch_async(self.fetchQueue, ^{
        // If the descriptor has been set, the info has been fetched.
        if (self.document) {
            completionHandler();
            
            return;
        }
        
        [MDBDocumentUtilities readDocumentAtURL: self.URL withCompletionHandler:^(MDBFractalDocument *document, NSError *error) {
            dispatch_async(self.fetchQueue, ^{
                if (document) {
                    self->_document = document;
                }
                else {
                    // what to do here? if no document why would there be info?
                    self->_document = nil;
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
    
    return [self.URL isEqual: [object URL]];
}


@end
