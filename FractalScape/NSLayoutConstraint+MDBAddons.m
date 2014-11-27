//
//  NSLayoutConstraint+MDBAddons.m
//  FractalScape
//
//  Created by Taun Chapman on 11/26/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "NSLayoutConstraint+MDBAddons.h"

@implementation NSLayoutConstraint (MDBAddons)

+(NSArray*) constraintsForFlowing:(NSArray *)views inContainingView:(UIView *)container forOrientation:(UILayoutConstraintAxis)axis withSpacing:(CGFloat)spacing {

    NSMutableArray* constraints = [NSMutableArray new];

    if (views.count > 0) {
        
        NSInteger viewIndex;

        UIView* firstView = [views firstObject];
        UIView* lastView = [views lastObject];
        
        NSLayoutAttribute firstEdgeAttribute;
        NSLayoutAttribute lastEdgeAttribute;

        if (axis == UILayoutConstraintAxisVertical) {
            firstEdgeAttribute = NSLayoutAttributeTop;
            lastEdgeAttribute = NSLayoutAttributeBottom;
        } else {
            firstEdgeAttribute = NSLayoutAttributeLeft;
            lastEdgeAttribute = NSLayoutAttributeRight;
        }
        
        [constraints addObject: [NSLayoutConstraint constraintWithItem: container
                                                             attribute: firstEdgeAttribute
                                                             relatedBy: NSLayoutRelationEqual
                                                                toItem: firstView
                                                             attribute: firstEdgeAttribute
                                                            multiplier: 1.0
                                                              constant: 0.0]];
                
        for (viewIndex = 1; viewIndex < views.count ; viewIndex++) {
            //
            UIView* prevView = views[viewIndex-1];
            UIView* view = views[viewIndex];
            
            [constraints addObject: [NSLayoutConstraint constraintWithItem: view
                                                                 attribute: firstEdgeAttribute
                                                                 relatedBy: NSLayoutRelationEqual
                                                                    toItem: prevView
                                                                 attribute: lastEdgeAttribute
                                                                multiplier: 1.0
                                                                  constant: spacing]];
            
        }
        
        [constraints addObject: [NSLayoutConstraint constraintWithItem: lastView
                                                             attribute: lastEdgeAttribute
                                                             relatedBy: NSLayoutRelationEqual
                                                                toItem: container
                                                             attribute: lastEdgeAttribute
                                                            multiplier: 1.0
                                                              constant: 0.0]];
        
    }
    
    return constraints;
}

@end
