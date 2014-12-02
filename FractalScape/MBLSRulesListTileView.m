//
//  MBLSRulesListTileView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSRulesListTileView.h"

#import "MDBLSRuleTileView.h"

#import "FractalScapeIconSet.h"


@implementation MDBListItemConstraints

+(instancetype) newItemConstraintsWithItem:(id)item hConstraint:(NSLayoutConstraint *)hc vConstraint:(NSLayoutConstraint *)vc {
    return [[self alloc] initWithItem: item hConstraint: hc vConstraint: vc];
}

-(instancetype) initWithItem: (id) item hConstraint: (NSLayoutConstraint*) hc vConstraint: (NSLayoutConstraint*) vc {
    self = [super init];
    if (self) {
        _item = item;
        _hConstraint = hc;
        _vConstraint = vc;
    }
    return self;
}

@end

@interface LSDrawingRuleProxy : NSObject

@property (nonatomic,strong) id             rule;
@property (nonatomic,strong) NSString       *iconIdentifierString;

-(UIImage*) asImage;

@end

@implementation LSDrawingRuleProxy

-(UIImage*) asImage {
    UIImage* cellImage = [FractalScapeIconSet imageOfKBIconRulePlaceEmpty];
    return cellImage;
}
@end

@interface MBLSRulesListTileViewer ()

@end

@implementation MBLSRulesListTileViewer

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
    self.opaque = NO;
//    self.contentMode = UIViewContentModeRedraw;
    
    _tileWidth = 26.0;
    _tileMargin = 2.0;
    _itemConstraints = [NSMutableArray new];
    
}
-(void) populateRulesWithProxy {
    _rules = [[NSMutableOrderedSet alloc]initWithCapacity: 10];
    for (int i=0; i<10; i++) {
        [_rules addObject: [LSDrawingRuleProxy new]];
    }
}
-(void) setupSubviews {
    
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }
    
#if TARGET_INTERFACE_BUILDER
    [self populateRulesWithProxy];
#endif
    
#pragma message "Need to add a proxy object for IB"
    
    NSInteger hPlacement = 0;
    for (LSDrawingRule* rule in _rules) {
        
        MDBLSRuleTileView* newView = [self viewForRule: rule];
        newView.frame = CGRectMake(hPlacement, 0, _tileWidth, _tileWidth);
        [self addSubview: newView];
        
        hPlacement += _tileWidth + _tileMargin;
    }
    
    [self setupConstraints];
}
-(MDBLSRuleTileView*) viewForRule: (LSDrawingRule*) aRule {
    
    MDBLSRuleTileView* ruleView = [[MDBLSRuleTileView alloc] initWithFrame: CGRectMake(0.0, 0.0, _tileWidth, _tileWidth)];
    ruleView.showTileBorder = _showTileBorder;
    ruleView.width = _tileWidth;
    ruleView.rule = aRule;

    return ruleView;
}
-(void) setupConstraints {
        
    [self setNeedsUpdateConstraints];
}

/*!
 Offsets from the containing view edges rather than inter item margins are used so the items can 
 be moved around using constraint animation. For example moving items to fill a gap would be done
 by changing the offsets of the items > the gap.
 */
-(void) updateConstraints {
    [self.itemConstraints removeAllObjects];
    [self removeConstraints: self.constraints];
    
    self.lastBounds = self.bounds;
    
    if (_rules && _rules.count > 0) {
        NSInteger itemsPerLine = floorf(self.bounds.size.width / (_tileWidth+_tileMargin));
        
        NSInteger lines;
        
        if (_rules.count == 0 || itemsPerLine == 0) {
            lines = 1;
        } else {
            lines = ceilf(_rules.count / (float)itemsPerLine);
        }
        CGFloat lineHeight = _tileWidth+_tileMargin;
        CGFloat widthMargin = _tileMargin;
        CGFloat outlineMargin = _showOutline ? 6.0 : 0.0;

        if (_justify) {
            //
            widthMargin = (self.bounds.size.width - (itemsPerLine * _tileWidth)) / (itemsPerLine-1);
        }
        
        NSArray* views = self.subviews;
        
        NSInteger lineNumber;
        
        for (lineNumber = 0; lineNumber < lines ; lineNumber++) {
            // anchor each line
            NSInteger itemIndex;
            NSInteger startIndex = itemsPerLine*lineNumber;
            
            UIView* firstView = views[startIndex];
            
            NSInteger vMargin = (lineNumber==0 && _showOutline) ? outlineMargin : lineNumber*(_tileWidth+_tileMargin);
            
            [self addConstraint: [NSLayoutConstraint constraintWithItem: firstView attribute: NSLayoutAttributeWidth relatedBy: NSLayoutRelationEqual toItem: nil attribute: NSLayoutAttributeNotAnAttribute multiplier: 1.0 constant: _tileWidth]];
            [self addConstraint: [NSLayoutConstraint constraintWithItem: firstView attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: nil attribute: NSLayoutAttributeNotAnAttribute multiplier: 1.0 constant: _tileWidth]];

            NSLayoutConstraint* hConstraint = [NSLayoutConstraint constraintWithItem: firstView attribute: NSLayoutAttributeLeft relatedBy: NSLayoutRelationEqual toItem: self attribute: NSLayoutAttributeLeft multiplier: 1.0 constant: outlineMargin];
            NSLayoutConstraint* vConstraint = [NSLayoutConstraint constraintWithItem: firstView attribute: NSLayoutAttributeTop relatedBy: NSLayoutRelationEqual toItem: self attribute: NSLayoutAttributeTop multiplier: 1.0 constant: vMargin];
            [self addConstraints: @[hConstraint,vConstraint]];
            [self.itemConstraints addObject: [MDBListItemConstraints newItemConstraintsWithItem: firstView hConstraint: hConstraint vConstraint: vConstraint]];
            
            NSInteger endIndex = MIN(_rules.count, startIndex+itemsPerLine);
            for (itemIndex = startIndex+1; itemIndex < endIndex; itemIndex++) {
                //
                UIView* view = views[itemIndex];
                CGFloat hOffset = outlineMargin + (_tileWidth + widthMargin) * (itemIndex - lineNumber*itemsPerLine);

                [self addConstraint: [NSLayoutConstraint constraintWithItem: view attribute: NSLayoutAttributeWidth relatedBy: NSLayoutRelationEqual toItem: nil attribute: NSLayoutAttributeNotAnAttribute multiplier: 1.0 constant: _tileWidth]];
                [self addConstraint: [NSLayoutConstraint constraintWithItem: view attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: nil attribute: NSLayoutAttributeNotAnAttribute multiplier: 1.0 constant: _tileWidth]];
                
                hConstraint = [NSLayoutConstraint constraintWithItem: view attribute: NSLayoutAttributeLeft relatedBy: NSLayoutRelationEqual toItem: self attribute: NSLayoutAttributeLeft multiplier: 1.0 constant: hOffset];
                vConstraint = [NSLayoutConstraint constraintWithItem: view attribute: NSLayoutAttributeTop relatedBy: NSLayoutRelationEqual toItem: self attribute: NSLayoutAttributeTop multiplier: 1.0 constant: vMargin];
                [self addConstraints: @[hConstraint,vConstraint]];
                [self.itemConstraints addObject: [MDBListItemConstraints newItemConstraintsWithItem: firstView hConstraint: hConstraint vConstraint: vConstraint]];
            }
        }
        
        CGFloat fullHeight = lines*lineHeight+2*outlineMargin;
        _heightConstraint = [NSLayoutConstraint constraintWithItem: self attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: nil attribute: NSLayoutAttributeNotAnAttribute multiplier: 1.0 constant: fullHeight];
        [self addConstraint: _heightConstraint];
    }
    
    [super updateConstraints];
    
#if TARGET_INTERFACE_BUILDER
    self.backgroundColor = [UIColor greenColor];
#endif
}

-(void) layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, self.lastBounds)) {
        //
        [self setNeedsUpdateConstraints];
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }

}
//-(void) drawRect:(CGRect)rect {
//    [super drawRect:rect];
//}
-(void) setRules:(NSMutableOrderedSet *)rules {
    _rules = rules;
    [self setupSubviews];
}

-(void) setTileMargin:(CGFloat)tileMargin {
    _tileMargin = tileMargin;
    [self setNeedsUpdateConstraints];
}

-(void) setTileWidth:(CGFloat)tileWidth {
    _tileWidth = tileWidth;
    
    for (MDBLSRuleTileView* subview in self.subviews) {
        subview.width = _tileWidth;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) setShowTileBorder:(BOOL)showTileBorder {
    _showTileBorder = showTileBorder;
    
    for (MDBLSRuleTileView* subview in self.subviews) {
        subview.showTileBorder = _showTileBorder;
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
-(void) setReadOnly:(BOOL)readOnly {
    _readOnly = readOnly;
    
    for (MDBLSRuleTileView* subview in self.subviews) {
        subview.readOnly = _readOnly;
    }
    
}
-(void) setJustify:(BOOL)justify {
    _justify = justify;
    
    [self setNeedsUpdateConstraints];
}

#pragma mark - Drag&Drop Implementation Details
-(LSDrawingRule*) ruleUnderPoint:(CGPoint)aPoint {
    LSDrawingRule* rule;
    
    UIView* viewUnderTouch = [self hitTest: aPoint withEvent: nil];
    if ([viewUnderTouch isKindOfClass: [MDBLSRuleTileView class]]) {
        rule = [(MDBLSRuleTileView*)viewUnderTouch rule];
    }
    
    return rule;
}
-(NSUInteger) insertionIndexForPoint: (CGPoint) insertionPoint {
    NSUInteger insertionIndex;
    
    LSDrawingRule* ruleUnderPoint = [self ruleUnderPoint: insertionPoint];
    if (ruleUnderPoint) {
        insertionIndex = [self.rules indexOfObject: ruleUnderPoint];
    } else {
        // are we in the view but inbetween or at the end of items?
        NSUInteger lastIndex = self.itemConstraints.count - 1;
        // We could use views but we arent keeping views in order.
        MDBListItemConstraints* lastItemConstraints = self.itemConstraints[lastIndex];
        CGFloat itemTopRightX = lastItemConstraints.hConstraint.constant + self.tileWidth;
        CGFloat itemTopRightY = lastItemConstraints.vConstraint.constant;
        CGFloat width = self.bounds.size.width - itemTopRightX;
        CGFloat height = self.bounds.size.height - itemTopRightY;
        CGRect endSpaceRect = CGRectMake(itemTopRightX, itemTopRightY, width, height);
        if (CGRectContainsPoint(endSpaceRect, insertionPoint)) {
            // we are at the end of the list
            insertionIndex = self.rules.count;
        } else {
            insertionIndex = NSNotFound;
        }
    }
    return insertionIndex;
}

-(void) moveRuleFrom: (NSUInteger) fromIndex to: (NSUInteger) toIndex {

    BOOL alreadyThere = fromIndex == (toIndex -1) || fromIndex == toIndex;
    // only move if the indexes are different
    if (!alreadyThere) {
        if (toIndex > fromIndex) {
            toIndex -= 1; // allow for the removal of the from item
        }
        
        LSDrawingRule* rule = [self.rules objectAtIndex: fromIndex];
        [self.rules removeObjectAtIndex: fromIndex];
        
        UIView* viewToMove = self.subviews[fromIndex];
        [viewToMove removeFromSuperview];
        
        [self.rules insertObject: rule atIndex: toIndex];
        [self insertSubview: viewToMove atIndex: toIndex];
        
        [self setNeedsUpdateConstraints];
    }
}
-(void) removeRule: (LSDrawingRule*) aRule {
    NSUInteger ruleIndex = [self.rules indexOfObject: aRule];
    
    if (ruleIndex != NSNotFound) {
        [self.rules removeObject: aRule];
        UIView* ruleView = self.subviews[ruleIndex];
        [ruleView removeFromSuperview];
        
        if (self.rules.count == 0) {
            [_rules addObject: [LSDrawingRule insertNewObjectIntoContext: self.context]];
            [self insertSubview: [self viewForRule: _rules[0]] atIndex: 0];
        }
        [self setNeedsUpdateConstraints];
    }
}

-(void) insertRule: (LSDrawingRule*) newRule atIndex: (NSUInteger) insertionIndex {
    LSDrawingRule* firstRule = [self.rules firstObject];
    
    // check and replace if the default rule placeholder
    if (firstRule.isDefaultRule) {
        [self.rules removeObjectAtIndex: 0];
        UIView* oldView = self.subviews[0];
        [oldView removeFromSuperview];
        
    }
    insertionIndex = MIN(self.rules.count - 1, insertionIndex);

    
    [self.rules insertObject: newRule atIndex: insertionIndex]; // works for index == count

    [self insertSubview: [self viewForRule: newRule] atIndex: insertionIndex];
    
    [self setNeedsUpdateConstraints];
}
/*!
 Needs to be able to handle insert/move. Is the rule already in the list or newly being added?
 If it already exists, move.
 
 @param aRule       the rule to insert/move
 @param insertPoint the point over the list.
 */
-(void) insertRule:(LSDrawingRule *)aRule atPoint:(CGPoint)insertPoint {
    if (aRule) {
        
        NSUInteger insertionIndex = [self insertionIndexForPoint: insertPoint];
        
        if (insertionIndex != NSNotFound) {
            // NSNotFound might happen if the insertPoint is in between views.
            NSUInteger currentIndex = [self.rules indexOfObject: aRule];
            
            if (currentIndex != NSNotFound) {
                     [self moveRuleFrom: currentIndex to: insertionIndex];
            } else {
                // insert
                [self insertRule: aRule atIndex: insertionIndex];
            }
        }

    }
}


#pragma mark - Drag&Drop
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    UIView* dragView;
    
    return dragView;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    if (!self.readOnly) {
        [self insertRule: (LSDrawingRule*)draggingItem.dragItem atPoint: point];
    }
    
    return needsLayout;
}
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    if (!self.readOnly) {
        [self insertRule: (LSDrawingRule*)draggingItem.dragItem atPoint: point];
    }
    
    return needsLayout;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    
    return needsLayout;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    [self removeRule: draggingItem.dragItem];
    
    return needsLayout;
}

@end
