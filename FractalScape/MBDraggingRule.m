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
        _size = size;
        _rule = rule;
        [self updateView];
    }
    return self;
}
-(void) updateView {
    CGRect frame = CGRectMake(0, 0, _size, _size);
    CGFloat margin = 2.0;
    
    self.view = [[UIView alloc] initWithFrame: frame];
    MDKLayerView* outlineView = [[MDKLayerView alloc] initWithFrame: frame];
    outlineView.borderWidth = 1.0;
    outlineView.cornerRadius = 4.0;
    outlineView.borderColor = [UIColor blueColor];
    outlineView.margin = 0.0;
    outlineView.shadowOpacity = 0.5;
    outlineView.shadowRadius = 3.0;
    outlineView.shadowOffset = CGPointMake(3, 3);
    outlineView.maskToBounds = NO;
    outlineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent: 0.95];
//    outlineView.contentMode = UIViewContentModeCenter;
    [self.view addSubview: outlineView];
    UIImage* ruleImage = [_rule asImage];
    UIImageView* ruleView = [[UIImageView alloc] initWithImage: ruleImage];
    ruleView.contentMode = UIViewContentModeScaleAspectFit;
    ruleView.frame = CGRectInset(outlineView.frame, margin, margin);

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
-(UIImage*)asImage {
    return [self.rule asImage];
}
@end
