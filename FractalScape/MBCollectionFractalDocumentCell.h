//
//  FractalScape
//
//  Created by Taun Chapman on 02/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "MDBFractalDocument.h"

@interface MBCollectionFractalDocumentCell : UICollectionViewCell

@property (assign,nonatomic) CGFloat   radius;
@property (strong, nonatomic) id<MDBFractaDocumentProtocol>          document;

@end
