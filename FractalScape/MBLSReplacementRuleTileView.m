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

@property (nonatomic,strong) IBOutlet MDBLSObjectTileView             *ruleView;
@property (nonatomic,strong) IBOutlet UILabel                         *separator;
@property (nonatomic,strong) IBOutlet MBLSObjectListTileViewer        *replacementsView;
@property (nonatomic,assign) CGRect                                    lastBounds;

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

    UIView* view = [[[NSBundle bundleForClass: [self class]] loadNibNamed: NSStringFromClass([self class]) owner: self options: nil] firstObject];
    [self addSubview: view];
    view.frame = self.bounds;

    
#if !TARGET_INTERFACE_BUILDER
    _ruleView.representedObject = self.replacementRule.contextRule;
#endif
    
    _separator.translatesAutoresizingMaskIntoConstraints = NO;
    _separator.textColor = self.tintColor;
    
#if !TARGET_INTERFACE_BUILDER    
    _replacementsView.objectList = [self.replacementRule mutableOrderedSetValueForKey: [LSReplacementRule rulesKey]];
    [_replacementsView setDefaultObjectClass: [LSDrawingRule class] inContext: self.replacementRule.managedObjectContext];
#endif
    
}
//-(void) layoutSubviews {
//    [self setupSubviews];
//}
-(void) updateConstraints {
    [self removeConstraints: self.constraints];

    self.lastBounds = self.bounds;
    
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
}
-(void) updateRuleViewRule:(id<MDBTileObjectProtocol>)rule {
    self.replacementRule.contextRule = rule;
    self.ruleView.representedObject = rule;
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
    id<MDBTileObjectProtocol> oldRule = draggingRule.oldReplacedDragItem;
    if (oldRule != nil && !oldRule.isReferenced) {
        draggingRule.oldReplacedDragItem = nil;
        if ([oldRule isKindOfClass: [NSManagedObject class]]) {
            [((NSManagedObject*)oldRule).managedObjectContext deleteObject: oldRule];
        }
    }

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
