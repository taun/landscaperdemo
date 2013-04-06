//
//  MBImmutableCellBackgroundView.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/28/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBImmutableCellBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MBImmutableCellBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.readOnlyView = NO;
        CALayer* temp = [CALayer layer];
        [self.layer addSublayer: temp];
        _outlineLayer = temp;
        _outlineLayer.frame = CGRectInset(frame, -6.0, -6.0);
        _outlineLayer.borderWidth = 3.0;
        _outlineLayer.cornerRadius = 6.0;
        _outlineLayer.zPosition = 300.0;
    }
    return self;
}

-(void) setReadOnlyView:(BOOL)readOnlyView {
    _readOnlyView = readOnlyView;
    UIColor* border = [UIColor clearColor];
    if (_readOnlyView) {
        border = [UIColor redColor];
    }
    
    CGColorRef colorCopy = CGColorCreateCopy(border.CGColor);
    self.outlineLayer.borderColor = colorCopy;
    CGColorRelease(colorCopy);
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
