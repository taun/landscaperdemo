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

#import "MDBLSObjectTileListAddDeleteView.h"
#import "NSLayoutConstraint+MDBAddons.h"
#import "FractalScapeIconSet.h"


@interface MBLSReplacementRulesListView ()
@property (nonatomic,assign) CGRect                         lastBounds;
@property (nonatomic,weak) MDBLSObjectTileListAddDeleteView*currentAddDeleteView;
@end

@implementation MBLSReplacementRulesListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        [self setupDefaults];
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setupDefaults];
        [self setupSubviews];
    }
    return self;
}

-(void) setupDefaults
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    _rowSpacing = 0.0;
    _tileWidth = 26.0;
    _tileMargin = 2.0;
}
-(void) setupSubviews
{
    for (UIView* view in [self subviews])
    {
        [view removeFromSuperview];
    }

    NSInteger lineNum = 0;
    
    NSInteger rrCount;
    
#if !TARGET_INTERFACE_BUILDER
    for (LSReplacementRule* replacementRule in self.replacementRules)
    {
#else
    for (rrCount = 0; rrCount < 2; rrCount++)
    {
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
        
        MDBLSObjectTileListAddDeleteView* addDeleteContainer = [[MDBLSObjectTileListAddDeleteView alloc] initWithFrame: rrFrame];
        [self addSubview: addDeleteContainer];
        addDeleteContainer.delegate = self;
        [addDeleteContainer setContent: newRR];
        
        
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
        
        if (self.currentAddDeleteView) {
            // Close AND get rid of all behaviors.
            [self.currentAddDeleteView animateClosed: NO];
        }
        
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


#pragma mark - Setters & Getters
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

- (IBAction)addSwipeRecognized:(id)sender
{
    MDBLSObjectTileListAddDeleteView* addDeleteView = (MDBLSObjectTileListAddDeleteView*)[sender view];
    MDBLSAddDeleteState state = addDeleteView.state;
    
    if (self.currentAddDeleteView && self.currentAddDeleteView != addDeleteView) {
        // already have one open so close it first
        [self.currentAddDeleteView animateClosed: YES];
        self.currentAddDeleteView = addDeleteView;
    }
    
    if (state != MDBLSNeutral) {
        // stuck in wrong state somehow
        [addDeleteView animateClosed: YES];
        self.currentAddDeleteView = nil;
    }
    else
    {
        [addDeleteView animateSlideForAdd];
        self.currentAddDeleteView = addDeleteView;
    }
}

- (IBAction)deleteSwipeRecognized:(id)sender
{
    MDBLSObjectTileListAddDeleteView* addDeleteView = (MDBLSObjectTileListAddDeleteView*)[sender view];
    MDBLSAddDeleteState state = addDeleteView.state;
    
    if (self.currentAddDeleteView && self.currentAddDeleteView != addDeleteView) {
        // already have one open so close it first
        [self.currentAddDeleteView animateClosed: YES];
        self.currentAddDeleteView = addDeleteView;
    }
    
    if (self.replacementRules.count == 1) {
        // don't allow the last one to be deleted
        addDeleteView.deleteButton.enabled = NO;
        addDeleteView.deleteButton.alpha = 0.5;
    } else {
        addDeleteView.deleteButton.enabled = YES;
        addDeleteView.deleteButton.alpha = 1.0;
    }

    if (state != MDBLSNeutral) {
        // stuck in wrong state somehow
        [addDeleteView animateClosed: YES];
        self.currentAddDeleteView = nil;
    }
    else
    {
        [addDeleteView animateSlideForDelete];
        self.currentAddDeleteView = addDeleteView;
    }
}

- (IBAction) deletePressed:(id)sender
{
    MDBLSObjectTileListAddDeleteView* addDeleteView = (MDBLSObjectTileListAddDeleteView*)sender;

    MBLSReplacementRuleTileView* callerRRuleView = (MBLSReplacementRuleTileView*)addDeleteView.content;
    LSReplacementRule* callerRRule = callerRRuleView.replacementRule;

    [UIView animateWithDuration: 0.25 animations:^{
        // Make all constraint changes here
        [self.replacementRules removeObject: callerRRule];
        
        [self.context deleteObject: callerRRule];
                
        [self saveContext];
         [self setupSubviews];
    }];
}

- (IBAction)addPressed:(id)sender
{
    MDBLSObjectTileListAddDeleteView* addDeleteView = (MDBLSObjectTileListAddDeleteView*)sender;

    MBLSReplacementRuleTileView* callerRRuleView = (MBLSReplacementRuleTileView*)addDeleteView.content;
    LSReplacementRule* callerRRule = callerRRuleView.replacementRule;
    
    NSInteger ruleIndex = [self.replacementRules indexOfObject: callerRRule];
    
    LSReplacementRule* newReplacementRule = [LSReplacementRule insertNewObjectIntoContext: self.context];
    LSDrawingRule* newContextRule = [LSDrawingRule insertNewObjectIntoContext: self.context];
    LSDrawingRule* newReplacementHolder = [LSDrawingRule insertNewObjectIntoContext: self.context];
    
    newReplacementRule.contextRule = newContextRule;
    NSMutableOrderedSet* rules = [newReplacementRule mutableOrderedSetValueForKey: @"rules"];
    [rules addObject: newReplacementHolder];
    
    [self layoutIfNeeded];
    [UIView animateWithDuration: 0.25 animations:^{
        // Make all constraint changes here
        [self.replacementRules insertObject: newReplacementRule atIndex: ruleIndex+1];
        [self saveContext];
        [self setupSubviews];
    }];
}

- (void)saveContext {
    NSError *error = nil;
    if (_context != nil) {
        if ([_context hasChanges] && ![_context save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } else {
            //            self.fractalDataChanged = YES;
        }
    }
}

@end
