//
//  MBDraggingRule.m
//  FractalScape
//
//  Created by Taun Chapman on 10/09/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBDraggingRule.h"
#import <MDUiKit/MDKLayerView.h>

@implementation MBDraggingRule
+(instancetype)newWithRule:(LSDrawingRule *)rule size:(NSInteger)size {
    return [[self alloc] initWithRule: rule size: size];
}
-(instancetype)initWithRule:(LSDrawingRule *)rule size:(NSInteger)size {
    self = [super init];
    if (self) {
        _size = 26.0;
        _rule = rule;
        [self updateView];
    }
    return self;
}
-(void) updateView {
    CGRect frame = CGRectMake(0, 0, _size, _size);
    self.view = [[UIView alloc] initWithFrame: frame];
    MDKLayerView* outlineView = [[MDKLayerView alloc] initWithFrame: frame];
    outlineView.borderWidth = 1.0;
    outlineView.cornerRadius = 4.0;
    outlineView.borderColor = [UIColor blueColor];
    outlineView.margin = 2.0;
    outlineView.shadowOpacity = 0.5;
    outlineView.shadowRadius = 3.0;
    outlineView.maskToBounds = NO;
    outlineView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview: outlineView];
    UIImage* ruleImage = [_rule asImage];
    UIImageView* ruleView = [[UIImageView alloc] initWithImage: ruleImage];
    if (ruleView) {
        [outlineView addSubview: ruleView];
    }
}
-(void) setRule:(LSDrawingRule *)rule {
    if (_rule != rule) {
        _rule = rule;
        [self updateView];
    }
}
-(void) setSize:(CGFloat)size {
    if (_size != size) {
        _size = size;
        [self updateView];
    }
}
@end
