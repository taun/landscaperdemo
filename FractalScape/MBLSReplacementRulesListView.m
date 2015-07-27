//
//  MBLSReplacementRulesListView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSReplacementRulesListView.h"
#import "MDBFractalObjectList.h"
#import "LSDrawingRule.h"
#import "LSReplacementRule.h"
#import "MBLSReplacementRuleTileView.h"

#import "MDBLSObjectTileListAddDeleteView.h"
#import "NSLayoutConstraint+MDBAddons.h"
#import "FractalScapeIconSet.h"


@interface MBLSReplacementRulesListView ()
@property (nonatomic,assign) CGRect                         lastBounds;
@property (nonatomic,weak) MDBLSObjectTileListAddDeleteView*currentAddDeleteView;
@property(nonatomic,strong) UITapGestureRecognizer       *tapGesture;
@property(nonatomic,strong) UILongPressGestureRecognizer *pressGesture;
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
    if (!_tapGesture)
    {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tapGestureRecognized:)];
        [self addGestureRecognizer: _tapGesture];
    }
    _tapGesture.enabled = NO;
    
    if (!_pressGesture)
    {
        _pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(tapGestureRecognized:)];
        [self addGestureRecognizer: _pressGesture];
    }
    _pressGesture.enabled = NO;

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
        
        MDBLSObjectTileListAddDeleteView* strongAddDeleteView = self.currentAddDeleteView;
        if (strongAddDeleteView) {
            // Close AND get rid of all behaviors.
            [strongAddDeleteView animateClosed: NO];
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

-(void)startBlinkOutline
{
    for (MBLSReplacementRuleTileView* rrView in self.subviews)
    {
        [rrView startBlinkOutline];
    }
}

-(void)endBlinkOutline
{
    for (MBLSReplacementRuleTileView* rrView in self.subviews)
    {
        [rrView endBlinkOutline];
    }
}

#pragma mark - Setters & Getters
-(void) setReplacementRules:(NSMutableArray *)replacementRules {
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

#pragma mark - Add & Delete
-(MDBLSAddDeleteState) addDeleteState
{
    MDBLSObjectTileListAddDeleteView* strongAddDeleteView = self.currentAddDeleteView;
    if (strongAddDeleteView) {
        return strongAddDeleteView.state;
    } else {
        return MDBLSNeutral;
    }
}
-(void) setCurrentAddDeleteView:(MDBLSObjectTileListAddDeleteView *)currentAddDeleteView
{
    _currentAddDeleteView = currentAddDeleteView;
    if (currentAddDeleteView) {
        self.tapGesture.enabled = YES;
        self.pressGesture.enabled = YES;
    }
    else
    {
        self.tapGesture.enabled = NO;
        self.pressGesture.enabled = NO;
    }
}

- (IBAction)addSwipeRecognized:(id)sender
{
    MDBLSObjectTileListAddDeleteView* addDeleteView = (MDBLSObjectTileListAddDeleteView*)sender;
    MDBLSAddDeleteState state = addDeleteView.state;
    
    MDBLSObjectTileListAddDeleteView* strongAddDeleteView = self.currentAddDeleteView;

    if (strongAddDeleteView && strongAddDeleteView != addDeleteView) {
        // already have one open so close it first
        [strongAddDeleteView animateClosed: YES];
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
    MDBLSObjectTileListAddDeleteView* addDeleteView = (MDBLSObjectTileListAddDeleteView*)sender;
    MDBLSAddDeleteState state = addDeleteView.state;
    
    MDBLSObjectTileListAddDeleteView* strongAddDeleteView = self.currentAddDeleteView;

    if (strongAddDeleteView && strongAddDeleteView != addDeleteView) {
        // already have one open so close it first
        [strongAddDeleteView animateClosed: YES];
        self.currentAddDeleteView = addDeleteView;
    }
    
    if (self.replacementRules.count == 1) {
        // don't allow the last one to be deleted
        [addDeleteView deleteButtonEnabled: NO];
    } else {
        [addDeleteView deleteButtonEnabled: YES];
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

- (IBAction)tapGestureRecognized:(id)sender
{
    MDBLSObjectTileListAddDeleteView* addDeleteView = self.currentAddDeleteView;
    if (addDeleteView) {
        [addDeleteView animateClosed: YES];
        self.currentAddDeleteView = nil;
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
        
//        [self.context deleteObject: callerRRule];
        
         [self setupSubviews];
    }];
}

- (IBAction)addPressed:(id)sender
{
    MDBLSObjectTileListAddDeleteView* addDeleteView = (MDBLSObjectTileListAddDeleteView*)sender;

    MBLSReplacementRuleTileView* callerRRuleView = (MBLSReplacementRuleTileView*)addDeleteView.content;
    LSReplacementRule* callerRRule = callerRRuleView.replacementRule;
    
    NSInteger ruleIndex = [self.replacementRules indexOfObject: callerRRule];
    
    LSReplacementRule* newReplacementRule = [LSReplacementRule new];
    LSDrawingRule* newContextRule = [LSDrawingRule new];
    LSDrawingRule* newReplacementHolder = [LSDrawingRule new];
    
    newReplacementRule.contextRule = newContextRule;
    MDBFractalObjectList* rules = newReplacementRule.rules;
    [rules addObject: newReplacementHolder];
    
    [self layoutIfNeeded];
    [UIView animateWithDuration: 0.25 animations:^{
        // Make all constraint changes here
        [self.replacementRules insertObject: newReplacementRule atIndex: ruleIndex+1];
        [self setupSubviews];
    }];
}

@end
