//
//  MBCollectionFractalCell.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBCollectionFractalCell.h"
#import <QuartzCore/QuartzCore.h>


@implementation MBCollectionFractalCell

-(void) setImageFrame:(UIView *)imageFrame {
    if (_imageFrame != imageFrame) {
        _imageFrame = imageFrame;
        _imageFrame.layer.shadowOpacity = 0.5;
        _imageFrame.layer.shadowOffset = CGSizeMake(0, 3.0);
    }
}

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
        //
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
