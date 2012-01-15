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


- (id)initWithPath:(CGPathRef) path 
         lineWidth: (double) lineWidth 
         lineColor: (CGColorRef) lineColor 
            stroke: (BOOL) stroke 
         fillColor: (CGColorRef) fillColor 
              fill: (BOOL) fill {
    self = [super init];
    if (self) {
        // set default values
        _path = path;
        _lineWidth = lineWidth;
        _lineColor = lineColor;
        _stroke = stroke;
        _fillColor = fillColor;
        _fill = fill;
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self = [self initWithPath:nil 
                 lineWidth:0.0 
                 lineColor:nil 
                    stroke:YES 
                 fillColor:nil 
                      fill:NO];
    }
    return self;
}

-(CGPathRef) path {
    return _path;
}

-(void) setPath:(CGPathRef)path {
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
}

-(CGColorRef) fillColor {
    return _fillColor;
}

-(void) setFillColor:(CGColorRef)fillColor {
    if (_fillColor != fillColor) {
        CGColorRelease(_fillColor);
        _lineColor = fillColor;
        CGColorRetain(_fillColor);
    }
}

-(void) dealloc {
    CGPathRelease(_path);
    CGColorRelease(_lineColor);
    CGColorRelease(_fillColor);
}

@end
