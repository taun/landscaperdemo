//
//  MBFractalSegment.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBFractalSegment.h"

@implementation MBFractalSegment

@synthesize lineWidth = _lineWidth;
@synthesize lineColor = _lineColor;
@synthesize fillColor = _fillColor;
@synthesize fill = _fill, stroke = _stroke;
@synthesize path = _path;
@synthesize transform = _transform;


- (id)init {
    self = [super init];
    if (self) {
        CGMutablePathRef newPath = CGPathCreateMutable();
        _path = newPath;
        CGPathRetain(_path);
        
        _lineWidth = 1.0;
        _lineColor = NULL;
        _stroke = YES;
        _fillColor = NULL;
        _fill = NO;
        _transform = CGAffineTransformIdentity;
    }
    return self;
}

-(NSString*) debugDescription {
    return [NSString stringWithFormat: @"Path %@, lineWidth: %d, stroke: %i", _path, _lineWidth, _stroke];
}

-(CGMutablePathRef) path {
    return _path;
}

-(void) setPath:(CGMutablePathRef)path {
    if (_path != path) {
        CGPathRelease(_path);
        _path = path;
        CGPathRetain(_path);
    }
}

-(CGColorRef) lineColor {
    return _lineColor;
}

-(void) setLineColor:(CGColorRef)lineColor {
    if (_lineColor != lineColor) {
        CGColorRelease(_lineColor);
        _lineColor = lineColor;
        CGColorRetain(_lineColor);
    }
    if (_fillColor==NULL) {
        self.fillColor = lineColor;
    }
}

-(CGColorRef) fillColor {
    return _fillColor;
}

-(void) setFillColor:(CGColorRef)fillColor {
    if (_fillColor != fillColor) {
        CGColorRelease(_fillColor);
        _fillColor = fillColor;
        CGColorRetain(_fillColor);
    }
}

-(MBFractalSegment*) copySettings {
    MBFractalSegment* newSegment = [[MBFractalSegment alloc] init];
    newSegment.lineColor = self.lineColor;
    newSegment.lineWidth = self.lineWidth;
    newSegment.stroke = self.stroke;
    
    newSegment.fillColor = self.fillColor;
    newSegment.fill = self.fill;
    
    newSegment.transform = self.transform;
    
    CGPoint currentPoint = CGPathGetCurrentPoint(self.path);
    CGAffineTransform currentTransform = newSegment.transform;
    CGPathMoveToPoint(newSegment.path, &currentTransform, 0, 0);
    
    return newSegment;
}

-(void) dealloc {
    CGPathRelease(_path);
    CGColorRelease(_lineColor);
    CGColorRelease(_fillColor);
}

@end
