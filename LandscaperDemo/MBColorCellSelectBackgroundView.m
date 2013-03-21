//
//  MBColorCellSelectBackgroundView.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/19/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBColorCellSelectBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MBColorCellSelectBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.layer.cornerRadius = 8.0;
        self.layer.masksToBounds = NO;
        UIColor* border = [UIColor grayColor];
        CGColorRef colorCopy = CGColorCreateCopy(border.CGColor);
        self.layer.borderColor = colorCopy;
        CGColorRelease(colorCopy);
        self.layer.borderWidth = 1.0;
        self.layer.shadowOpacity = 0.9;
        self.layer.shadowRadius = 2;
        self.layer.shadowOffset = CGSizeMake(2,2);
        self.layer.shadowColor = [[UIColor whiteColor] CGColor];
        self.layer.backgroundColor = [[UIColor darkGrayColor] CGColor];
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
