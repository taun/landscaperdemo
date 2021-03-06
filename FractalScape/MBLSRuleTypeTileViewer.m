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
    
    self.objectList = [_type.rulesAsSortedArray mutableCopy];
    self.readOnly = YES;
}

@end
