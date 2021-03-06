//
//  MBFractalSegment.m
//  FractalScape
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

 
#import "MBFractalSegment.h"
#include "QuartzHelpers.h"
#include <math.h>

//@implementation MBFractalSegment
//
//
//+(NSArray*)settingsToCopy {
//    return @[@"turningAngle",
//             @"turningAngleIncrement",
//             @"lineLength",
//             @"lineWidth",
//             @"lineWidthIncrement",
//             @"lineLengthScaleFactor",
//             @"lineChangeFactor",
//             @"randomize",
//             @"randomness",
//             @"fill",
//             @"stroke",
//             @"lineCap",
//             @"lineJoin",
//             @"transform",
//             @"lineColorIndex",
//             @"fillColorIndex"
//             ];
//}
//
//+ (CGFloat)randomDoubleBetween:(CGFloat)smallNumber and:(CGFloat)bigNumber {
//    CGFloat diff = bigNumber - smallNumber;
//    return (((CGFloat) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
//}
//
//-(CGFloat) randomScalar {
//    return [[self class] randomDoubleBetween: (1.0 - self.randomness)  and: (1.0 + self.randomness)];
//}
//
//
//- (instancetype)init {
//    self = [super init];
//    if (self) {
//        
//        
//        _turningAngle = M_PI_4;
//        _turningAngleIncrement = 0.0;
//        
//        _lineLength = 10.0;
//        _lineLengthScaleFactor = 1.0;
//        
//        _lineWidth = 1.0;
//        _lineWidthIncrement = 0.0;
//        
//        _transform = CGAffineTransformIdentity;
//    }
//    return self;
//}
//
//-(CGMutablePathRef) path {
//    if (_path == NULL) {
//        _path = CGPathCreateMutable();
//    }
//    return _path;
//}
//
//-(void) setPath:(CGMutablePathRef)path {
//    if (CGPathEqualToPath(_path, path)) return;
//    
//    CGPathRelease(_path);
//    _path = NULL;
//    
//    if (path != NULL) {
//        _path = (CGMutablePathRef) CGPathRetain(path);
//    }
//}
//
////-(CGColorRef) lineColor {
////    if (_lineColor == NULL) {
////        _lineColor = CreateDeviceRGBColor(0.0, 0.0, 0.0, 1.0);
////        CGColorRetain(_lineColor);
////        self.stroke = YES;
////    }
////    return _lineColor;
////}
//
////-(void) setLineColor:(CGColorRef)lineColor {
////    if (CGColorEqualToColor(_lineColor,lineColor)) return;
////    
////    CGColorRelease(_lineColor);
////    if (lineColor != NULL) {
////        _lineColor = CGColorRetain(lineColor);
////    }
////}
//
////-(CGColorRef) fillColor {
////    if (_fillColor == NULL) {
////        _fillColor = CreateDeviceGrayColor(0.8, 0.8);
////        CGColorRetain(_fillColor);
////        self.fill = NO;
////    }
////    return _fillColor;
////}
////
////-(void) setFillColor:(CGColorRef)fillColor {
////    if (CGColorEqualToColor(_fillColor,fillColor)) return;
////    
////    CGColorRelease(_fillColor);
////    if (fillColor != NULL) {
////        _fillColor = CGColorRetain(fillColor);
////    }
////}
//
//-(MBFractalSegment*) copySettings {
//    MBFractalSegment* newSegment = [[MBFractalSegment alloc] init];
//    
//    if (!_randomize) {
//        [newSegment setTurningAngle: _turningAngle];
//        [newSegment setTurningAngleIncrement: _turningAngleIncrement];
//        newSegment.lineLength = self.lineLength;
//        newSegment.lineWidth = self.lineWidth;
//        newSegment.lineWidthIncrement = self.lineWidthIncrement;
//        newSegment.lineLengthScaleFactor = self.lineLengthScaleFactor;
//        newSegment.lineChangeFactor = self.lineChangeFactor;
//        newSegment.randomize = self.randomize;
//        newSegment.randomness = self.randomness;
//        newSegment.fill = self.fill;
//        newSegment.stroke = self.stroke;
//        newSegment.lineCap = self.lineCap;
//        newSegment.lineJoin = self.lineJoin;
//        newSegment.transform = self.transform;
//        newSegment.lineColorIndex = self.lineColorIndex;
//        newSegment.fillColorIndex = self.fillColorIndex;
//    } else {
//        newSegment.turningAngle = self.turningAngle;
//        newSegment.turningAngleIncrement = self.turningAngleIncrement;
//        newSegment.lineLength = self.lineLength;
//        newSegment.lineWidth = self.lineWidth;
//        newSegment.lineWidthIncrement = self.lineWidthIncrement;
//        newSegment.lineLengthScaleFactor = self.lineLengthScaleFactor;
//        newSegment.lineChangeFactor = self.lineChangeFactor;
//        newSegment.randomize = self.randomize;
//        newSegment.randomness = self.randomness;
//        newSegment.fill = self.fill;
//        newSegment.stroke = self.stroke;
//        newSegment.lineCap = self.lineCap;
//        newSegment.lineJoin = self.lineJoin;
//        newSegment.transform = self.transform;
//        newSegment.lineColorIndex = self.lineColorIndex;
//        newSegment.fillColorIndex = self.fillColorIndex;
//    }
//   
//    CGAffineTransform currentTransform = newSegment.transform;
//    CGPathMoveToPoint(newSegment.path, &currentTransform, 0, 0);
//    
//    return newSegment;
//}
//
//#pragma mark - KVC overrides for CGColorRef properties
//
//- (id)valueForUndefinedKey:(NSString *)key {
////    if ([key isEqualToString:@"lineColor"]) {
////        return (id)self.lineColor;
////    } else if ([key isEqualToString:@"fillColor"]) {
////        return (id)self.fillColor;
////    }
//    
//    return [super valueForUndefinedKey:key];
//}
//
//- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
////    if ([key isEqualToString:@"lineColor"]) {
////        self.lineColor = (__bridge CGColorRef) value;
////    } else if ([key isEqualToString:@"fillColor"]) {
////        self.fillColor = (__bridge CGColorRef) value;
////    } else {
//        [super setValue: value forUndefinedKey: key];
////    }
//}
//
//-(void) dealloc {
//    CGPathRelease(_path);
////    CGColorRelease(_lineColor);
////    CGColorRelease(_fillColor);
//}
//
//
//
//-(CGFloat) turningAngle {
//    CGFloat value = _turningAngle;
//    if (_randomize) {
//        value *= [self randomScalar];
//    }
//    return value;
//}
//
//-(CGFloat) turningAngleIncrement {
//    CGFloat value = _turningAngleIncrement;
//    if (_randomize) {
//        value *= [self randomScalar];
//    }
//    return value;
//}
//
//-(CGFloat) lineLength {
//    CGFloat value = _lineLength;
//    if (_randomize) {
//        value *= [self randomScalar];
//    }
//    return value;
//}
//
//-(CGFloat) lineLengthScaleFactor {
//    CGFloat value = _lineLengthScaleFactor;
//    if (_randomize) {
//        value *= [self randomScalar];
//    }
//    return value;
//}
//
//-(CGFloat) lineWidth {
//    CGFloat value = fabs(_lineWidth);
//    if (_randomize) {
//        value *= [self randomScalar];
//    }
//    return value;
//}
//
//-(CGFloat) lineWidthIncrement {
//    CGFloat value = _lineWidthIncrement;
//    if (_randomize) {
//        value *= [self randomScalar];
//    }
//    return value;
//}
//
//
//-(NSString*) colorAsString: (CGColorRef) color {
//    NSString* resultString;
//    NSArray* componentsArray;
//    
//    const CGFloat *components = CGColorGetComponents(color);
//    
//    switch(CGColorSpaceGetModel(CGColorGetColorSpace(color)))
//    {
//        case kCGColorSpaceModelMonochrome:
//            // For grayscale colors, the luminance is the color value
//            componentsArray =@[@"Monochrome:", @(components[0])];
//            break;
//            
//        case kCGColorSpaceModelRGB:
//            // For RGB colors, we calculate luminance assuming sRGB Primaries as per
//            // http://en.wikipedia.org/wiki/Luminance_(relative)
//            componentsArray =@[@"RGB:",
//                               @(components[0]),
//                               @(components[1]),
//                               @(components[2]),
//                               @(components[3])];
//            break;
//            
//        default:
//            // We don't implement support for non-gray, non-rgb colors at this time.
//            // Since our only consumer is colorSortByLuminance, we return a larger than normal
//            // value to ensure that these types of colors are sorted to the end of the list.
//            componentsArray =@[@"Default"];
//    }
//    resultString = [componentsArray componentsJoinedByString: @" "];
//    return  resultString;
//}
//
//-(NSString*) debugDescription {
//    NSString* stroke = self.stroke ? @"YES" : @"NO";
//    NSString* fill = self.fill ? @"YES" : @"NO";
////    NSString* lineColorComponents = [self colorAsString: self.lineColor];
////    NSString* fillColorComponents = [self colorAsString: self.fillColor];
//    
//    return [NSString stringWithFormat: @"Path %@; lineWidth = %g; LineColorIndex = %ld; stroke = %@; FillColorIndex = %ld; fill = %@",
//            _path, _lineWidth, (long)_lineColorIndex, stroke, (long)_fillColorIndex, fill];
//}
//
//
//
//
//@end
