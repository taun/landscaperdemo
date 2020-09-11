//
//  MBLSReplacementRuleTileView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSReplacementRuleTileView.h"
#import "MDBLSObjectTileView.h"
#import "MDBTileObjectProtocol.h"

#import "FractalScapeIconSet.h"

@interface MBLSReplacementRuleTileView ()

@property (nonatomic,strong) MDBLSObjectTileView             *ruleView;
@property (nonatomic,strong) UILabel                        *separator;
@property (nonatomic,strong) MBLSObjectListTileViewer        *replacementsView;
@property (nonatomic,assign) CGRect                         lastBounds;

-(void) updateRuleViewRule: (LSDrawingRule*) rule;

@end

@implementation MBLSReplacementRuleTileView


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
    _tileMargin = 2.0;
    
}
-(void) setupSubviews {
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }
    

//    self.backgroundColor = [UIColor whiteColor];
    
    _ruleView = [[MDBLSObjectTileView alloc] initWithFrame: CGRectMake(0, 0, _tileWidth, _tileWidth)];
    _ruleView.showTileBorder = YES;
    _ruleView.width = _tileWidth;
    // Never remove rule unless it is being replaced by another.
    _ruleView.replaceable = YES;
    _ruleView.readOnly = YES;
    
#if !TARGET_INTERFACE_BUILDER
    _ruleView.representedObject = self.replacementRule.contextRule;
#endif

    [self addSubview: _ruleView];
    
    _separator = [[UILabel alloc] initWithFrame: CGRectMake(_tileWidth*2, 0, _tileWidth, _tileWidth)];
    _separator.text = NSLocalizedString(@"=>", nil);
    _separator.translatesAutoresizingMaskIntoConstraints = NO;
    _separator.textColor = [FractalScapeIconSet tutorialOverlayColor];

    [self addSubview: _separator];
    
    CGRect replacementRect = CGRectMake(_tileWidth*3, 0, _tileWidth*50, _tileWidth*2);
    _replacementsView = [[MBLSObjectListTileViewer alloc] initWithFrame: replacementRect];
    _replacementsView.justify = _justify;
    _replacementsView.showTileBorder = _showTileBorder;
    _replacementsView.tileWidth = _tileWidth;
    _replacementsView.tileMargin = _tileMargin;
    _replacementsView.readOnly = NO;
    
#if !TARGET_INTERFACE_BUILDER
    _replacementsView.objectList = self.replacementRule.rules;
    [_replacementsView setDefaultObjectClass: [LSDrawingRule class]];
#endif
    
    [self addSubview: _replacementsView];
}

-(void)startBlinkOutline
{
    [self.ruleView startBlinkOutline];
    [self.replacementsView startBlinkOutline];
}
-(void)endBlinkOutline
{
    [self.ruleView endBlinkOutline];
    [self.replacementsView endBlinkOutline];
}

//-(void) layoutSubviews {
//    [self setupSubviews];
//}
-(void) updateConstraints {
    [self removeConstraints: self.constraints];

    self.lastBounds = self.bounds;
    
    NSDictionary* adjacentViewsDictionary = NSDictionaryOfVariableBindings(_ruleView,_separator,_replacementsView);
    
    NSDictionary* metricsDictionary = @{@"width":@(_tileWidth*0.2)};
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-6-[_ruleView]-[_separator]-[_replacementsView]-6-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_ruleView(60)]-70-[_separator(30)]-[_replacementsView(200)]-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_ruleView]-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_separator]-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[_replacementsView]-6-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];

    [self addConstraint: [NSLayoutConstraint constraintWithItem: _replacementsView
                                                      attribute: NSLayoutAttributeCenterY
                                                      relatedBy: NSLayoutRelationEqual
                                                         toItem: self
                                                      attribute: NSLayoutAttributeCenterY
                                                     multiplier: 1.0 constant: 0]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem: _ruleView
                                                      attribute: NSLayoutAttributeCenterY
                                                      relatedBy: NSLayoutRelationEqual
                                                         toItem: self
                                                      attribute: NSLayoutAttributeCenterY
                                                     multiplier: 1.0 constant: 0]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem: _separator
                                                      attribute: NSLayoutAttributeCenterY
                                                      relatedBy: NSLayoutRelationEqual
                                                         toItem: self
                                                      attribute: NSLayoutAttributeCenterY
                                                     multiplier: 1.0 constant: 0]];
    
    [_ruleView setContentHuggingPriority: UILayoutPriorityDefaultLow + 1 forAxis: UILayoutConstraintAxisHorizontal];
//    [_ruleView setContentHuggingPriority: UILayoutPriorityDefaultLow - 1 forAxis: UILayoutConstraintAxisVertical];
    [_ruleView setContentCompressionResistancePriority: UILayoutPriorityRequired forAxis: UILayoutConstraintAxisHorizontal];
    [_replacementsView setContentHuggingPriority: UILayoutPriorityDefaultLow - 1 forAxis: UILayoutConstraintAxisHorizontal];
    [_replacementsView setContentCompressionResistancePriority: UILayoutPriorityFittingSizeLevel forAxis: UILayoutConstraintAxisHorizontal];
    [_replacementsView setNeedsUpdateConstraints];
    
    [super updateConstraints];
}
-(void) layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, self.lastBounds)) {
        //
        [self setNeedsUpdateConstraints];
    }
    
 }

-(void) setReplacementRule:(LSReplacementRule *)replacementRule {
    _replacementRule = replacementRule;
    
    [self setupSubviews];
//    [self setNeedsLayout];
}
-(void) updateRuleViewRule:(id<MDBTileObjectProtocol>)rule {
    if ([rule isKindOfClass: [LSDrawingRule class]]) {
        self.replacementRule.contextRule = (LSDrawingRule*)rule;
        self.ruleView.representedObject = (LSDrawingRule*)rule;
    }
}
-(void) setTileMargin:(CGFloat)tileMargin {
    _tileMargin = tileMargin;
    _replacementsView.tileMargin = _tileMargin;
    
    [self setNeedsUpdateConstraints];
}

-(void) setTileWidth:(CGFloat)tileWidth {
    _tileWidth = tileWidth;
    _ruleView.width = _tileWidth;
    _replacementsView.tileWidth = _tileWidth;
    
    [self setNeedsUpdateConstraints];
}

-(void) setShowTileBorder:(BOOL)showTileBorder {
    _showTileBorder = showTileBorder;
//    _ruleView.showTileBorder = _showTileBorder;
    _replacementsView.showTileBorder = _showTileBorder;
    
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
-(void) setJustify:(BOOL)justify {
    _justify = justify;
    _replacementsView.justify = _justify;
    
    [self setNeedsUpdateConstraints];
}

#pragma mark - Drag&Drop Implementation Details
-(BOOL) pointIsInContext: (CGPoint) aPoint {
    CGPoint localPoint = [self convertPoint: aPoint toView: self.ruleView];
    BOOL pointInside = [self.ruleView pointInside: localPoint withEvent: nil];
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
        if (draggingRule.dragItem != self.ruleView.representedObject) {
            draggingRule.oldReplacedDragItem = self.ruleView.representedObject;
            [self updateRuleViewRule: draggingRule.dragItem];
        }
    }

    return needsLayout;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    //
#pragma message "TODO: fix for uidocument"
//    id<MDBTileObjectProtocol> oldRule = draggingRule.oldReplacedDragItem;
//    if (oldRule != nil && !oldRule.isReferenced) {
//        draggingRule.oldReplacedDragItem = nil;
//        if ([oldRule isKindOfClass: [NSManagedObject class]]) {
//            [((NSManagedObject*)oldRule).managedObjectContext deleteObject: oldRule];
//        }
//    }

    return needsLayout;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    if (draggingRule.dragItem == self.ruleView.representedObject) {
        [self updateRuleViewRule: draggingRule.oldReplacedDragItem];
    }
    
    return needsLayout;
}


@end
