//
//  MBFractalSegment.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBFractalSegment.h"
#include "QuartzHelpers.h"
#include <math.h>

@implementation MBFractalSegment

@synthesize path = _path;
@synthesize transform = _transform;

@synthesize lineWidth = _lineWidth, lineWidthIncrement = _lineWidthIncrement;
@synthesize lineLength = _lineLength, lineLengthScaleFactor = _lineLengthScaleFactor;
@synthesize stroke = _stroke, fill = _fill;

@synthesize turningAngle = _turningAngle, turningAngleIncrement = _turningAngleIncrement;

@synthesize lineColor = _lineColor, fillColor = _fillColor;


- (id)init {
    self = [super init];
    if (self) {
        CGMutablePathRef newPath = CGPathCreateMutable();
        _path = newPath;
        CGPathRetain(_path);
        
        CGColorRef defaultLineColor = CreateDeviceRGBColor(0.0, 0.0, 0.0, 1.0);
        CGColorRetain(defaultLineColor);
        
        CGColorRef  defaultFillColor = CreateDeviceGrayColor(0.8, 0.8);
        CGColorRetain(defaultFillColor);
        
        _turningAngle = M_PI_4;
        _turningAngleIncrement = 0.0;
        
        _lineLength = 10.0;
        _lineLengthScaleFactor = 1.0;
        
        _lineWidth = 1.0;
        _lineWidthIncrement = 0.0;
        
        _lineColor = defaultLineColor;
        _stroke = YES;
        
        _fillColor = defaultFillColor;
        _fill = NO;
        
        _transform = CGAffineTransformIdentity;
    }
    return self;
}

-(NSString*) colorAsString: (CGColorRef) color {
    NSString* resultString;
    NSArray* componentsArray;
    
    const CGFloat *components = CGColorGetComponents(color);
    
    switch(CGColorSpaceGetModel(CGColorGetColorSpace(color)))
    {
        case kCGColorSpaceModelMonochrome:
            // For grayscale colors, the luminance is the color value
            componentsArray =[NSArray arrayWithObjects: @"Monochrome:", [NSNumber numberWithFloat: components[0]], nil];
            break;
            
        case kCGColorSpaceModelRGB:
            // For RGB colors, we calculate luminance assuming sRGB Primaries as per
            // http://en.wikipedia.org/wiki/Luminance_(relative)
            componentsArray =[NSArray arrayWithObjects: @"RGB:",
                              [NSNumber numberWithFloat: components[0]],
                              [NSNumber numberWithFloat: components[1]],
                              [NSNumber numberWithFloat: components[2]],
                              [NSNumber numberWithFloat: components[3]],
                              nil];
            break;
            
        default:
            // We don't implement support for non-gray, non-rgb colors at this time.
            // Since our only consumer is colorSortByLuminance, we return a larger than normal
            // value to ensure that these types of colors are sorted to the end of the list.
            componentsArray =[NSArray arrayWithObjects: @"Default",nil];
    }
    resultString = [componentsArray componentsJoinedByString: @" "];
    return  resultString;
}

-(NSString*) debugDescription {
    NSString* stroke = self.stroke ? @"YES" : @"NO";
    NSString* fill = self.fill ? @"YES" : @"NO";
    NSString* lineColorComponents = [self colorAsString: self.lineColor];
    NSString* fillColorComponents = [self colorAsString: self.fillColor];
    
    return [NSString stringWithFormat: @"Path %@, lineWidth: %d, LineColor: %@, stroke: %@, FillColor: %@, fill: %@", 
            _path, _lineWidth, lineColorComponents, stroke, fillColorComponents, fill];
}

-(CGMutablePathRef) path {
    return _path;
}

-(void) setPath:(CGMutablePathRef)path {
    if (CGPathEqualToPath(_path, path)) return;
    
    CGPathRelease(_path);
    if (path != NULL) {
    	_path = (CGMutablePathRef) CGPathRetain(path);
    }
}

-(CGColorRef) lineColor {
    return _lineColor;
}

-(void) setLineColor:(CGColorRef)lineColor {
    if (CGColorEqualToColor(_lineColor,lineColor)) return;
    
    CGColorRelease(_lineColor);
    if (lineColor != NULL) {
    	_lineColor = CGColorRetain(lineColor);
    }
}

-(CGColorRef) fillColor {
    return _fillColor;
}

-(void) setFillColor:(CGColorRef)fillColor {
    if (CGColorEqualToColor(_fillColor,fillColor)) return;
    
    CGColorRelease(_fillColor);
    if (fillColor != NULL) {
    	_fillColor = CGColorRetain(fillColor);
    }
}

- (NSArray*)settingsToCopy {
    return [NSArray arrayWithObjects:
            @"turningAngle",
            @"turningAngleIncrement",
            @"lineLength", 
            @"lineWidth",
            @"lineWidthIncrement",
            @"lineLengthScaleFactor",
            @"lineColor",
            @"fillColor",
            @"fill",
            @"stroke",
            @"transform",
            nil];
}

-(MBFractalSegment*) copySettings {
    MBFractalSegment* newSegment = [[MBFractalSegment alloc] init];
    
    for (id aSetting in [self settingsToCopy]) {
        [newSegment setValue:[self valueForKey: aSetting] forKey: aSetting];
    }
    
    CGAffineTransform currentTransform = newSegment.transform;
    CGPathMoveToPoint(newSegment.path, &currentTransform, 0, 0);
    
    return newSegment;
}

#pragma mark - KVC overrides for CGColorRef properties

- (id)valueForUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"lineColor"]) {
        return (id)self.lineColor;
    } else if ([key isEqualToString:@"fillColor"]) {
        return (id)self.fillColor;
    }
    
    return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"lineColor"]) {
        self.lineColor = (__bridge CGColorRef) value;
    } else if ([key isEqualToString:@"fillColor"]) {
        self.fillColor = (__bridge CGColorRef) value;
    } else {
        [super setValue: value forUndefinedKey: key];
    }
}

-(void) dealloc {
    CGPathRelease(_path);
    CGColorRelease(_lineColor);
    CGColorRelease(_fillColor);
}

@end
