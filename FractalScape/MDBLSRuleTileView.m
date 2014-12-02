//
//  MDBLSRuleTileView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MDBLSRuleTileView.h"

#import "FractalScapeIconSet.h"


@implementation MDBLSRuleTileView


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

    _tileCornerRadius = 4.0;
    _width = 52;

    if (_rule == nil) {
        UIImage* cellImage = [FractalScapeIconSet imageOfKBIconRulePlaceEmpty];
        self.image = cellImage;
        [self sizeToFit];
        [self setNeedsUpdateConstraints];
    }
    
    UIView* backgroundView = [[UIView alloc] initWithFrame: CGRectZero];
    
    backgroundView.layer.masksToBounds = NO;
    backgroundView.layer.cornerRadius = _tileCornerRadius;
    backgroundView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent: 0.15];
    
//    self.selectedBackgroundView = backgroundView;

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
-(void) setShowTileBorder:(BOOL)showTileBorder {
    _showTileBorder = showTileBorder;
    [self refreshAppearance];
}
-(id) item {
    return self.rule;
}
-(void) refreshAppearance {
    self.layer.borderColor = self.tintColor.CGColor;
    self.layer.borderWidth = _showTileBorder ? 1.0 : 0.0;
    self.layer.cornerRadius = _tileCornerRadius;
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

#pragma mark - Drag&Drop
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    
    if (self.readOnly) {
        LSDrawingRule* newRule = [self.rule mutableCopy];
        draggingItem.dragItem = newRule;
    } else {
        draggingItem.dragItem = self.rule;
    }

    return draggingItem.view;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    return needsLayout;
}

@end
