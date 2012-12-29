//
//  MBFractalLayer.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBFractalLayer.h"
#import "MBLSFractal.h"
#import "MBFractalSegment.h"
#include <math.h>

@implementation MBFractalLayer

@synthesize fractal = _fractal;

- (id)init {
    self = [super init];
    if (self) {
        self.anchorPoint = CGPointMake(0.0f, 0.0f);
        //TODO: there is a bit of a circular reference problem here
        //The controller is sizing the content to the layer bounds but the layer resizes the content to changed layer bounds. This should allow resizing the fractal by resizing the layer without redrawing the fractal path.
//        self.contentsGravity = kCAGravityCenter;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    
    CGContextSaveGState(ctx);
    
    // outline the layer bounding box
    CGContextBeginPath(ctx);
    CGContextAddRect(ctx, self.bounds);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetRGBStrokeColor(ctx, 0.5, 0.0, 0.0, 0.1);
    CGContextStrokePath(ctx);
    
    // move 0,0 down to the bottom left corner
    CGContextTranslateCTM(ctx, self.bounds.origin.x, self.bounds.origin.y + self.bounds.size.height);
    // flip the Y axis so +Y is up direction from origin
    if ([self contentsAreFlipped]) {
        //CGContextConcatCTM(ctx, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
        CGContextScaleCTM(ctx, 1.0, -1.0);
    }
    
    // put a small square at the origin
    CGContextBeginPath(ctx);
    CGContextAddRect(ctx, CGRectMake(0, 0, 10, 10));
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetRGBStrokeColor(ctx, 0.5, 0.0, 0.4, 0.1);
    CGContextStrokePath(ctx);

    CGContextRestoreGState(ctx);
    
    CGContextSaveGState(ctx);
    
    double scale = self.bounds.size.width/self.fractal.bounds.size.width;
    double margin = -0.0/scale;
    
    CGRect fBounds = CGRectStandardize(CGRectInset(self.fractal.bounds, margin, margin) );

    CGContextScaleCTM(ctx, scale, scale);
    CGContextTranslateCTM(ctx, -fBounds.origin.x, -fBounds.origin.y);
    
    for (MBFractalSegment* segment in self.fractal.finishedSegments) {
        // stroke and or fill each segment
        CGContextBeginPath(ctx);
        
        // Scale the lineWidth to compensate for the overall scaling
//        CGContextSetLineWidth(ctx, segment.lineWidth);
        CGContextSetLineWidth(ctx, segment.lineWidth/scale);
        
        CGContextAddPath(ctx, segment.path);
        
        //init to default value
        CGPathDrawingMode strokeOrFill = kCGPathStroke;
        if (segment.fill && segment.stroke) {
            strokeOrFill = kCGPathFillStroke;
            CGContextSetStrokeColorWithColor(ctx, segment.lineColor);
            CGContextSetFillColorWithColor(ctx, segment.fillColor);
        } else if (segment.stroke) {
            strokeOrFill = kCGPathStroke;
            CGContextSetStrokeColorWithColor(ctx, segment.lineColor);
        } else if (segment.fill) {
            strokeOrFill = kCGPathFill;
            CGContextSetFillColorWithColor(ctx, segment.fillColor);
        }
        CGContextDrawPath(ctx, strokeOrFill);
    }
    
    CGContextRestoreGState(ctx);
}

@end
