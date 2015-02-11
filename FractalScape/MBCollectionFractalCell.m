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


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self configureDefaults];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        //
        [self configureDefaults];
    }
    return self;
}
-(void) configureDefaults {
    
//    [self fixConstraints];

    _radius = 5.0;
    
    UIImage* placeholder = [UIImage imageNamed: @"kBIconRulePlaceEmpty"];
    UIImageView* strongImageView = self.imageView;
    strongImageView.image = placeholder;
    
    self.selectedBackgroundView = [self configureSelectedBackgroundViewFrame: CGRectZero];
}
-(UIView*) configureSelectedBackgroundViewFrame: (CGRect) frame {
    UIView *selectBackgroundView = [[UIView alloc] initWithFrame: frame];
    selectBackgroundView.layer.cornerRadius = self.radius;
    selectBackgroundView.layer.masksToBounds = NO;
    UIColor* border = [UIColor grayColor];
    CGColorRef colorCopy = CGColorCreateCopy(border.CGColor);
    selectBackgroundView.layer.borderColor = colorCopy;
    CGColorRelease(colorCopy);
    selectBackgroundView.layer.borderWidth = 0.0;
//    selectBackgroundView.layer.shadowOpacity = 0.9;
//    selectBackgroundView.layer.shadowRadius = 2;
//    selectBackgroundView.layer.shadowOffset = CGSizeMake(2,2);
//    selectBackgroundView.layer.shadowColor = [[UIColor whiteColor] CGColor];
    selectBackgroundView.layer.backgroundColor = [[UIColor darkGrayColor] CGColor];
    return selectBackgroundView;
}

-(void) setImageFrame:(UIView *)imageFrame {
    if (_imageFrame != imageFrame) {
//        imageFrame.layer.shadowOpacity = 0.5;
//        imageFrame.layer.shadowOffset = CGSizeMake(0, 3.0);
        _imageFrame = imageFrame;
    }
}

/*!
 Seems to be a bug in iOS 8 beta#?
 Cannont add constraints to the contentView using IB so we do it manually.
 */
//-(void) fixConstraints {
//    
//    NSMutableArray* constraints = [[NSMutableArray alloc] init];
//    
//    [constraints addObject: [NSLayoutConstraint
//                             constraintWithItem: self
//                             attribute: NSLayoutAttributeHeight
//                             relatedBy:NSLayoutRelationEqual
//                             toItem: nil
//                             attribute: 0
//                             multiplier: 1.0
//                             constant: 262.0]];
//    [constraints addObject: [NSLayoutConstraint
//                             constraintWithItem: self
//                             attribute: NSLayoutAttributeWidth
//                             relatedBy:NSLayoutRelationEqual
//                             toItem: nil
//                             attribute: 0
//                             multiplier: 1.0
//                             constant: 154.]];
//    
//    [self addConstraints: constraints];
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
