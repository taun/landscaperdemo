//
//  MDBLSRuleTileView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MDBLSObjectTileView.h"



@implementation MDBLSObjectTileView


- (instancetype)initWithFrame:(CGRect)frame {
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

    if (_representedObject == nil) {
        self.representedObject = [MDBTileObjectProxy new];
    }
    
    UIView* backgroundView = [[UIView alloc] initWithFrame: CGRectZero];
    
    backgroundView.layer.masksToBounds = NO;
    backgroundView.layer.cornerRadius = _tileCornerRadius;
    backgroundView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent: 0.15];
    
//    self.selectedBackgroundView = backgroundView;

}

-(void) setRepresentedObject:(id<MDBTileObjectProtocol>)object {
    if (object == nil) {
        _representedObject = [MDBTileObjectProxy new];
    } else {
        _representedObject = object;
    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        //
        self.image = [object asImage];
        [self sizeToFit];
        [self setNeedsUpdateConstraints];
//    });
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
    return self.representedObject;
}
-(void) refreshAppearance {
    self.layer.borderColor = self.tintColor.CGColor;
    self.layer.borderWidth = _showTileBorder ? 1.0 : 0.0;
    self.layer.cornerRadius = _tileCornerRadius;
    self.layer.masksToBounds = YES;
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

-(void)startBlinkOutline
{
    CGFloat hue, sat, bright, alpha;
    [self.tintColor getHue: &hue saturation: &sat brightness: &bright alpha: &alpha];
    UIColor* newBackground = [UIColor colorWithHue: hue saturation: sat brightness: bright alpha: alpha/5.0];
    
    [UIView animateWithDuration: 3.0 delay: 0.0
         usingSpringWithDamping: 0.4
          initialSpringVelocity: 0.0
                        options: UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         //
                         self.alpha = 0.6;
                         self.backgroundColor = newBackground;
                     } completion:^(BOOL finished) {
                         //
                     }];
}
-(void)endBlinkOutline
{
    self.backgroundColor = [UIColor clearColor];
    self.alpha = 1.0;
//    self.image = [_representedObject asImage];
}

#pragma mark - Drag&Drop
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    
    if (self.readOnly) {
        id<MDBTileObjectProtocol> newObject = [self.representedObject copy];
        draggingItem.dragItem = newObject;
    } else {
        draggingItem.dragItem = self.representedObject;
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
