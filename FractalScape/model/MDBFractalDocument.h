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

extern NSString* _Nonnull const kMDBVersionFileName;
extern NSString* _Nonnull const kMDBThumbnailFileName;
extern NSString* _Nonnull const kMDBFractalFileName;

extern NSString* _Nonnull const CKFractalRecordType;
extern NSString* _Nonnull const CKFractalRecordNameField;
extern NSString* _Nonnull const CKFractalRecordNameInsensitiveField;
extern NSString* _Nonnull const CKFractalRecordDescriptorField;
extern NSString* _Nonnull const CKFractalRecordFractalDefinitionAssetField;
extern NSString* _Nonnull const CKFractalRecordFractalThumbnailAssetField;

extern NSString* _Nonnull const CKFractalRecordSubscriptionIDkey;

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

- (void)fractalDocumentWasDeleted:(MDBFractalDocument* _Nullable)document;

@end

@protocol MDBFractaDocumentProtocol <NSObject>

@property(atomic,strong,nullable) LSFractal                 *fractal;
@property(nonatomic,strong,nullable) UIImage                *thumbnail;
@property(nonatomic,readonly) MDBFractalDocumentLoadResult  loadResult;
@property(nonatomic,readonly,nullable) NSString             *loadResultString;
@property(nonatomic,readonly,nullable) NSURL                *fileURL;

@property (weak,nullable) id<MDBFractalDocumentDelegate>   delegate;

-(UIDocumentState)documentState;
- (void)openWithCompletionHandler:(void (^ __nullable)(BOOL success))completionHandler;
- (void)saveToURL:(NSURL *_Nullable)url forSaveOperation:(UIDocumentSaveOperation)saveOperation completionHandler:(void (^ _Nullable)(BOOL success))completionHandler __TVOS_PROHIBITED;- (void)closeWithCompletionHandler:(void (^ _Nullable)(BOOL success))completionHandler;
- (void)updateChangeCount:(UIDocumentChangeKind)change;

@end

/*!
 A document for storing fractals.
 */
@interface MDBFractalDocument : UIDocument <MDBFractaDocumentProtocol>

+(NSInteger)    version;
/*!
 An LSFractal
 */
@property(atomic,strong,nullable) LSFractal                          *fractal;
@property(nonatomic,strong,nullable) UIImage                         *thumbnail;
@property(nonatomic,strong,nullable) NSArray                         *categories;
@property(nonatomic,readonly) MDBFractalDocumentLoadResult  loadResult;
@property(nonatomic,readonly,nullable) NSString                      *loadResultString;

@property (weak,nullable) id<MDBFractalDocumentDelegate>             delegate;

-(CKRecord* _Nullable) asCloudKitRecord;

@end
