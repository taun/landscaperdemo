//
//  MBColorCellBackgroundView.m
//  FractalScape
//
//  Created by Taun Chapman on 03/19/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBColorCellBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MBColorCellBackgroundView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.layer.cornerRadius = 5.0;
        self.layer.masksToBounds = NO;
        UIColor* border = [UIColor clearColor];
        CGColorRef colorCopy = CGColorCreateCopy(border.CGColor);
        self.layer.borderColor = colorCopy;
        CGColorRelease(colorCopy);
        self.layer.borderWidth = 1.0;
        
        if ((YES)) {
            self.layer.shadowOpacity = 0.5;
            self.layer.shadowRadius = 2.0;
            self.layer.shadowOffset = CGSizeMake(0,2);
        }
        
        self.layer.backgroundColor = [[UIColor whiteColor] CGColor];
    }
    return self;
}

//- (void)drawRect:(CGRect)rect
//{
//    // draw a rounded rect bezier path filled with blue
//    CGContextRef aRef = UIGraphicsGetCurrentContext();
//    CGContextSaveGState(aRef);
//    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:5.0f];
//    [bezierPath setLineWidth:1.0f];
//    [[UIColor blackColor] setStroke];
//    
//    UIColor *fillColor = [UIColor lightGrayColor]; // color equivalent is #87ceeb
//    [fillColor setFill];
//    
//    [bezierPath stroke];
//    [bezierPath fill];
//    CGContextRestoreGState(aRef);
//}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
