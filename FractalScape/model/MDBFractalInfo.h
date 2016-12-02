//
//  MDBFractalInfo.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/04/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;

#import "MDBFractalDocument.h"

@class LSFractal, MDBURLPlusMetaData;

@interface MDBFractalInfo : NSObject
/*!
 Identifier
 */
@property(nonatomic,copy,readonly) NSString                         *identifier;
/*!
 File url
 */
@property(nonatomic,strong,readonly) MDBURLPlusMetaData             *urlPlusMeta;
/*!
 The last change date, redundant?
 */
@property(nonatomic,strong) NSDate                                  *changeDate;
/*!
 A Fractal Document
 */
@property(nonatomic,strong,readonly) id<MDBFractaDocumentProtocol>  document;
/*!
 The version on this device is the current version. Only applicable for cloud
 
 Always returns yes for local.
 */
@property(nonatomic,readonly) BOOL                                  isCurrent;
/*!
 Always returns NO for local
 */
@property(nonatomic,readonly) BOOL                                  isDownloading;
/*!
 0 to 100%
 */
@property(nonatomic,readonly) double                                downloadingProgress;
/*!
 Always returns NO for local
 */
@property(nonatomic,readonly) BOOL                                  isUploading;
/*!
 0 to 100%
 */
@property(nonatomic,readonly) double                                uploadingProgress;

@property(nonatomic,assign) NSUInteger                              fileStatusChanged;


-(void)setProxyDocument: (id<MDBFractaDocumentProtocol>)proxy;

+ (instancetype)newFractalInfoWithURLPlusMeta: (MDBURLPlusMetaData*)urlPlusMeta forFractal: (LSFractal*)fractal image: (UIImage*)image documentDelegate: (id)delegate;
- (instancetype)initWithURLPlusMeta:(MDBURLPlusMetaData *)urlPlusMeta;
- (void) updateMetaDataWith: (NSMetadataItem*)meta;
- (void) fetchDocumentWithCompletionHandler:(void (^)(void))completionHandler;
- (void) closeDocument;
//- (void)unCacheDocument;

@end
