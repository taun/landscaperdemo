//
//  MBLSRuleCollectionTableViewCell.m
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSRuleCollectionTableViewCell.h"

@implementation MBLSRuleCollectionTableViewCell

/*!
 Initializes a table cell with a style and a reuse identifier and returns it to the caller.
 
 @param style           A constant indicating a cell style. See UITableViewCellStyle for descriptions of these constants.
 @param reuseIdentifier A string used to identify the cell object if it is to be reused for drawing multiple rows of a table view. Pass nil if the cell object is not to be reused. You should use the same reuse identifier for all cells of the same form.
 
 @return An initialized UITableViewCell object or nil if the object could not be created.
 */
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}
/*!
 Prepares a reusable cell for reuse by the table view's delegate.
 */
-(void)prepareForReuse {
    
}

-(void) awakeFromNib {
    [super awakeFromNib];
//    [self setTranslatesAutoresizingMaskIntoConstraints: NO];
//    [self.contentView setTranslatesAutoresizingMaskIntoConstraints: NO];
}

-(void)updateConstraints {
    
    // need to set height and width constraints on the collectionView here
    // collectionView width is the cell width minus margins
    // collectionView height is the collection contentView height based on the above width.
    
    // collection view width just set to a > value?
    
//    if (self.superview) {
//        // set width to superview width
//        
//        NSMutableArray* constraints = [[NSMutableArray alloc] initWithCapacity: 2];
//        
//        [constraints addObject: [NSLayoutConstraint constraintWithItem: self
//                                                             attribute: NSLayoutAttributeLeading
//                                                             relatedBy: NSLayoutRelationEqual
//                                                                toItem: self.superview
//                                                             attribute: NSLayoutAttributeLeading
//                                                            multiplier: 1.0
//                                                              constant: 0]
//         ];
//        
//        [constraints addObject: [NSLayoutConstraint constraintWithItem: self
//                                                             attribute: NSLayoutAttributeWidth
//                                                             relatedBy: NSLayoutRelationEqual
//                                                                toItem: self.superview
//                                                             attribute: NSLayoutAttributeWidth
//                                                            multiplier: 1.0
//                                                              constant: 0]
//         ];
//        [self.superview addConstraints: constraints];
//    }
    
//    CGFloat newHeight = self.contentSize.height;
//    
//    
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
    
//    NSString* constraintsString = [self.contentView.constraints description];
}

-(void) layoutSubviews {
//    if (self.superview && (self.superview.constraints.count == 0)) {
//        [self setNeedsUpdateConstraints];
//    }
    [super layoutSubviews];
    
//    NSString* constraintsString = [self.contentView.constraints description];
}

@end
