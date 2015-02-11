//
//  MDBLSObjectTileListAddDeleteView.m
//  FractalScape
//
//  Created by Taun Chapman on 02/09/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBLSObjectTileListAddDeleteView.h"

@interface MDBLSObjectTileListAddDeleteView ()

@property(nonatomic,strong) UISwipeGestureRecognizer     *addSwipeGesture;
@property(nonatomic,strong) UISwipeGestureRecognizer     *deleteSwipeGesture;
@property(nonatomic,strong) UITapGestureRecognizer       *tapGesture;
@property(nonatomic,strong) UILongPressGestureRecognizer *pressGesture;

@property(nonatomic,strong) UIDynamicAnimator            *cellAnimator;
@property(nonatomic,strong) UISnapBehavior               *snapBehaviour;
@property(readwrite,assign) MDBLSAddDeleteState           state;
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
        [self setupSubviews];
    }
    return self;
}


-(void) setupSubviews {
    self.clipsToBounds = NO;
    
    _state = MDBLSNeutral;

    _addSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(addSwipeRecognized:)];
    _addSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer: _addSwipeGesture];
    
    _deleteSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(deleteSwipeRecognized:)];
    _deleteSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer: _deleteSwipeGesture];
    
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tapGestureRecognized:)];
    [self addGestureRecognizer: _tapGesture];
    _tapGesture.enabled = NO;
    
    _pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(tapGestureRecognized:)];
    [self addGestureRecognizer: _pressGesture];
    _pressGesture.enabled = NO;

    UIView* view = [[[NSBundle bundleForClass: [self class]] loadNibNamed: NSStringFromClass([self class]) owner: self options: nil] firstObject];
    [self addSubview: view];
    view.frame = self.bounds;
    
    [self updateButtonAlphas];
    
#if TARGET_INTERFACE_BUILDER
#endif

    [self setupConstraints];
    
}

-(void) setContent:(UIView *)content {
    if (_content) {
        [_content removeFromSuperview];
    }
    _content = content;
    [self addSubview: _content];
    self.cellAnimator = [[UIDynamicAnimator alloc]initWithReferenceView: self];

    NSDictionary* viewsDict = @{@"content": _content};
    
    NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem: _content
                                                                      attribute: NSLayoutAttributeLeading
                                                                      relatedBy: NSLayoutRelationEqual
                                                                         toItem: self
                                                                      attribute: NSLayoutAttributeLeading
                                                                     multiplier: 1.0 constant: 0.0];
    _leftConstraint = leftConstraint;
    [self addConstraint: leftConstraint];
    
    NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem: _content
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
        [self.delegate addSwipeRecognized: sender];
    }
}

- (IBAction)deleteSwipeRecognized:(id)sender
{
    if ([self.delegate respondsToSelector: @selector(deleteSwipeRecognized:)]) {
        [self.delegate deleteSwipeRecognized: sender];
    }
}
-(IBAction)tapGestureRecognized:(id)sender
{
    if (self.state != MDBLSNeutral) {
        [self animateClosed: YES];
    }
}
-(void) animate: (BOOL)animate contentsToPosition: (CGFloat) position
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
            [self updateButtonAlphas];
            self.leftConstraint.constant = position;
            self.rightConstraint.constant = position;
            [self layoutIfNeeded];
        }];
    }
    else
    {
        [self updateButtonAlphas];
        self.leftConstraint.constant = position;
        self.rightConstraint.constant = position;
    }

}
-(void) updateButtonAlphas
{
    switch (_state) {
        case MDBLSNeutral:
            self.addButton.alpha = 0.0;
            self.deleteButton.alpha = 0.0;
            break;
        case MDBLSAdding:
            self.addButton.alpha = 1.0;
            break;
        case MDBLSDeleting:
            self.deleteButton.alpha = 1.0;
            
        default:
            break;
    }
}
-(IBAction) deleteButtonEnabled:(BOOL)enabled
{
    if (enabled)
    {
        self.deleteButton.enabled = YES;
    }
    else
    {
        self.deleteButton.enabled = NO;
    }
}
-(void) animateClosed: (BOOL)animate {
    self.state = MDBLSNeutral;
    
    [self animate: (BOOL) animate contentsToPosition: 0.0];
    [self setContentViewEnabled: YES];
}
-(void) animateSlideForAdd {
    self.state = MDBLSAdding;
    
    CGFloat position = self.addButton.bounds.size.width + 8;
    [self setContentViewEnabled: NO];
    [self animate: YES contentsToPosition: position];
}
-(void) animateSlideForDelete {
    self.state = MDBLSDeleting;

    CGFloat position = self.deleteButton.bounds.size.width + 8;
    [self setContentViewEnabled: NO];
    [self animate: YES contentsToPosition: -position];
}

-(void) setContentViewEnabled: (BOOL)enabled
{
    self.content.userInteractionEnabled = enabled;
    self.tapGesture.enabled = !enabled;
    self.pressGesture.enabled = !enabled;
}
@end
