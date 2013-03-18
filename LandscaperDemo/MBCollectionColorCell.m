//
//  MBCollectionColorCell.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/18/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBCollectionColorCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation MBCollectionColorCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        // Initialization code
        self.layer.cornerRadius = 5.0;
        self.layer.masksToBounds = YES;
        UIColor* border = [UIColor lightGrayColor];
        CGColorRef colorCopy = CGColorCreateCopy(border.CGColor);
        self.layer.borderColor = colorCopy;
        CGColorRelease(colorCopy);
        self.layer.borderWidth = 1.0;
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
