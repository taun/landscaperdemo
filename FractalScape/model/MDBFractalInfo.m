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

-(NSString *)debugDescription
{
    NSString* desc = [NSString stringWithFormat: @"%@ ChangeDate:%@ Identifier:%@",self.description, _changeDate, self.identifier];
    return desc;
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

-(void) dealloc
{
    if (_document.documentState != UIDocumentStateClosed) {
        [_document closeWithCompletionHandler: nil];
    }
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
                if (document && !error) {
                    self->_document = document;
                }
                else {
                    // what to do here? if no document why would there be info?
                    self->_document = document;
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
    NSURL* myURL = [[self.URL absoluteString]hasSuffix: @"/"] ? self.URL : [self.URL URLByAppendingPathComponent: @"/"];
    NSURL* otherURL = [[[object URL] absoluteString]hasSuffix: @"/"] ? [object URL] : [[object URL] URLByAppendingPathComponent: @"/"];

    return [myURL isEqual: otherURL];
}


@end
