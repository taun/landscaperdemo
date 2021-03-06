//
//  MBFractalSegment.h
//  FractalScape
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

@import Foundation;

@import QuartzCore;

#import "MBColor.h"

static const NSInteger kLSMaxSegmentPointsSize = 60;
static const NSInteger kLSMaxSegmentStackSize = 30;
static const NSInteger kLSMaxColors = 30;


struct MBSegmentStruct {
    CGContextRef        context;
    CGMutablePathRef    path;
    CGPoint             points[kLSMaxSegmentPointsSize]; // connected path points
    NSInteger           pointIndex; // index points to current valid point. init to -1
    CGPathDrawingMode   mode;
    BOOL                advancedMode;
    CGAffineTransform   transform; // Local transform so points can be used. Transform point before adding to points.
    CGFloat             scale;
    BOOL                noDrawPath;
    CGFloat             baseAngle;
    CGFloat             turningAngle;
    CGFloat             turningAngleIncrement;
    BOOL                drawingModeUnchanged;
    BOOL                stroke;
    CGLineCap           lineCap;
    CGLineJoin          lineJoin;
    NSInteger           lineColorIndex;
    ColorRgbaOrColorRef currentLineColor;
    CGFloat             lineLength;
    CGFloat             lineWidth;
    CGFloat             lineWidthIncrement;
    CGFloat             lineLengthScaleFactor;
    CGFloat             lineChangeFactor;
    CGFloat             lineHueRotationPercent;
    CGFloat             fillHueRotationPercent;
    BOOL                fill;
    BOOL                EOFill;
    NSInteger           fillColorIndex;
    ColorRgbaOrColorRef currentFillColor;
    BOOL                randomize;
    CGFloat             randomness;
    BOOL                inCurve;
} ;
typedef struct MBSegmentStruct MBSegmentStruct;
typedef MBSegmentStruct* MBSegmentRef;

#pragma message "REMOVE: MBFractalSegment class obsolete"
/*!
 A fractal path segment.
 */
//@interface MBFractalSegment : NSObject {
//    CGMutablePathRef    _path;
//}
//
//@property (nonatomic, assign) CGMutablePathRef      path;
//
//@property (nonatomic,assign) CGFloat                 turningAngle;
//@property (nonatomic,assign) CGFloat                 turningAngleIncrement;
//@property (nonatomic,assign) CGFloat                 lineLength;
//@property (nonatomic,assign) CGFloat                 lineWidth;
//@property (nonatomic,assign) CGFloat                 lineWidthIncrement;
//@property (nonatomic,assign) CGFloat                 lineLengthScaleFactor;
//@property (nonatomic,assign) CGFloat                 lineChangeFactor;
//@property (nonatomic,assign) BOOL                   randomize;
//@property (nonatomic,assign) CGFloat                 randomness;
//@property (nonatomic,assign) BOOL                   fill;
//@property (nonatomic,assign) BOOL                   stroke;
//@property (nonatomic,assign) CGLineCap              lineCap;
//@property (nonatomic,assign) CGLineJoin             lineJoin;
//
//@property (nonatomic,assign) NSInteger              lineColorIndex;
//@property (nonatomic,assign) NSInteger              fillColorIndex;
//
//@property (nonatomic,assign) CGAffineTransform      transform;
//
//+(NSArray*)settingsToCopy;
//+(CGFloat)randomDoubleBetween:(CGFloat)smallNumber and:(CGFloat)bigNumber;
//
//@property (NS_NONATOMIC_IOSONLY, readonly, strong) MBFractalSegment *copySettings;
//
//-(CGFloat) randomScalar;
//
//@end
