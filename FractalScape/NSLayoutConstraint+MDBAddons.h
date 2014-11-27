//
//  NSLayoutConstraint+MDBAddons.h
//  FractalScape
//
//  Created by Taun Chapman on 11/26/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSLayoutConstraint (MDBAddons)

/*!
 Should check for whether all of the 'views' are subviews of the container.
 This does not handle the orthogonal axis constraints. That is still up to the calling method. 
 For example, if stacking vertically, the width of each item is not handled.
 
 @param views     the views to be stacked in the container
 @param container the container of the views
 @param axis      which axis to use for stacking
 @param spacing   inter item spacing. Not added as padding between the container and contained views. 
 
 @return an array of constraints to add to the containers constraints.
 */
+(NSArray*) constraintsForFlowing: (NSArray*)views inContainingView: (UIView*)container forOrientation: (UILayoutConstraintAxis) axis withSpacing: (CGFloat) spacing;

@end
