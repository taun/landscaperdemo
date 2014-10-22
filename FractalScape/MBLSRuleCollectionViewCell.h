//
//  MBLSRuleCollectionViewCell.h
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSDrawingRule+addons.h"
#import "MBLSRuleDragAndDropProtocol.h"

@interface MBLSRuleCollectionViewCell : UICollectionViewCell <MBLSRuleDragAndDropProtocol>

@property (weak,nonatomic) LSDrawingRule            *rule;

@property (weak,nonatomic) IBOutlet UIImageView     *customImageView;

@end
