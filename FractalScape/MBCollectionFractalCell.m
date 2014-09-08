//
//  MBCollectionFractalCell.m
//  FractalScape
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

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self fixConstraints];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        //
        [self fixConstraints];
    }
    return self;
}

/*!
 Seems to be a bug in iOS 8 beta#?
 Cannont add constraints to the contentView using IB so we do it manually.
 */
-(void) fixConstraints {
    
    NSMutableArray* constraints = [[NSMutableArray alloc] init];
    
    [constraints addObject: [NSLayoutConstraint
                             constraintWithItem: self
                             attribute: NSLayoutAttributeHeight
                             relatedBy:NSLayoutRelationEqual
                             toItem: nil
                             attribute: 0
                             multiplier: 1.0
                             constant: 262.0]];
    [constraints addObject: [NSLayoutConstraint
                             constraintWithItem: self
                             attribute: NSLayoutAttributeWidth
                             relatedBy:NSLayoutRelationEqual
                             toItem: nil
                             attribute: 0
                             multiplier: 1.0
                             constant: 154.]];
    
    [self addConstraints: constraints];
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
