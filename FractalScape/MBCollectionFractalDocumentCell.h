//
//  FractalScape
//
//  Created by Taun Chapman on 02/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "MDBFractalDocument.h"

@class MDCCloudTransferStatusIndicator;
@class MDBFractalInfo;

@interface MBCollectionFractalDocumentCell : UICollectionViewCell

@property (assign,nonatomic) CGFloat   radius;
//@property (strong, nonatomic) id<MDBFractaDocumentProtocol>          document;
@property (strong, nonatomic) MDBFractalInfo                        *info;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView        *activityIndicator;
@property (weak, nonatomic) IBOutlet MDCCloudTransferStatusIndicator*transferIndicator;
@property (strong,nonatomic) IBInspectable UIColor                  *selectedBorder;
@property (assign,nonatomic) IBInspectable CGFloat                  selectedBorderWidth;

-(void)purgeImage;
-(void)updateProgessIndicatorForURL: (NSURL*)docURL;

@end
