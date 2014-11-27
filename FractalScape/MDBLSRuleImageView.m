//
//  MDBLSRuleImageView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MDBLSRuleImageView.h"

#import "FractalScapeIconSet.h"


@implementation MDBLSRuleImageView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupDefaults];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

-(void) setupDefaults {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.contentMode = UIViewContentModeScaleAspectFit;
    self.userInteractionEnabled = YES;

    _cornerRadius = 4.0;
    _width = 52;

    if (_rule == nil) {
        UIImage* cellImage = [FractalScapeIconSet imageOfKBIconRulePlaceEmpty];
        self.image = cellImage;
        [self sizeToFit];
        [self setNeedsUpdateConstraints];
    }
}

-(void) setRule:(LSDrawingRule *)rule {
    _rule = rule;
    self.image = [rule asImage];
    [self sizeToFit];
    [self setNeedsUpdateConstraints];
}
-(void) setWidth:(CGFloat)width {
    if (width == 0) {
        width = 52.0;
    }
    _width = width;
    [self setNeedsUpdateConstraints];
}
-(void) setShowBorder:(BOOL)showBorder {
    _showBorder = showBorder;
    [self refreshAppearance];
}

-(void) refreshAppearance {
    self.layer.borderColor = self.tintColor.CGColor;
    self.layer.borderWidth = _showBorder ? 1.0 : 0.0;
    self.layer.cornerRadius = _cornerRadius;
    [self setNeedsDisplay];
}

-(void) updateConstraints {
    [self removeConstraints: self.constraints];
    
    
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(self);
    NSDictionary* metricsDictionary = @{@"width":@(_width)};
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[self(width)]" options:0 metrics: metricsDictionary views: viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[self(width)]" options:0 metrics: metricsDictionary views: viewsDictionary]];
    
    
    [super updateConstraints];
}

@end
