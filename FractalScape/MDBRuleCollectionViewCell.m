//
//  MDBRuleCollectionViewCell.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/07/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBRuleCollectionViewCell.h"

#import "LSDrawingRule.h"


@interface MDBRuleCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView    *ruleIconImage;
@property (weak, nonatomic) IBOutlet UILabel        *ruleDescriptionLabel;

@end

@implementation MDBRuleCollectionViewCell

-(void)setRule:(LSDrawingRule *)rule
{
    if (![_rule isEqual: rule])
    {
        _rule = rule;
        self.ruleIconImage.image = [rule asImage];
        self.ruleDescriptionLabel.text = rule.descriptor;
        
        [self setNeedsLayout];
    }
}

@end
