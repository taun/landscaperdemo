//
//  MBLSRuleTypeTileViewer.h
//  FractalScape
//
//  Created by Taun Chapman on 11/24/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import UIKit;

#import "LSDrawingRuleType.h"
#import "LSDrawingRule.h"

#import "MBLSObjectListTileViewer.h"
#import "MBLSRuleDragAndDropProtocol.h"

//IB_DESIGNABLE

@interface MBLSRuleTypeTileViewer : MBLSObjectListTileViewer <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) LSDrawingRuleType          *type;


@end
