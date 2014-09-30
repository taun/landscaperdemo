//
//  MBLSRuleCollectionSourceTableViewCell.m
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSRuleCollectionSourceTableViewCell.h"

@implementation MBLSRuleCollectionSourceTableViewCell

//-(void) layoutSubviews {
//    self.collectionView.bounds = self.contentView.bounds;
//}

-(void) updateConstraints {
    
    UIView* contentView = self.contentView;
    UIView* collectionView = self.collectionView;
    
    NSMutableArray* constraints = [[NSMutableArray alloc] init];
    
    [constraints addObject: [NSLayoutConstraint
                             constraintWithItem: collectionView
                             attribute: NSLayoutAttributeTop
                             relatedBy:NSLayoutRelationEqual
                             toItem: contentView
                             attribute: NSLayoutAttributeTop
                             multiplier: 1.0
                             constant: 0.0]
     ];
    [constraints addObject: [NSLayoutConstraint
                             constraintWithItem: collectionView
                             attribute: NSLayoutAttributeBottom
                             relatedBy:NSLayoutRelationEqual
                             toItem: contentView
                             attribute: NSLayoutAttributeBottom
                             multiplier: 1.0
                             constant: 0.0]
     ];
    
    [self.contentView addConstraints: constraints];
    
    
    [super updateConstraints];
}

@end
