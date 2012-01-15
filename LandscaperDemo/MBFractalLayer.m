//
//  MBFractalLayer.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBFractalLayer.h"
#import "MBIFSFractal.h"
#import "MBFractalSegment.h"
#include <math.h>

@implementation MBFractalLayer

@synthesize fractal = _fractal;

- (id)init {
    self = [super init];
    if (self) {
        self.anchorPoint = CGPointMake(0.0f, 1.0f);
        //TODO: there is a bit of a circular reference problem here
        //The controller is sizing the content to the layer bounds but the layer resizes the content to changed layer bounds. This should allow resizing the fractal by resizing the layer without redrawing the fractal path.
        self.contentsGravity = kCAGravityCenter;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    
    CGContextSaveGState(ctx);
    
    self.contentsGravity = kCAGravityCenter;
    
    // change view aspect to match fractal
    // only reduce dimension
    CGRect fractalBounds = self.fractal.bounds;
    
    // create a transform to scale the fractal into the layer
    CGRect viewBounds = self.bounds;
    CGRect marginBounds = viewBounds;
    // scale fractal to fit view bounds    
    double scale = ((viewBounds.size.width)/fractalBounds.size.width);
    scale = MAX(scale, (viewBounds.size.height)/fractalBounds.size.height);
    double margin = 0.0;
    
    marginBounds.origin.x -= margin;
    marginBounds.origin.y -= margin;
    marginBounds.size.width += margin;
    marginBounds.size.height += margin;
    
    self.bounds = marginBounds;
    
    // translate fractal origin to view origin
    CGPoint fOrigin = fractalBounds.origin;
    CGPoint vOrigin = viewBounds.origin;
    
    CGSize fSize = fractalBounds.size;
    CGSize vSize = viewBounds.size;
    
    
    
    // outline the layer bounding box
    CGContextBeginPath(ctx);
    CGContextAddRect(ctx, marginBounds);
    CGContextSetLineWidth(ctx, 5.0);
    CGContextSetRGBStrokeColor(ctx, 0.5, 0.0, 0.0, 0.1);
//    CGContextStrokePath(ctx);

    // outline the layer bounding box
    CGContextBeginPath(ctx);
    CGContextAddRect(ctx, viewBounds);
    CGContextSetLineWidth(ctx, 5.0);
    CGContextSetRGBStrokeColor(ctx, 0.5, 0.0, 0.0, 0.1);
//    CGContextStrokePath(ctx);
    
    // move 0,0 down to the bottom left corner
    CGContextTranslateCTM(ctx, vOrigin.x, vOrigin.y + vSize.height);
    // flip the Y axis so +Y is up direction from origin
    if ([self contentsAreFlipped]) {
        CGContextConcatCTM(ctx, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
    }

    // put a small square at the origin
    CGContextBeginPath(ctx);
    CGContextAddRect(ctx, CGRectMake(0, 0, 10, 10));
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetRGBStrokeColor(ctx, 0.5, 0.0, 0.4, 0.1);
    CGContextStrokePath(ctx);
    
    // Scale so the largest axis fits
    CGContextScaleCTM(ctx, scale, scale);
    // translate the fractal to start at the origin
    CGContextTranslateCTM(ctx, vOrigin.x-fOrigin.x, vOrigin.y - fOrigin.y);    
    
    if ([self contentsAreFlipped]) {
        CGContextConcatCTM(ctx, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
        CGContextTranslateCTM(ctx, 0, fSize.height+5);
    }
    double maxLineWidth = 0;
    for (MBFractalSegment* segment in self.fractal.segments) {
        // stroke and or fill each segment
        CGContextBeginPath(ctx);
        
        // Scale the lineWidth to compensate for the overall scaling
        CGContextSetLineWidth(ctx, segment.lineWidth/scale);
        maxLineWidth = MAX(maxLineWidth, segment.lineWidth);
        
        CGContextAddPath(ctx, segment.path);
        CGPathDrawingMode strokeOrFill;
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
