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
@property (nonatomic, assign) double         lineWidth;
@property (nonatomic, assign) CGColorRef     lineColor;
@property (nonatomic, assign) CGColorRef     fillColor;
@property (nonatomic, readwrite) BOOL        fill;
@property (nonatomic, readwrite) BOOL        stroke;

@property (nonatomic,assign) CGAffineTransform      transform;


-(MBFractalSegment*) copySettings;

@end
