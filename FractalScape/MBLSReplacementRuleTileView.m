//
//  MBLSReplacementRuleTileView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSReplacementRuleTileView.h"
#import "MDBLSRuleImageView.h"
#import "MBLSRulesListTileView.h"


@interface MBLSReplacementRuleTileView ()

@property (nonatomic,strong) MDBLSRuleImageView             *ruleView;
@property (nonatomic,strong) UILabel                        *separator;
@property (nonatomic,strong) MBLSRulesListTileViewer        *replacementsView;
@property (nonatomic,assign) CGRect                         lastBounds;

@end

@implementation MBLSReplacementRuleTileView


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
//    self.contentMode = UIViewContentModeRedraw;
    
    _tileWidth = 26.0;
    _tileMargin = 2.0;
    
}
-(void) setupSubviews {
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }
    

    _ruleView = [[MDBLSRuleImageView alloc] initWithFrame: CGRectMake(0, 0, _tileWidth, _tileWidth)];
    _ruleView.showBorder = YES;
    _ruleView.width = _tileWidth;
    
#if !TARGET_INTERFACE_BUILDER
    _ruleView.rule = self.replacementRule.contextRule;
#endif

    [self addSubview: _ruleView];
    
    _separator = [[UILabel alloc] initWithFrame: CGRectMake(_tileWidth*2, 0, _tileWidth, _tileWidth)];
    _separator.text = @":";
    _separator.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview: _separator];
    
    CGRect replacementRect = CGRectMake(_tileWidth*3, 0, _tileWidth*50, _tileWidth*2);
    _replacementsView = [[MBLSRulesListTileViewer alloc] initWithFrame: replacementRect];
    _replacementsView.justify = _justify;
    _replacementsView.showBorder = _showBorder;
    _replacementsView.tileWidth = _tileWidth;
    _replacementsView.tileMargin = _tileMargin;
    
#if !TARGET_INTERFACE_BUILDER
    _replacementsView.rules = [self.replacementRule mutableOrderedSetValueForKey: @"rules"];
#endif
    
    [self addSubview: _replacementsView];
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

-(void) setShowBorder:(BOOL)showBorder {
    _showBorder = showBorder;
//    _ruleView.showBorder = _showBorder;
    _replacementsView.showBorder = _showBorder;
    
}
-(void) setShowOutline:(BOOL)showOutline {
    _showOutline = showOutline;
    
    if (_showOutline) {
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 6.0;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    } else {
        self.layer.borderWidth = 0.0;
    }
}
-(void) setJustify:(BOOL)justify {
    _justify = justify;
    _replacementsView.justify = _justify;
    
    [self setNeedsUpdateConstraints];
}

@end
