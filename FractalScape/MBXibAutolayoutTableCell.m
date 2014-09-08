//
//  MBXibAutolayoutTableCell.m
//  FractalScape
//
//  Created by Taun Chapman on 03/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBXibAutolayoutTableCell.h"

@interface MBXibAutolayoutTableCell ()

-(void) fixSubviewsOuterConstraints;

@end

@implementation MBXibAutolayoutTableCell

-(void) awakeFromNib {
    [super awakeFromNib];
    [self fixConstraints];
//    [self fixSubviewsOuterConstraints];
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/*!
 Seems to be a bug in iOS 8 beta#?
 Cannont add constraints to the contentView using IB so we do it manually.
 */
-(void) fixConstraints {
    UIView* contentView = self.contentView;
    
    NSMutableArray* constraints = [[NSMutableArray alloc] init];
    
    [constraints addObject: [NSLayoutConstraint
                             constraintWithItem: contentView
                             attribute: NSLayoutAttributeHeight
                             relatedBy:NSLayoutRelationGreaterThanOrEqual
                             toItem: nil
                             attribute: 0
                             multiplier: 1.0
                             constant: 44.0]];
    
    [self.contentView addConstraints: constraints];
}
/*!
 This was an autolayout fix for iOS 6.
 No obsolete.
 */
-(void) fixSubviewsOuterConstraints {

    UIView* cellView = self.contentView.superview;
    UIView* contentView = self.contentView;
    UIView* embeddedView = self.embeddedSubviews;
    
//    NSArray* constraints = [cellView constraints];
//    NSLog(@"cellViews: %@;", [cellView subviews]);
//    NSLog(@"cellView: %@; constraints: %@;", cellView, constraints);
//   
//    constraints = [contentView constraints];
//    NSLog(@"contentViews: %@;", [contentView subviews]);
//    NSLog(@"contentView: %@; constraints: %@;", contentView, constraints);
//    [self.contentView removeConstraints: constraints];
    
//    constraints = [embeddedView constraints];
//    NSLog(@"embeddedView: %@; constraints: %@;", embeddedView, constraints);

    // Remove the constraints from the embeddedView to the cellView added by IB
    // allows the contentView to autolayout properly
    [cellView removeConstraints: cellView.constraints];
    
    NSArray* newConstraints;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(contentView, embeddedView);
    
    // Add new constraints which just make the embeddedView the same size as the contentView
    // All of the subViews should be laid out relative to the embeddedView and so unchanged
    // Especially if the embeddedView is just made the same size as the contentView in IB
    newConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[embeddedView]-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:viewsDictionary];
    [contentView addConstraints: newConstraints];

    newConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[embeddedView]-0-|"
                                                             options:0
                                                             metrics:nil
                                                               views:viewsDictionary];
    [contentView addConstraints: newConstraints];
}
@end
