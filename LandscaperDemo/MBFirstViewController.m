//
//  MBFirstViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MBFirstViewController.h"
#import "FractalPadView.h"
#import "MBIFSFractal.h"
#import "MBFractalLayer.h"

#import <QuartzCore/QuartzCore.h>

#include "Model/QuartzHelpers.h"

#include <math.h>


@implementation MBFirstViewController

@synthesize MainFractalView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

-(MBIFSFractal*) newVonKochSnowFlake {
    CGColorRef lineColor = CreateDeviceRGBColor(0.0f, 0.3f, 1.0f, 1.0f);
    
    MBIFSFractal* fractal = [[MBIFSFractal alloc] init];
    fractal.lineColor = lineColor;
    fractal.lineWidth = 2.0f;
    CGColorRelease(lineColor);
    
    fractal.axiom = @"F";
    double angle = M_PI/(3.0f);
    [fractal addProductionRuleReplaceString: @"F" withString: @"F-F++F-F"];
    [fractal addProductionRuleReplaceString: @"+" withString: @"+"];
    [fractal addProductionRuleReplaceString: @"-" withString: @"-"];
    [fractal addDrawingRuleString: @"F" executesSelector: @"drawLine:" withArgument: [NSNumber numberWithDouble: 10.0f]];
    [fractal addDrawingRuleString: @"+" executesSelector: @"rotate:" withArgument: [NSNumber numberWithDouble: angle]];
    [fractal addDrawingRuleString: @"-" executesSelector: @"rotate:" withArgument: [NSNumber numberWithDouble: -angle]];
    fractal.levels = 0;
//    if (MainFractalView.layer.contentsAreFlipped) {
//        fractal.currentTransform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
//    }
    return fractal;
}

-(MBIFSFractal*) newVonKochIsland {
    CGColorRef lineColor = CreateDeviceRGBColor(0.0f, 0.3f, 1.0f, 1.0f);
    
    MBIFSFractal* fractal = [[MBIFSFractal alloc] init];
    fractal.lineColor = lineColor;
    fractal.lineWidth = 2.0f;
    CGColorRelease(lineColor);
    
    fractal.axiom = @"F+F+F+F";
    double angle = M_PI/(2.0f);
    [fractal addProductionRuleReplaceString: @"F" withString: @"F+F-F-FF+F+F-F"];
    [fractal addProductionRuleReplaceString: @"+" withString: @"+"];
    [fractal addProductionRuleReplaceString: @"-" withString: @"-"];
    [fractal addDrawingRuleString: @"F" executesSelector: @"drawLine:" withArgument: [NSNumber numberWithDouble: 20.0f]];
    [fractal addDrawingRuleString: @"+" executesSelector: @"rotate:" withArgument: [NSNumber numberWithDouble: angle]];
    [fractal addDrawingRuleString: @"-" executesSelector: @"rotate:" withArgument: [NSNumber numberWithDouble: -angle]];
    fractal.levels = 0;
    return fractal;
}

-(void) addVonKochSnowFlakeLayerPosition: (CGPoint) position  maxDimension: (double) size {
    // It is important to create the fractal before the layer so the layer bounds aspect can use the fractal bounds
    // It is assumed fractal bounds aspect will not change significantly with varying levels]
    // A different axiom or rules is a different fractal and probably requires a new layer.
    
    // create the fractal
    MBIFSFractal* fractal = [self newVonKochSnowFlake];
    fractal.levels = 4;
    fractal.fill = NO;
    [fractal generateProduct];
    [fractal generatePaths];

    
    // create a fractal layer
    MBFractalLayer* fractalLayer = [[MBFractalLayer alloc] init];
    
    // anchorPoint traditional lower left corner
    //    fractalLayer.anchorPoint = CGPointMake(0.0f, 1.0f);    
    // position based on lower left corner
    fractalLayer.position = position;
    
    CGSize unitBox = [fractal unitBox];
    fractalLayer.bounds = CGRectMake(0.0f, 0.0f, unitBox.width*size, unitBox.height*size);
    fractalLayer.borderWidth = 0.0;
    fractalLayer.masksToBounds = NO;
    
    fractalLayer.fractal = fractal;
    
    [MainFractalView.layer addSublayer: fractalLayer];
    [fractalLayer setNeedsDisplay];
}

/*
 position is bottom left corner
 */
-(void) addVonKochIslandLayerPosition: (CGPoint) position maxDimension: (double) size {
    
    CGColorRef fillColor = CreateDeviceRGBColor(0.0f, 0.8f, 1.0f, 0.8f);
    CGColorRef lineColor = CreateDeviceRGBColor(1.0f, 0.8f, 0.0f, 1.0f);

    // create the fractal
    MBIFSFractal* fractal = [self newVonKochIsland];
    fractal.levels = 2;
    fractal.stroke = YES;
    fractal.lineColor = lineColor;
    CGColorRelease(lineColor);
    fractal.fill = YES;
    fractal.fillColor = fillColor;
    CGColorRelease(fillColor);
    [fractal generateProduct];
    [fractal generatePaths];
    
    
    // create a fractal layer
    MBFractalLayer* fractalLayer = [[MBFractalLayer alloc] init];
    
    // anchorPoint traditional lower left corner
    //    fractalLayer.anchorPoint = CGPointMake(0.0f, 1.0f);    
    // position based on lower left corner
    fractalLayer.position = position;
    
    CGSize unitBox = [fractal unitBox];
    fractalLayer.bounds = CGRectMake(0.0f, 0.0f, unitBox.width*size, unitBox.height*size);

    fractalLayer.fractal = fractal;
    
    [MainFractalView.layer addSublayer: fractalLayer];
    [fractalLayer setNeedsDisplay];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [MainFractalView setNeedsDisplay];
    [MainFractalView.layer setNeedsDisplay];
    
    [self addVonKochSnowFlakeLayerPosition: CGPointMake(50, 50) maxDimension: 300];
    [self addVonKochIslandLayerPosition: CGPointMake(75, 250) maxDimension: 300];
}

- (void)viewDidUnload
{
    [self setMainFractalView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
