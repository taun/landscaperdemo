//
//  FractalPadView.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/03/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

// TODO: unused

#import "FractalPadView.h"
#import <QuartzCore/QuartzCore.h>

#include "Model/QuartzHelpers.h"


@implementation FractalPadView

- (void)awakeFromNib
{
    [self setupLayers];
}

-(void) setupLayers {
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext {
    
//	CGContextSetFillColorWithColor(theContext, graphBackgroundColor());
//	CGContextFillRect(theContext, theLayer.bounds);
//    
//    CGMutablePathRef thePath = CGPathCreateMutable();
//    
//    CGPathMoveToPoint(thePath,NULL,15.0f,15.f);
//    CGPathAddCurveToPoint(thePath,
//                          NULL,
//                          15.f,250.0f,
//                          295.0f,250.0f,
//                          295.0f,15.0f);
//    
//    CGContextBeginPath(theContext);
//    CGContextAddPath(theContext, thePath );
//    
//    CGContextSetLineWidth(theContext,
//                          [[theLayer valueForKey:@"lineWidth"] floatValue]);
//    CGContextStrokePath(theContext);
//    
//    // release the path
//    CGPathRelease(thePath);
}

@end
