//
//  MBLSRulesListTileView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSRulesListTileView.h"

#import "LSDrawingRule+addons.h"
#import "MDBLSRuleImageView.h"

#import "FractalScapeIconSet.h"


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
        
        MDBLSRuleImageView* ruleView = [[MDBLSRuleImageView alloc] initWithFrame: CGRectMake(0.0,0.0,_tileWidth,_tileWidth)];
        [self addSubview: ruleView];
        ruleView.frame = CGRectMake(hPlacement, 0, _tileWidth, _tileWidth);
        ruleView.showBorder = _showBorder;
        ruleView.width = _tileWidth;
        ruleView.rule = rule;

        
        hPlacement += _tileWidth + _tileMargin;
    }
    
    [self setupConstraints];
}

-(void) setupConstraints {
        
    [self setNeedsUpdateConstraints];
}

-(void) updateConstraints {
    [self removeConstraints: self.constraints];
    
    self.lastBounds = self.bounds;
    
    if (_rules) {
        NSInteger itemsPerLine = floorf(self.bounds.size.width / (_tileWidth+_tileMargin));
        
        NSInteger lines;
        
        if (_rules.count == 0 || itemsPerLine == 0) {
            lines = 1;
        } else {
            lines = ceilf(_rules.count / (float)itemsPerLine);
        }
        CGFloat lineHeight = _tileWidth+_tileMargin;
        
        CGFloat widthMargin = _tileMargin;
        
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
            NSDictionary* endViewsDictionary = NSDictionaryOfVariableBindings(firstView);
            NSDictionary* metricsDictionary = @{@"width":@(_tileWidth),@"hmargin" : @(widthMargin), @"vmargin":@(lineNumber*(_tileWidth+_tileMargin))};
            
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
    
    for (MDBLSRuleImageView* subview in self.subviews) {
        subview.width = _tileWidth;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) setShowBorder:(BOOL)showBorder {
    _showBorder = showBorder;
    
    for (MDBLSRuleImageView* subview in self.subviews) {
        subview.showBorder = _showBorder;
    }
    
}
-(void) setReadOnly:(BOOL)readOnly {
    _readOnly = readOnly;
    
    for (MDBLSRuleImageView* subview in self.subviews) {
        subview.readOnly = _readOnly;
    }
    
}
-(void) setJustify:(BOOL)justify {
    _justify = justify;
    
    [self setNeedsUpdateConstraints];
}

@end
