//
//  MBCollectionFractalSupplementaryLabel.m
//  LandscaperDemo
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

    NSArray* glossColors = [NSArray arrayWithObjects:
                            (id)glossTop.CGColor,
                            (id)glossBottom.CGColor,
                            (id)glossBottom.CGColor,
                            (id)lighterShadowColor.CGColor, nil];
    NSArray* glossLocations = [NSArray arrayWithObjects: @0, @0.58, @0.93, @1, nil];

    [(CAGradientLayer *)self.layer setColors: glossColors];
    [(CAGradientLayer *)self.layer setLocations: glossLocations];
    self.layer.shadowOpacity = 0.4;
    self.layer.shadowOffset = CGSizeMake(0.0, 3.0);
    self.layer.shadowRadius = 4;
    self.layer.masksToBounds = NO;
    self.layer.borderColor = self.backgroundColor.CGColor;
    self.layer.borderWidth = 1.0;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}
-(id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initGradient];
    }
    return self;
}
-(void)awakeFromNib {
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
