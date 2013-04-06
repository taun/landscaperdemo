//
//  MBLSFractalLevelNView.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/10/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalLevelNView.h"
#import "MBPortalStyleView.h"

#import <QuartzCore/QuartzCore.h>

@implementation MBLSFractalLevelNView

@synthesize fractalView = _fractalView, sliderContainerView = _sliderContainerView;
@synthesize hudViewBackground = _hudViewBackground;

@synthesize slider = _slider;
@synthesize hudLabel = _hudLabel, hudText1 = _hudText1, hudText2 = _hudText2;

-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo {
    CFDictionaryRef boundsDict = CGRectCreateDictionaryRepresentation(bounds);
    NSString* boundsDescription = [(__bridge NSString*)boundsDict description];
    CFRelease(boundsDict);
    
    NSLog(@"%@ = %@", boundsInfo,boundsDescription);
}


#pragma mark - Getters and setters

-(void) setFractalView:(UIView *)fractalView {
    _fractalView = fractalView;
    UIRotationGestureRecognizer* rgr = [[UIRotationGestureRecognizer alloc] 
                                        initWithTarget: self 
                                        action: @selector(rotateFractal:)];
    
    [_fractalView addGestureRecognizer: rgr];
    
    UILongPressGestureRecognizer* lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget: self
                                          action: @selector(magnifyFractal:)];
    
    [_fractalView addGestureRecognizer: lpgr];
}

-(void) setHudViewBackground: (UIView*) hudViewBackground {
    _hudViewBackground = hudViewBackground;
    
    CALayer* background = _hudViewBackground.layer; 
    
    background.cornerRadius = HUD_CORNER_RADIUS;
    background.borderWidth = 1.6;
    background.borderColor = [UIColor grayColor].CGColor;
    
    background.shadowOffset = CGSizeMake(0, 3.0);
    background.shadowOpacity = 0.6;
}



-(void) setupStyle {
//    [[NSBundle mainBundle] loadNibNamed:@"MBLSFractalLevelNView" owner:self options:nil];

    CGAffineTransform rotateCC = CGAffineTransformMakeRotation(-M_PI_2);
    [self.sliderContainerView setTransform: rotateCC];
}

- (void) awakeFromNib {
    [self setupStyle];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
//        [self setupStyle];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
//        [self setupStyle];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
