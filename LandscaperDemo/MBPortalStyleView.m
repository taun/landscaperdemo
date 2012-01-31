//
//  MBPortalStyleView.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/30/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBPortalStyleView.h"
#import <QuartzCore/QuartzCore.h>

@interface MBPortalStyleView ()

-(void) setupStyle;

@end

@implementation MBPortalStyleView

-(void) setupStyle {
    self.layer.frame = CGRectInset(self.layer.frame, 5.0, 5.0);
    self.layer.cornerRadius = 20.0;
    self.layer.borderWidth = 4.0;
    self.layer.borderColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), (CGFloat[]){ 0.0, 0.5, 1.0, 1.0 });
    [self.layer needsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupStyle];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupStyle];
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
