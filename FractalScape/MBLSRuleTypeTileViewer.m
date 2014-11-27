//
//  MBLSRuleTypeTileViewer.m
//  FractalScape
//
//  Created by Taun Chapman on 11/24/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSRuleTypeTileViewer.h"

@implementation MBLSRuleTypeTileViewer


-(void) setType:(LSDrawingRuleType *)type {
    _type = type;
    
    self.rules = [_type mutableOrderedSetValueForKey: @"rules"];
    self.readOnly = YES;
}

-(void) updateConstraints {
    CGSize size0 = self.bounds.size;
    [super updateConstraints];
    CGSize size1 = self.bounds.size;
}
-(void) layoutSubviews {
    CGSize lastSize = self.lastBounds.size;
    CGSize size0 = self.bounds.size;
    [super layoutSubviews];
    CGSize size1 = self.bounds.size;
}
-(void) drawRect:(CGRect)rect {
    CGSize size0 = self.bounds.size;
    [super drawRect:rect];
    CGSize size1 = self.bounds.size;
}
@end
