//
//  LSFractalGenerator.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/19/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LSFractal;

/*!
 Takes an LSFractal definition given to it from core data and generates the production string and core graphics path.
 
 Need an LSFractal controller which intermediates between view and model.
 Gets context from view and segments from LSFractalGenerator?
 */
@interface LSFractalGenerator : NSObject

@property (nonatomic, strong) LSFractal*        fractal;

/*!
 Overrides the fractal level in order to allow multiple views of the same fractal with different generation levels.
 */
@property (nonatomic, assign) double            forceLevel;

@property (nonatomic,assign,readonly) CGRect    bounds;


/*
 The drawing rules are cached from the managed object. This is because the rules are returned as a set and we need to convert them to a dictionary. We only want to do this once unless the rules are changed. Need to observer the rules and if there is a change, clear the cache.
 */
-(void) clearCache;

-(void) productionRuleChanged;

-(void) appearanceChanged;

/*!
 Height/Width aspect ratio.
 */
-(double) aspectRatio;

/*!
 Returns the width and height of maximum close fitting dimension of the fractal which will fit in a 1x1 box.
 */
-(CGSize) unitBox;

/*!
 Use to flip or rotate the fractal before generating the path.
 */
-(void) setInitialTransform: (CGAffineTransform) transform;

#pragma mark - layer delegate
- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext;

@end
