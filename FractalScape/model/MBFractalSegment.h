//
//  MBFractalSegment.h
//  FractalScape
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

struct MBSegmentStruct {
    CGContextRef        context;
    CGPoint             lastPoint;
    CGPathDrawingMode   mode;
    CGAffineTransform   transform;
    CGFloat             turningAngle;
    CGFloat             turningAngleIncrement;
    BOOL                stroke;
    CGLineCap           lineCap;
    CGLineJoin          lineJoin;
    NSInteger           lineColorIndex;
    CGFloat             lineLength;
    CGFloat             lineWidth;
    CGFloat             lineWidthIncrement;
    CGFloat             lineLengthScaleFactor;
    CGFloat             lineChangeFactor;
    BOOL                fill;
    BOOL                EOFill;
    NSInteger           fillColorIndex;
    BOOL                randomize;
    CGFloat             randomness;
} ;
typedef struct MBSegmentStruct MBSegmentStruct;


struct MBSegmentStackStruct {
    NSUInteger          stackIndex;
    MBSegmentStruct     segmentStack[20];
};
typedef struct MBSegmentStackStruct MBSegmentStackStruct;

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
