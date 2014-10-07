//
//  MBLSRuleCollectionViewCell.m
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSRuleCollectionViewCell.h"

@implementation MBLSRuleCollectionViewCell

-(void) updateConstraints {
    
    UIView* contentView = self.contentView;
    
    // Cell only gets added as subview of collectionview if below is left as default yes.
    //    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSMutableArray* constraints = [NSMutableArray new];
    
    // translatesAutoresizingMask sets the contentView margins
    // this replaces the effect of the translatesAutoresizingMask on the contentView to cell
    [constraints addObject: [NSLayoutConstraint
                             constraintWithItem: self
                             attribute: NSLayoutAttributeTop
                             relatedBy:NSLayoutRelationEqual
                             toItem: contentView
                             attribute: NSLayoutAttributeTop
                             multiplier: 1.0
                             constant: 0]];

    [constraints addObject: [NSLayoutConstraint
                             constraintWithItem: self
                             attribute: NSLayoutAttributeBottom
                             relatedBy:NSLayoutRelationEqual
                             toItem: contentView
                             attribute: NSLayoutAttributeBottom
                             multiplier: 1.0
                             constant: 0]];
    
    [constraints addObject: [NSLayoutConstraint
                             constraintWithItem: self
                             attribute: NSLayoutAttributeLeading
                             relatedBy:NSLayoutRelationEqual
                             toItem: contentView
                             attribute: NSLayoutAttributeLeading
                             multiplier: 1.0
                             constant: 0]];
    
    [constraints addObject: [NSLayoutConstraint
                             constraintWithItem: self
                             attribute: NSLayoutAttributeTrailing
                             relatedBy:NSLayoutRelationEqual
                             toItem: contentView
                             attribute: NSLayoutAttributeTrailing
                             multiplier: 1.0
                             constant: 0]];
    
    
    if (self.superview) {
        
        UICollectionView* collectionView = (UICollectionView*)self.superview;
        UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
        CGFloat cellWidth = layout.itemSize.width;
        CGFloat cellHeight = layout.itemSize.height;
        
        // translatesAutoresizingMask sets the cell height and width
        // this replaces the effect of the translatesAutoresizingMask on the cell
        [constraints addObject: [NSLayoutConstraint
                                 constraintWithItem: self
                                 attribute: NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                 toItem: nil
                                 attribute: NSLayoutAttributeNotAnAttribute
                                 multiplier: 1.0
                                 constant: cellWidth]];
        
        [constraints addObject: [NSLayoutConstraint
                                 constraintWithItem: self
                                 attribute: NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                 toItem: nil
                                 attribute: NSLayoutAttributeNotAnAttribute
                                 multiplier: 1.0
                                 constant: cellHeight]];
        
    }
    [self removeConstraints: self.constraints];
    
    [self addConstraints: constraints];
    
    [super updateConstraints];
}

@end
