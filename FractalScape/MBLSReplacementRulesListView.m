//
//  MBLSReplacementRulesListView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSReplacementRulesListView.h"
#import "LSDrawingRule+addons.h"
#import "LSReplacementRule+addons.h"
#import "MBLSReplacementRuleTileView.h"

#import "NSLayoutConstraint+MDBAddons.h"
#import "FractalScapeIconSet.h"


@interface MBLSReplacementRulesListView ()
@property (nonatomic,assign) CGRect                         lastBounds;
@end

@implementation MBLSReplacementRulesListView

- (instancetype)initWithFrame:(CGRect)frame
{
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
    
    _rowSpacing = 0.0;
    _tileWidth = 26.0;
    _tileMargin = 2.0;
}
-(void) setupSubviews {
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }

    NSInteger lineNum = 0;
    
    NSInteger rrCount;
#if !TARGET_INTERFACE_BUILDER
    for (LSReplacementRule* replacementRule in self.replacementRules) {
#else
    for (rrCount = 0; rrCount < 3; rrCount++) {
#endif
    
        CGRect rrFrame = CGRectMake(0, lineNum*_tileWidth, self.bounds.size.width, _tileWidth);
        MBLSReplacementRuleTileView* newRR = [[MBLSReplacementRuleTileView alloc] initWithFrame: rrFrame];
#if !TARGET_INTERFACE_BUILDER
        newRR.replacementRule = replacementRule;
#endif
        newRR.justify = _justify;
        newRR.tileMargin = _tileMargin;
        newRR.tileWidth = _tileWidth;
        newRR.showTileBorder = _showTileBorder;
        newRR.showOutline = YES;
        
        [self addSubview: newRR];
        
        lineNum++;
#if !TARGET_INTERFACE_BUILDER
    }
#else
    }
#endif
    
    [self setNeedsUpdateConstraints];
}

-(void) updateConstraints {
    if (self.subviews.count > 0) {
        [self removeConstraints: self.constraints];
        
        
        NSInteger lineNumber;
        // anchor each line
        
        for (UIView* view in self.subviews) {
            //
            NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(view);
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options: 0 metrics: 0 views: viewsDictionary]];
        }
        
        [self addConstraints: [NSLayoutConstraint constraintsForFlowing: self.subviews
                                                       inContainingView: self
                                                         forOrientation: UILayoutConstraintAxisVertical
                                                            withSpacing: self.rowSpacing]];
        
    }
    
    [super updateConstraints];
}

//-(void) layoutSubviews {
//    [super layoutSubviews];
//    
//    if (!CGRectEqualToRect(self.bounds, self.lastBounds)) {
//        //
//        [self setNeedsUpdateConstraints];
//    }
//    
//}

-(void) setReplacementRules:(NSMutableOrderedSet *)replacementRules {
    _replacementRules = replacementRules;
    
    [self setupSubviews];
}

-(void) setRowSpacing:(CGFloat)rowSpacing {
    _rowSpacing = rowSpacing;
        
    [self setNeedsUpdateConstraints];
}
    
-(void) setTileMargin:(CGFloat)tileMargin {
    _tileMargin = tileMargin;
    
    for (MBLSReplacementRuleTileView* rrView in self.subviews) {
        rrView.tileMargin = _tileMargin;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) setTileWidth:(CGFloat)tileWidth {
    _tileWidth = tileWidth;

    for (MBLSReplacementRuleTileView* rrView in self.subviews) {
        rrView.tileWidth = _tileWidth;
    }

     [self setNeedsUpdateConstraints];
}

-(void) setShowTileBorder:(BOOL)showTileBorder {
    _showTileBorder = showTileBorder;

    for (MBLSReplacementRuleTileView* rrView in self.subviews) {
        rrView.showTileBorder = _showTileBorder;
    }
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
    
    for (MBLSReplacementRuleTileView* rrView in self.subviews) {
        rrView.justify = _justify;
    }
    
    [self setNeedsUpdateConstraints];
}
#pragma mark - Drag&Drop
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    UIView* dragView;
    
    return dragView;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}

@end
