//
//  MDBFractalDocument.h
//  FractalScapes
//
//  Created by Taun Chapman on 02/21/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;
@import CloudKit;

@class LSFractal;
@class LSDrawingRuleType;
@class MDBFractalDocument;

extern NSString* const kMDBVersionFileName;
extern NSString* const kMDBThumbnailFileName;
extern NSString* const kMDBFractalFileName;

extern NSString * const CKFractalRecordType;
extern NSString * const CKFractalRecordNameField;
extern NSString * const CKFractalRecordNameInsensitiveField;
extern NSString * const CKFractalRecordDescriptorField;
extern NSString * const CKFractalRecordFractalDefinitionAssetField;
extern NSString * const CKFractalRecordFractalThumbnailAssetField;

extern NSString * const CKFractalRecordSubscriptionIDkey;

typedef NS_ENUM(NSUInteger, MDBFractalDocumentLoadResult)
{
    MDBFractalDocumentLoad_SUCCESS,
    MDBFractalDocumentLoad_ZERO_LENGTH_FILE,
    MDBFractalDocumentLoad_CORRUPT_FILE,
    MDBFractalDocumentLoad_UNEXPECTED_VERSION,
    MDBFractalDocumentLoad_NO_SUCH_FILE
};

/*!
 * Protocol that allows a list document to notify other objects of it being deleted.
 */
@protocol MDBFractalDocumentDelegate <NSObject>

- (void)fractalDocumentWasDeleted:(MDBFractalDocument *)document;

@end

@protocol MDBFractaDocumentProtocol <NSObject>

@property(atomic,strong) LSFractal                       *fractal;
@property(nonatomic,strong) UIImage                         *thumbnail;
@property(nonatomic,readonly) MDBFractalDocumentLoadResult  loadResult;
@property(nonatomic,readonly) NSString                      *loadResultString;
@property(nonatomic,readonly) NSURL                         *fileURL;

@end

/*!
 A document for storing fractals.
 */
@interface MDBFractalDocument : UIDocument <MDBFractaDocumentProtocol>

+(NSInteger)    version;
/*!
 An LSFractal
 */
@property(atomic,strong) LSFractal                       *fractal;
@property(nonatomic,strong) UIImage                         *thumbnail;
@property(nonatomic,strong) NSArray                         *categories;
@property(nonatomic,readonly) MDBFractalDocumentLoadResult  loadResult;
@property(nonatomic,readonly) NSString                      *loadResultString;

@property (weak) id<MDBFractalDocumentDelegate>             delegate;

-(CKRecord*) asCloudKitRecord;

@end
