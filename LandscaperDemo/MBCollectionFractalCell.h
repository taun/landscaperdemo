//
//  MBCollectionFractalCell.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MBCollectionFractalCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView    *imageView;
@property (weak, nonatomic) IBOutlet UILabel        *textLabel;
@property (weak, nonatomic) IBOutlet UILabel        *detailTextLabel;

@end