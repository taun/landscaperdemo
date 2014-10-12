//
//  MBLSReplacementRuleTableViewCell.m
//  FractalScape
//
//  Created by Taun Chapman on 10/01/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSReplacementRuleTableViewCell.h"

@implementation MBLSReplacementRuleTableViewCell

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
 Just here for future reference.
 */
-(void)prepareForReuse {
    
}
-(void)updateConstraints {
    
    
//    NSMutableArray* constraints = [NSMutableArray new];
//    NSLayoutConstraint* constraint;
//    
//    BOOL needsCenterX = YES;
//    BOOL needsCenterY = YES;
//    
//    for (NSLayoutConstraint* existingConstraint in self.imageView.superview.constraints) {
//        if ([existingConstraint.identifier isEqualToString: @"MBCenterX"]) {
//            needsCenterX = NO;
//        } else if ([existingConstraint.identifier isEqualToString: @"MBCenterY"]) {
//            needsCenterY = NO;
//        }
//    }
//    if (needsCenterX) {
//        constraint = [NSLayoutConstraint constraintWithItem: self.imageView
//                                                  attribute: NSLayoutAttributeCenterX
//                                                  relatedBy: NSLayoutRelationEqual
//                                                     toItem: self.imageView.superview
//                                                  attribute: NSLayoutAttributeCenterX
//                                                 multiplier: 1
//                                                   constant: 0];
//        constraint.identifier = @"MBCenterX";
//        [constraints addObject: constraint];
//    }
//    if (needsCenterY) {
//        constraint = [NSLayoutConstraint constraintWithItem: self.imageView.superview
//                                                  attribute: NSLayoutAttributeCenterY
//                                                  relatedBy: NSLayoutRelationEqual
//                                                     toItem: self.imageView.superview
//                                                  attribute: NSLayoutAttributeCenterY
//                                                 multiplier: 1
//                                                   constant: 0];
//        constraint.identifier = @"MBCenterY";
//        [constraints addObject: constraint];
//    }
//    
//    [self.imageView.superview addConstraints: constraints];
    // change constraints above
    [super updateConstraints];
//    NSString* constraintsString = [self.contentView.constraints description];
}

@end
