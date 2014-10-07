//
//  MBLSRuleCollectionTableViewCell.h
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBXibAutolayoutTableCell.h"
#import <MDUiKit/MDUiKit.h>

@interface MBLSRuleCollectionTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet MDKUICollectionViewScrollContentSized *collectionView;

@end
