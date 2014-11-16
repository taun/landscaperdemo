//
//  MBLSRuleCollectionViewCell.m
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSRuleCollectionViewCell.h"

#import <MDUiKit/MDUiKit.h>

@implementation MBLSRuleCollectionViewCell

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    return self;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    return self;
}
/*!
 Prepares a reusable cell for reuse by the table view's delegate.
 */
-(void)prepareForReuse {
    
}
-(void) awakeFromNib {
    [super awakeFromNib];
    
    MDKLayerViewDesignable* layerView = [[MDKLayerViewDesignable alloc] initWithFrame: CGRectZero];
    
    layerView.maskToBounds = NO;
    layerView.cornerRadius = 4.0;
    layerView.margin = 4;
    layerView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent: 0.15];
    
    self.selectedBackgroundView = layerView;
    
    self.defaultImage = self.customImageView.image;
}

-(void)setCellItem:(id)item {
    if (_cellItem != item) {
        _cellItem = item;
        if (item) {
            self.customImageView.image = [_cellItem asImage];
        } else {
            self.customImageView.image = self.defaultImage;
        }
    }
}

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

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    return nil;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}

@end
