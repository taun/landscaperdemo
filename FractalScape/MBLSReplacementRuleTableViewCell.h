//
//  MBLSReplacementRuleTableViewCell.h
//  FractalScape
//
//  Created by Taun Chapman on 10/01/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBXibAutolayoutTableCell.h"
#import "LSDrawingRule+addons.h"
#import "LSReplacementRule+addons.h"
#import "MBLSRuleDragAndDropProtocol.h"
#import "MBLSRuleBaseCollectionTableViewCell.h"

@interface MBLSReplacementRuleTableViewCell : MBLSRuleBaseCollectionTableViewCell <MBLSRuleDragAndDropProtocol>

@property (weak,nonatomic) LSReplacementRule                                *replacementRule;

@property (weak, nonatomic) IBOutlet UIImageView                            *customImageView;

@end
