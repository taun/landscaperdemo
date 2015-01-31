//
//  MBFractalSegment.h
//  FractalScape
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static const NSInteger kLSMaxSegmentPointsSize = 30;
static const NSInteger kLSMaxSegmentStackSize = 30;
static const NSInteger kLSMaxColors = 20;

struct MBSegmentStruct {
    CGContextRef        context;
    CGMutablePathRef    path;
    CGPoint             points[kLSMaxSegmentPointsSize]; // connected path points
    NSInteger          pointIndex; // index points to current valid point. init to -1
    CGPathDrawingMode   mode;
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
    CGColorRef          defaultLineColor;
    NSInteger           lineColorsCount;
    NSInteger           lineColorIndex;
    CGColorRef          lineColors[kLSMaxColors];
    CGFloat             lineLength;
    CGFloat             lineWidth;
    CGFloat             lineWidthIncrement;
    CGFloat             lineLengthScaleFactor;
    CGFloat             lineChangeFactor;
    BOOL                fill;
    BOOL                EOFill;
    CGColorRef          defaultFillColor;
    NSInteger           fillColorsCount;
    NSInteger           fillColorIndex;
    CGColorRef          fillColors[kLSMaxColors];
    BOOL                randomize;
    CGFloat             randomness;
} ;
typedef struct MBSegmentStruct MBSegmentStruct;
typedef MBSegmentStruct* MBSegmentRef;


/*!
 A fractal path segment.
 */
@interface MBFractalSegment : NSObject {
    CGMutablePathRef    _path;
}

@property (nonatomic, assign) CGMutablePathRef      path;

@property (nonatomic,assign) CGFloat                 turningAngle;
@property (nonatomic,assign) CGFloat                 turningAngleIncrement;
@property (nonatomic,assign) CGFloat                 lineLength;
@property (nonatomic,assign) CGFloat                 lineWidth;
@property (nonatomic,assign) CGFloat                 lineWidthIncrement;
@property (nonatomic,assign) CGFloat                 lineLengthScaleFactor;
@property (nonatomic,assign) CGFloat                 lineChangeFactor;
@property (nonatomic,assign) BOOL                   randomize;
@property (nonatomic,assign) CGFloat                 randomness;
@property (nonatomic,assign) BOOL                   fill;
@property (nonatomic,assign) BOOL                   stroke;
@property (nonatomic,assign) CGLineCap              lineCap;
@property (nonatomic,assign) CGLineJoin             lineJoin;

@property (nonatomic,assign) NSInteger              lineColorIndex;
@property (nonatomic,assign) NSInteger              fillColorIndex;

@property (nonatomic,assign) CGAffineTransform      transform;

+(NSArray*)settingsToCopy;
+(CGFloat)randomDoubleBetween:(CGFloat)smallNumber and:(CGFloat)bigNumber;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) MBFractalSegment *copySettings;

-(CGFloat) randomScalar;

@end
