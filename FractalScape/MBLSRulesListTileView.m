//
//  MBLSRulesListTileView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSRulesListTileView.h"

#import "LSDrawingRule+addons.h"

#import "FractalScapeIconSet.h"

@interface LSDrawingRuleProxy : NSObject
@property (nonatomic,strong) NSString       *iconIdentifierString;

-(UIImage*) asImage;
@end

@implementation LSDrawingRuleProxy

-(UIImage*) asImage {
    UIImage* cellImage = [FractalScapeIconSet imageOfKBIconRulePlace0];
    return cellImage;
}
@end



@implementation MBLSRulesListTileView

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
    
#if TARGET_INTERFACE_BUILDER
    
    _rules = [NSMutableOrderedSet new];
    
    for (int i=0; i < 30 ; i++) {
        LSDrawingRuleProxy *rule1 = [[LSDrawingRuleProxy alloc] init];
        rule1.iconIdentifierString = @"kBIconRulePlace0";
        [_rules addObject: rule1];
    }
    
#endif
    
    NSInteger hPlacement = 0;
    for (id rule in _rules) {
        UIImageView* newImageVIew = [[UIImageView alloc] initWithImage: [rule asImage]];
        newImageVIew.contentMode = UIViewContentModeScaleAspectFit;
        newImageVIew.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview: newImageVIew];
        newImageVIew.frame = CGRectMake(hPlacement, 0, _tileWidth, _tileWidth);
        
        newImageVIew.layer.borderColor = self.tintColor.CGColor;
        newImageVIew.layer.borderWidth = _showBorder ? 1.0 : 0.0;
        newImageVIew.layer.cornerRadius = 4.0;
        
        hPlacement += _tileWidth + _tileMargin;
    }
    
    [self setupConstraints];
}

-(void) setupConstraints {
    
    //    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings();
    
    //    [descriptorBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_descriptor]|" options:0 metrics: 0 views:viewsDictionary]];
    
    [self setNeedsUpdateConstraints];
}

-(void) updateConstraints {
    [self removeConstraints: self.constraints];
    
    NSInteger itemsPerLine = floorf(self.bounds.size.width / (_tileWidth+_tileMargin));
    NSInteger lines = ceilf(_rules.count / (float)itemsPerLine);
    CGFloat lineHeight = _tileWidth+_tileMargin;
    
    
    NSArray* views = self.subviews;
    
    NSInteger lineNumber;
    
    for (lineNumber = 0; lineNumber < lines ; lineNumber++) {
        // anchor each line
        NSInteger itemIndex;
        NSInteger startIndex = itemsPerLine*lineNumber;
        
        UIView* firstView = views[startIndex];
        NSDictionary* endViewsDictionary = NSDictionaryOfVariableBindings(firstView);
        NSDictionary* metricsDictionary = @{@"width":@(_tileWidth),@"hmargin" : @(_tileMargin), @"vmargin":@(lineNumber*(_tileWidth+_tileMargin))};
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[firstView(width)]" options:0 metrics: metricsDictionary views: endViewsDictionary]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vmargin-[firstView(width)]" options:0 metrics: metricsDictionary views: endViewsDictionary]];
        
        NSInteger endIndex = MIN(_rules.count, startIndex+itemsPerLine);
        for (itemIndex = startIndex+1; itemIndex < endIndex; itemIndex++) {
            //
            UIView* prevView = views[itemIndex-1];
            UIView* view = views[itemIndex];
            NSDictionary* adjacentViewsDictionary = NSDictionaryOfVariableBindings(prevView,view);
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[prevView]-hmargin-[view(width)]" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vmargin-[view(width)]" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
        }
    }
    
    NSDictionary* selfViewDict = @{@"self":self};
    NSDictionary* selfMetric = @{@"height": @(lines*lineHeight)};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[self(height)]" options: 0 metrics: selfMetric views: selfViewDict]];
    
    
    [super updateConstraints];
}

-(void) layoutSubviews {
    [super layoutSubviews];
    
    for (UIView* view in self.subviews) {
        view.layer.borderWidth = _showBorder ? 1.0 : 0.0;
    }
}

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
    [self setNeedsUpdateConstraints];
}
@end
