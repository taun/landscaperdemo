//
//  MBCollectionFractalCell.h
//  FractalScape
//
//  Created by Taun Chapman on 02/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

@class MDBFractalInfo;

@interface MBCollectionFractalCell : UICollectionViewCell

@property (assign,nonatomic) CGFloat   radius;
@property (weak, nonatomic) MDBFractalInfo          *fractalInfo;

@end
