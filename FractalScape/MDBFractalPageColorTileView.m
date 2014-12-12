//
//  MDBFractalPageColorTileView.m
//  FractalScape
//
//  Created by Taun Chapman on 12/10/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalPageColorTileView.h"


@interface MDBFractalPageColorTileView ()

@property (nonatomic,strong) MDBLSObjectTileView             *backgroundColorView;
@property (nonatomic,strong) UIImageView                        *pageTemplateView;

@property (nonatomic,assign) CGRect                         lastBounds;

-(void) updateColor: (MBColor*) newColor;

@end

@implementation MDBFractalPageColorTileView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupDefaults];
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaults];
        [self setupSubviews];
    }
    return self;
}

-(void) setupDefaults {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    //    self.contentMode = UIViewContentModeRedraw;
    
    _tileWidth = 26.0;
}
-(void) setupSubviews {
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }
    
    CGRect pageTemplateRect = CGRectMake(0, 0, _tileWidth, _tileWidth);
    _pageTemplateView = [[UIImageView alloc] initWithFrame: pageTemplateRect];
#if TARGET_INTERFACE_BUILDER
    _pageTemplateView.image = [FractalScapeIconSet imageOfTabBarPageColorIcon];
#else
    _pageTemplateView.image = [[UIImage imageNamed: @"tabBarPageColorIcon"] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
#endif
    _pageTemplateView.tintColor = self.tintColor;
    [_pageTemplateView setTranslatesAutoresizingMaskIntoConstraints: NO];
    [_pageTemplateView addConstraint: [NSLayoutConstraint constraintWithItem: _pageTemplateView
                                                                   attribute: NSLayoutAttributeHeight
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: nil
                                                                   attribute: NSLayoutAttributeNotAnAttribute
                                                                  multiplier: 1.0 constant: 25.0]];
    [_pageTemplateView addConstraint: [NSLayoutConstraint constraintWithItem: _pageTemplateView
                                                                   attribute: NSLayoutAttributeWidth
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: nil
                                                                   attribute: NSLayoutAttributeNotAnAttribute
                                                                  multiplier: 1.0 constant: 25.0]];
    
    
    [self addSubview: _pageTemplateView];
    
    _backgroundColorView = [[MDBLSObjectTileView alloc] initWithFrame: CGRectMake(0, 0, _tileWidth, _tileWidth)];
    _backgroundColorView.showTileBorder = YES;
    _backgroundColorView.width = _tileWidth;
    _backgroundColorView.tileCornerRadius = _tileCornerRadius;
    // Never remove rule unless it is being replaced by another.
    _backgroundColorView.replaceable = YES;
    _backgroundColorView.readOnly = YES;
    
#if !TARGET_INTERFACE_BUILDER
    _backgroundColorView.representedObject = self.fractal.backgroundColor;
#endif
    
    
    [self addSubview: _backgroundColorView];
}

-(void) updateConstraints {
//    [self removeConstraints: self.constraints];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem: _pageTemplateView
                                                      attribute: NSLayoutAttributeTop
                                                      relatedBy: NSLayoutRelationEqual
                                                         toItem: self
                                                      attribute: NSLayoutAttributeTop
                                                     multiplier: 1.0 constant: 14]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem: _backgroundColorView
                                                      attribute: NSLayoutAttributeBottom
                                                      relatedBy: NSLayoutRelationEqual
                                                         toItem: self
                                                      attribute: NSLayoutAttributeBottom
                                                     multiplier: 1.0 constant: -14]];

    [self addConstraint: [NSLayoutConstraint constraintWithItem: _pageTemplateView
                                                      attribute: NSLayoutAttributeCenterX
                                                      relatedBy: NSLayoutRelationEqual
                                                         toItem: self
                                                      attribute: NSLayoutAttributeCenterX
                                                     multiplier: 1.0 constant: 0]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem: _backgroundColorView
                                                      attribute: NSLayoutAttributeCenterX
                                                      relatedBy: NSLayoutRelationEqual
                                                         toItem: self
                                                      attribute: NSLayoutAttributeCenterX
                                                     multiplier: 1.0 constant: 0]];
    
    [super updateConstraints];
}
-(void) layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, self.lastBounds)) {
        //
        [self setNeedsUpdateConstraints];
    }
    
}
-(void) setFractal:(LSFractal *)fractal {
    if (_fractal != fractal) {
        _fractal = fractal;
        self.backgroundColorView.representedObject = self.fractal.backgroundColor;
    }
}

-(void) updateColor:(id<MDBTileObjectProtocol>)color {
    if ([color isKindOfClass: [MBColor class]]) {
        self.fractal.backgroundColor = color;
    }
    self.backgroundColorView.representedObject = color;
}

-(void) setTileWidth:(CGFloat)tileWidth {
    _tileWidth = tileWidth;
    _backgroundColorView.width = _tileWidth;
    
    [self setNeedsUpdateConstraints];
}

-(void) setShowTileBorder:(BOOL)showTileBorder {
    _showTileBorder = showTileBorder;
    //    _ruleView.showTileBorder = _showTileBorder;
    _backgroundColorView.showTileBorder = _showTileBorder;
    
}
-(void) setShowOutline:(BOOL)showOutline {
    _showOutline = showOutline;
    
    if (_showOutline) {
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 6.0;
        self.layer.borderColor = [FractalScapeIconSet groupBorderColor].CGColor;
    } else {
        self.layer.borderWidth = 0.0;
    }
}

#pragma mark - Drag&Drop Implementation Details
-(BOOL) pointIsInContext: (CGPoint) aPoint {
    CGPoint localPoint = [self convertPoint: aPoint toView: self.backgroundColorView];
    BOOL pointInside = [self.backgroundColorView pointInside: localPoint withEvent: nil];
    return pointInside;
}

#pragma mark - Drag&Drop
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    UIView* dragView;
    
    if ([self pointIsInContext: point]) {
        //
    }
    
    return dragView;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    if ([self pointIsInContext: point]) {
        //
    }
    
    return needsLayout;
}
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    if ([self pointIsInContext: point]) {
        //
        if (draggingRule.dragItem != self.backgroundColorView.representedObject) {
            draggingRule.oldReplacedDragItem = self.backgroundColorView.representedObject;
            [self updateColor: draggingRule.dragItem];
        }
    }
    
    return needsLayout;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    id<MDBTileObjectProtocol> color = draggingItem.oldReplacedDragItem;
    if (color && !color.isReferenced) {
        draggingItem.oldReplacedDragItem = nil;
        if ([color isKindOfClass: [NSManagedObject class]]) {
            [((NSManagedObject*)color).managedObjectContext deleteObject: color];
        }
    }
    
    return needsLayout;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    if (draggingItem.dragItem == self.backgroundColorView.representedObject) {
        [self updateColor: draggingItem.oldReplacedDragItem];
    }
    
    return needsLayout;
}

@end
