//
//  MDBRuleCollectionViewCell.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/07/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LSDrawingRule;
@class MDKLayerViewDesignable;

@interface MDBRuleCollectionViewCell : UICollectionViewCell

@property (nonatomic,weak) LSDrawingRule                    *rule;
@property (weak, nonatomic) IBOutlet MDKLayerViewDesignable *designableContainerView;


@end
