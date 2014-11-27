//
//  MBLSRuleTypeTileViewer.h
//  FractalScape
//
//  Created by Taun Chapman on 11/24/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"

#import "MBLSRulesListTileView.h"

//IB_DESIGNABLE

@interface MBLSRuleTypeTileViewer : MBLSRulesListTileViewer

@property (nonatomic,strong) LSDrawingRuleType          *type;

@end
