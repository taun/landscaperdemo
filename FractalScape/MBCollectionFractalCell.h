//
//  MBCollectionFractalCell.h
//  FractalScape
//
//  Created by Taun Chapman on 02/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSFractal+addons.h"

@interface MBCollectionFractalCell : UICollectionViewCell

@property (assign,nonatomic) CGFloat   radius;
@property (weak, nonatomic) LSFractal               *fractal;
@property (weak, nonatomic) IBOutlet UIView         *imageFrame;
@property (weak, nonatomic) IBOutlet UIImageView    *imageView;
@property (weak, nonatomic) IBOutlet UILabel        *textLabel;
@property (weak, nonatomic) IBOutlet UILabel        *detailTextLabel;

@end
