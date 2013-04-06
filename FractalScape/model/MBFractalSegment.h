//
//  MBFractalSegment.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface MBFractalSegment : NSObject {
    CGMutablePathRef    _path;
    CGColorRef          _lineColor;
    CGColorRef          _fillColor;
}

@property (nonatomic, assign) CGMutablePathRef      path;

@property (nonatomic,assign) double                 turningAngle;
@property (nonatomic,assign) double                 turningAngleIncrement;
@property (nonatomic,assign) double                 lineLength;
@property (nonatomic,assign) double                 lineWidth;
@property (nonatomic,assign) double                 lineWidthIncrement;
@property (nonatomic,assign) double                 lineLengthScaleFactor;
@property (nonatomic,assign) double                 randomness;
@property (nonatomic,assign) CGColorRef             lineColor;
@property (nonatomic,assign) CGColorRef             fillColor;
@property (nonatomic, readwrite) BOOL               fill;
@property (nonatomic, readwrite) BOOL               stroke;

@property (nonatomic,assign) CGAffineTransform      transform;

+(NSArray*)settingsToCopy;

-(MBFractalSegment*) copySettings;

@end
