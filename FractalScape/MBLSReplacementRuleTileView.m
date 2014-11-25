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
@property (nonatomic,strong) MBLSRulesListTileViewer        *replacementsView;

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
    
    _tileWidth = 26.0;
    _tileMargin = 2.0;
}
-(void) setupSubviews {
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }

    _ruleView = [[MDBLSRuleImageView alloc] initWithFrame: CGRectMake(0, 0, _tileWidth, _tileWidth)];
    _ruleView.rule = self.replacementRule.contextRule;
    _ruleView.showBorder = _showBorder;

    [self addSubview: _ruleView];
    
    CGRect replacementRect = CGRectMake(_tileWidth*3, 0, self.bounds.size.width-(_tileWidth*3), _tileWidth);
    _replacementsView = [[MBLSRulesListTileViewer alloc] initWithFrame: replacementRect];
    _replacementsView.rules = [self.replacementRule mutableOrderedSetValueForKey: @"rules"];
    
    [self addSubview: _replacementsView];
}

-(void) updateConstraints {
    [self removeConstraints: self.constraints];

    [super updateConstraints];
}

-(void) setReplacementRule:(LSReplacementRule *)replacementRule {
    _replacementRule = replacementRule;
    
    [self setupSubviews];
}
@end
