//
//  MBCollectionFractalSupplementaryLabel.m
//  FractalScape
//
//  Created by Taun Chapman on 02/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBCollectionFractalSupplementaryLabel.h"
#import <QuartzCore/QuartzCore.h>

@implementation MBCollectionFractalSupplementaryLabel

+ (Class)layerClass {
    
    return [CAGradientLayer class];
}

-(void) initGradient {
    // Set the colors for the gradient layer.

    UIColor* lighterShadowColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.506];
    UIColor* glossBottom = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.117];
    UIColor* glossTop = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.664];

    NSArray* glossColors = @[(id)glossTop.CGColor,
                            (id)glossBottom.CGColor,
                            (id)glossBottom.CGColor,
                            (id)lighterShadowColor.CGColor];
    NSArray* glossLocations = @[@0, @0.58, @0.93, @1];

    [(CAGradientLayer *)self.layer setColors: glossColors];
    [(CAGradientLayer *)self.layer setLocations: glossLocations];
    self.layer.shadowOpacity = 0.4;
    self.layer.shadowOffset = CGSizeMake(0.0, 3.0);
    self.layer.shadowRadius = 4;
    self.layer.masksToBounds = NO;
    self.layer.borderColor = self.backgroundColor.CGColor;
    self.layer.borderWidth = 1.0;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}
-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        if ((NO)) {
            [self initGradient];
        }
        [self fixConstraints];
    }
    return self;
}
-(void)awakeFromNib {
    [super awakeFromNib];
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
                             relatedBy:NSLayoutRelationGreaterThanOrEqual
                             toItem: nil
                             attribute: 0
                             multiplier: 1.0
                             constant: 44.0]];
    
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
