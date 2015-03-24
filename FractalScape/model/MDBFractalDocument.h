//
//  MDBFractalDocument.h
//  FractalScapes
//
//  Created by Taun Chapman on 02/21/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

@class LSFractal;
@class LSDrawingRuleType;
@class MDBFractalDocument;

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

/*!
 A document for storing fractals.
 */
@interface MDBFractalDocument : UIDocument

+(NSInteger)    version;
/*!
 An LSFractal
 */
@property(nonatomic,strong) LSFractal                       *fractal;
@property(nonatomic,strong) UIImage                         *thumbnail;
@property(nonatomic,strong) LSDrawingRuleType               *sourceDrawingRules;
@property(nonatomic,strong) NSArray                         *sourceColorCategories;
@property(nonatomic,strong) NSArray                         *categories;
@property(nonatomic,readonly) MDBFractalDocumentLoadResult  loadResult;

@property (weak) id<MDBFractalDocumentDelegate>             delegate;

@end
