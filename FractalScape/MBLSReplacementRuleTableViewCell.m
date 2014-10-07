//
//  MBLSReplacementRuleTableViewCell.m
//  FractalScape
//
//  Created by Taun Chapman on 10/01/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSReplacementRuleTableViewCell.h"

@implementation MBLSReplacementRuleTableViewCell

-(void)updateConstraints {
    
    //    CGFloat newHeight = self.contentSize.height;
    //
    //    if (newHeight > 0) {
    //
    //        self.currentHeightConstraint = [NSLayoutConstraint constraintWithItem: self
    //                                                                    attribute: NSLayoutAttributeHeight
    //                                                                    relatedBy: NSLayoutRelationEqual
    //                                                                       toItem: nil
    //                                                                    attribute: NSLayoutAttributeNotAnAttribute
    //                                                                   multiplier: 1.0
    //                                                                     constant: newHeight];
    //
    //        [self addConstraint: self.currentHeightConstraint];
    //    }
    
    // change constraints above
    [super updateConstraints];
    NSString* constraintsString = [self.contentView.constraints description];
}

@end
