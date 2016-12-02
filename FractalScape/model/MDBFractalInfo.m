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
#import "MDBURLPlusMetaData.h"


@interface MDBFractalInfo ()
@property(nonatomic,strong,readwrite) id<MDBFractaDocumentProtocol>         document;
@property (nonatomic,strong) dispatch_queue_t                               fetchQueue;

@property(nonatomic,assign,readwrite) BOOL                                  isCurrent;
@property(nonatomic,assign,readwrite) BOOL                                  isDownloading;
@property(nonatomic,assign,readwrite) double                                downloadingProgress;
@property(nonatomic,assign,readwrite) BOOL                                  isUploading;
@property(nonatomic,assign,readwrite) double                                uploadingProgress;

@end

@implementation MDBFractalInfo



+ (instancetype)newFractalInfoWithURLPlusMeta: (MDBURLPlusMetaData*)urlPlusMeta forFractal:(LSFractal *)fractal image: (UIImage*)image documentDelegate: (id)delegate
{
    MDBFractalInfo* newInfo = [[[self class]alloc] initWithURLPlusMeta: urlPlusMeta];
    MDBFractalDocument* newDocument = [[MDBFractalDocument alloc] initWithFileURL: urlPlusMeta.fileURL];
    newDocument.fractal = fractal;
    newDocument.thumbnail = image;
    [newDocument updateChangeCount: UIDocumentChangeDone];
    newDocument.delegate = delegate;
    newInfo.document = newDocument;
    newInfo.changeDate = [NSDate date];
    
    return newInfo;
}

- (instancetype)initWithURLPlusMeta:(MDBURLPlusMetaData *)urlPlusMeta {
    self = [super init];
    
    if (self)
    {
        _fetchQueue = dispatch_queue_create("com.moedae.FractalScapes.info", DISPATCH_QUEUE_SERIAL);
        _urlPlusMeta = urlPlusMeta;
        [self updateMetaDataValues];
    }
    
    return self;
}

-(void)updateMetaDataWith:(NSMetadataItem *)meta
{
    if (meta)
    {
        _urlPlusMeta.metaDataItem = meta;
        [self updateMetaDataValues];
    }
}

-(void)updateMetaDataValues
{
        NSMetadataItem* meta = _urlPlusMeta.metaDataItem;
        
        if (meta)
        {
            NSString *downloadStatus = [meta valueForAttribute: NSMetadataUbiquitousItemDownloadingStatusKey];
            _isCurrent = [downloadStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusCurrent];
            _isDownloading = [[meta valueForAttribute: NSMetadataUbiquitousItemIsDownloadingKey] boolValue];
            _downloadingProgress = [[meta valueForAttribute: NSMetadataUbiquitousItemPercentDownloadedKey] doubleValue];
            _isUploading = [[meta valueForAttribute: NSMetadataUbiquitousItemIsUploadingKey] boolValue];
            _uploadingProgress = [[meta valueForAttribute: NSMetadataUbiquitousItemPercentUploadedKey] doubleValue];
        }
    [self updateChangeDate];
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
    [_urlPlusMeta.fileURL getResourceValue: &modDate forKey: NSURLContentModificationDateKey error: &error];
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
    NSString *identifier = self.urlPlusMeta.fileURL.lastPathComponent;
    
    return identifier.stringByDeletingPathExtension;
}

-(void)setProxyDocument:(id<MDBFractaDocumentProtocol>)proxy
{
    _document = proxy;
}

-(void)closeDocument
{
    if (_document.documentState != UIDocumentStateClosed)
    {
        [_document closeWithCompletionHandler: nil];
    }
    _document = nil;
}

-(void) dealloc
{
    [self closeDocument];
}

- (void)fetchDocumentWithCompletionHandler:(void (^)(void))completionHandler {
    dispatch_async(self.fetchQueue, ^{
        // If the descriptor has been set, the info has been fetched.
        if (self.document) {
            completionHandler();
            
            return;
        }
        
        [MDBDocumentUtilities readDocumentAtURL: self.urlPlusMeta.fileURL withCompletionHandler:^(MDBFractalDocument *document, NSError *error) {
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
    NSURL* myURL = [[self.urlPlusMeta.fileURL absoluteString]hasSuffix: @"/"] ? self.urlPlusMeta.fileURL : [self.urlPlusMeta.fileURL URLByAppendingPathComponent: @"/"];
    NSURL* otherURL = [[[[object urlPlusMeta]fileURL] absoluteString]hasSuffix: @"/"] ? [[object urlPlusMeta]fileURL] : [[[object urlPlusMeta]fileURL] URLByAppendingPathComponent: @"/"];

    return [myURL isEqual: otherURL];
}


@end
