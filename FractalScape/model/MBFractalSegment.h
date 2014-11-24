//
//  MBFractalSegment.h
//  FractalScape
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/*!
 A fractal path segment.
 */
@interface MBFractalSegment : NSObject {
    CGMutablePathRef    _path;
}

@property (nonatomic, assign) CGMutablePathRef      path;

@property (nonatomic,assign) double                 turningAngle;
@property (nonatomic,assign) double                 turningAngleIncrement;
@property (nonatomic,assign) double                 lineLength;
@property (nonatomic,assign) double                 lineWidth;
@property (nonatomic,assign) double                 lineWidthIncrement;
@property (nonatomic,assign) double                 lineLengthScaleFactor;
@property (nonatomic,assign) double                 lineChangeFactor;
@property (nonatomic,assign) BOOL                   randomize;
@property (nonatomic,assign) double                 randomness;
@property (nonatomic,assign) BOOL                   fill;
@property (nonatomic,assign) BOOL                   stroke;
@property (nonatomic,assign) CGLineCap              lineCap;
@property (nonatomic,assign) CGLineJoin             lineJoin;

@property (nonatomic,assign) NSInteger              lineColorIndex;
@property (nonatomic,assign) NSInteger              fillColorIndex;

@property (nonatomic,assign) CGAffineTransform      transform;

+(NSArray*)settingsToCopy;
+(double)randomDoubleBetween:(double)smallNumber and:(double)bigNumber;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) MBFractalSegment *copySettings;

-(double) randomScalar;

@end
