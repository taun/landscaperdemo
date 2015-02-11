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
@property(nonatomic,strong) UIDynamicAnimator            *cellAnimator;
@property(nonatomic,strong) UISnapBehavior               *snapBehaviour;
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
    
    _addSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(addSwipeRecognized:)];
    _addSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer: _addSwipeGesture];
    
    _deleteSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(deleteSwipeRecognized:)];
    _deleteSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer: _deleteSwipeGesture];
    
    UIView* view = [[[NSBundle bundleForClass: [self class]] loadNibNamed: NSStringFromClass([self class]) owner: self options: nil] firstObject];
    [self addSubview: view];
    view.frame = self.bounds;
    
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
-(void) animateContentsToPosition: (CGFloat) position
{
    [self.cellAnimator removeBehavior: self.snapBehaviour];
    CGPoint currentPosition = self.content.center;
    CGPoint newPosition = CGPointMake(self.content.bounds.size.width/2.0 + position, currentPosition.y);
    self.snapBehaviour = [[UISnapBehavior alloc]initWithItem: self.content snapToPoint: newPosition];
    self.snapBehaviour.damping = 0.9;
    [self.cellAnimator addBehavior: self.snapBehaviour];
    
//    [self layoutIfNeeded];
//    [UIView animateWithDuration: 0.5 animations:^{
        // Make all constraint changes here
        self.leftConstraint.constant = position;
        self.rightConstraint.constant = position;
        [self layoutIfNeeded];
//    }];

}
-(MDBLSAddDeleteState) state {
    MDBLSAddDeleteState theState = MDBLSNeutral;
    
    if (self.leftConstraint.constant > 0) {
        theState = MDBLSAdding;
    } else if (self.leftConstraint.constant < 0) {
        theState = MDBLSDeleting;
    }
    
    return theState;
}
-(void) animateClosed {
    [self animateContentsToPosition: 0.0];
}
-(void) animateSlideForAdd {
    CGFloat position = self.addButton.bounds.size.width + 8;
    [self animateContentsToPosition: position];
}
-(void) animateSlideForDelete {
    CGFloat position = self.deleteButton.bounds.size.width + 8;
    [self animateContentsToPosition: -position];
}
@end
