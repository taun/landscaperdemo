//
//  MBFractalLayer.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/09/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class MBLSFractal;

/*!
 Default anchorPoint is set to (0, 1), lower left corner
 */
@interface MBFractalLayer : CALayer

@property (nonatomic, strong) MBLSFractal* fractal;

@end
