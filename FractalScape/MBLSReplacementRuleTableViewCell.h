//
//  MBLSReplacementRuleTableViewCell.h
//  FractalScape
//
//  Created by Taun Chapman on 10/01/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBXibAutolayoutTableCell.h"
#import <MDUiKit/MDUiKit.h>

@interface MBLSReplacementRuleTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (weak, nonatomic) IBOutlet MDKUICollectionViewScrollContentSized *rightCollectionView;

@end
