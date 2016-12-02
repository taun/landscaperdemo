//
//  MDBLSObjectTileListAddDeleteView.m
//  FractalScape
//
//  Created by Taun Chapman on 02/09/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBLSObjectTileListAddDeleteView.h"
#import "MBLSReplacementRuleTileView.h"


@interface MDBLSObjectTileListAddDeleteView ()

@property(nonatomic,strong) UISwipeGestureRecognizer     *addSwipeGesture;
@property(nonatomic,strong) UISwipeGestureRecognizer     *deleteSwipeGesture;
@property(nonatomic,strong) UITapGestureRecognizer       *tapGesture;
@property(nonatomic,strong) UILongPressGestureRecognizer *pressGesture;

@property(nonatomic,strong) UIDynamicAnimator            *cellAnimator;
@property(nonatomic,strong) UISnapBehavior               *snapBehaviour;
@property(readwrite,assign) MDBLSAddDeleteState           state;

@property(nonatomic,assign) CGFloat                      deleteControlInitialConstant;
@property(nonatomic,assign) CGFloat                      addControlInitialConstant;

@end

@implementation MDBLSObjectTileListAddDeleteView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
//        [self setupSubviews];
    }
    return self;
}

//-(void)awakeFromNib
//{
//    [super awakeFromNib];
//    [self setupSubviews];
//}

//-(void)layoutSubviews
//{
//    [super layoutSubviews];
//    [self setupSubviews];
//}

-(BOOL) canBecomeFirstResponder
{
    return YES;
}


-(void) setupSubviews {
    self.clipsToBounds = NO;
    
    
    if (!_addSwipeGesture) {
        _addSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(addSwipeRecognized:)];
        _addSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer: _addSwipeGesture];
    }
    
    if (!_deleteSwipeGesture) {
        _deleteSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(deleteSwipeRecognized:)];
        _deleteSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer: _deleteSwipeGesture];
    }
    
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tapGestureRecognized:)];
        [self addGestureRecognizer: _tapGesture];
    }
    _tapGesture.enabled = NO;
    
    if (!_pressGesture) {
        _pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(tapGestureRecognized:)];
        [self addGestureRecognizer: _pressGesture];
    }
    _pressGesture.enabled = NO;

    UIView* view = [[[NSBundle bundleForClass: [self class]] loadNibNamed: NSStringFromClass([self class]) owner: self options: nil] firstObject];
    [self addSubview: view];
    view.frame = self.bounds;
 
    self.addControlInitialConstant = self.addControlConstraint.constant;
    self.deleteControlInitialConstant = self.deleteControlConstraint.constant;

#if TARGET_INTERFACE_BUILDER
#endif

    [self setupConstraints];
    
    // state must come after constraints due to constraints dependency
    self.state = MDBLSNeutral;
}

-(void)startBlinkOutline
{
    for (MBLSReplacementRuleTileView* subview in self.subviews)
    {
        if ([subview isKindOfClass: [MBLSReplacementRuleTileView class]]) [subview startBlinkOutline];
    }
}
-(void)endBlinkOutline
{
    for (MBLSReplacementRuleTileView* subview in self.subviews)
    {
        if ([subview isKindOfClass: [MBLSReplacementRuleTileView class]])  [subview endBlinkOutline];
    }
}

-(void) setTileMargin:(CGFloat)tileMargin {
    _tileMargin = tileMargin;
    
    for (MBLSReplacementRuleTileView* rrView in self.subviews) {
        if([rrView isKindOfClass: [MBLSReplacementRuleTileView class]]) rrView.tileMargin = _tileMargin;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) setShowOutline:(BOOL)showOutline {
    _showOutline = showOutline;
    
    for (MBLSReplacementRuleTileView* rrView in self.subviews) {
        if([rrView isKindOfClass: [MBLSReplacementRuleTileView class]]) rrView.showOutline = _showOutline;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) setTileWidth:(CGFloat)tileWidth {
    _tileWidth = tileWidth;
    
    for (MBLSReplacementRuleTileView* rrView in self.subviews) {
        if([rrView isKindOfClass: [MBLSReplacementRuleTileView class]]) rrView.tileWidth = _tileWidth;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) setJustify:(BOOL)justify {
    _justify = justify;
    
    for (MBLSReplacementRuleTileView* rrView in self.subviews) {
        if([rrView isKindOfClass: [MBLSReplacementRuleTileView class]]) rrView.justify = _justify;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void)updateConstraints
{
    [super updateConstraints];
}

-(void) setContent:(UIView *)content {
    UIView* strongContent = _content;
    if (strongContent) {
        [strongContent removeFromSuperview];
    }
    _content = content;
    [self addSubview: content];
    self.cellAnimator = [[UIDynamicAnimator alloc]initWithReferenceView: self];

    NSDictionary* viewsDict = @{@"content": content};
    
    NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem: content
                                                                      attribute: NSLayoutAttributeLeading
                                                                      relatedBy: NSLayoutRelationEqual
                                                                         toItem: self
                                                                      attribute: NSLayoutAttributeLeading
                                                                     multiplier: 1.0 constant: 0.0];
    _leftConstraint = leftConstraint;
    [self addConstraint: leftConstraint];
    
    NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem: content
                                                                       attribute: NSLayoutAttributeTrailing
                                                                       relatedBy: NSLayoutRelationEqual
                                                                          toItem: self
                                                                       attribute: NSLayoutAttributeTrailing
                                                                      multiplier: 1.0 constant: 0.0];
    _rightConstraint = rightConstraint;
    [self addConstraint: rightConstraint];
    
    //        [addDeleteContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[newRR]-0-|"
    //                                                                                    options: 0
    //                                                                                    metrics: nil
    //                                                                                      views: viewsDict]];
    
    [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-0-[content]-0-|"
                                                                                options: 0
                                                                                metrics: nil
                                                                                  views: viewsDict]];
//    self.state = MDBLSNeutral;
}

-(void) setupConstraints
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

- (IBAction)deletePressed:(id)sender
{
    if ([self.delegate respondsToSelector: @selector(deletePressed:)]) {
        [self.delegate deletePressed: self];
    }
}

- (IBAction)addPressed:(id)sender
{
    if ([self.delegate respondsToSelector: @selector(addPressed:)]) {
        [self.delegate addPressed: self];
    }
}

- (IBAction)addSwipeRecognized:(id)sender
{
    if ([self.delegate respondsToSelector: @selector(addSwipeRecognized:)]) {
        [self.delegate addSwipeRecognized: self];
    }
}

- (IBAction)deleteSwipeRecognized:(id)sender
{
    if ([self.delegate respondsToSelector: @selector(deleteSwipeRecognized:)]) {
        [self.delegate deleteSwipeRecognized: self];
    }
}
-(IBAction)tapGestureRecognized:(id)sender
{
    if (self.state != MDBLSNeutral) {
        [self.delegate tapGestureRecognized: self];
    }
}
-(void) animate: (BOOL)animate toState: (MDBLSAddDeleteState) state
{
//    [self.cellAnimator removeBehavior: self.snapBehaviour];
//    if (animate) {
//        CGPoint currentPosition = self.content.center;
//        CGPoint newPosition = CGPointMake(self.content.bounds.size.width/2.0 + position, currentPosition.y);
//        self.snapBehaviour = [[UISnapBehavior alloc]initWithItem: self.content snapToPoint: newPosition];
//        self.snapBehaviour.damping = 0.9;
//        [self.cellAnimator addBehavior: self.snapBehaviour];
//    }
    
    if (animate)
    {
        [self layoutIfNeeded];
        [UIView animateWithDuration: 0.5 animations:^{
            // Make all constraint changes here
            self.state = state;
            [self layoutIfNeeded];
        }];
    }
    else
    {
        self.state = state;
    }
}
-(IBAction) deleteButtonEnabled:(BOOL)enabled
{
    UIButton* strongButton = self.deleteButton;
    
    strongButton.enabled = enabled;
}
-(void) animateClosed: (BOOL)animate {
    [self animate: (BOOL) animate toState: MDBLSNeutral];
}
-(void) animateSlideForAdd {
    [self animate: YES toState: MDBLSAdding];
}
-(void) animateSlideForDelete {
    [self animate: YES toState: MDBLSDeleting];
}
-(void) setState:(MDBLSAddDeleteState)state
{
    _state = state;
    
    CGFloat position = 0;
    
    UIButton* strongAdd = self.addButton;
    UIButton* strongDelete = self.deleteButton;
    
    switch (_state) {
        case MDBLSNeutral:
            [self setContentViewEnabled:YES];
            strongAdd.alpha = 0.0;
            strongDelete.alpha = 0.0;
            [self resignFirstResponder];
            break;
            
        case MDBLSAdding:
            position = strongAdd.bounds.size.width + 8;
            [self setContentViewEnabled:NO];
            strongAdd.alpha = 1.0;
            [self becomeFirstResponder]; // to dismiss any text editing
            break;
            
        case MDBLSDeleting:
            position = -(strongDelete.bounds.size.width + 8);
            [self setContentViewEnabled:NO];
            strongDelete.alpha = 1.0;
            [self becomeFirstResponder];
            break;
        default:
            break;
    }
    self.addControlConstraint.constant = self.addControlInitialConstant + position;
    self.deleteControlConstraint.constant = self.deleteControlInitialConstant - position;
    self.leftConstraint.constant = position;
    self.rightConstraint.constant = position;
}

-(void) setContentViewEnabled: (BOOL)enabled
{
    self.content.userInteractionEnabled = enabled;
    self.tapGesture.enabled = !enabled;
    self.pressGesture.enabled = !enabled;
}
@end
