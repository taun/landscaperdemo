//
//  FractalScape
//
//  Created by Taun Chapman on 02/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

@class MDBFractalDocument;

@interface MBCollectionFractalDocumentCell : UICollectionViewCell

@property (assign,nonatomic) CGFloat   radius;
@property (weak, nonatomic) MDBFractalDocument          *document;

@end
