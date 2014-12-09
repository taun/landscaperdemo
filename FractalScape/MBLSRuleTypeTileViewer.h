//
//  MBLSRuleTypeTileViewer.h
//  FractalScape
//
//  Created by Taun Chapman on 11/24/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"

#import "MBLSObjectListTileViewer.h"
#import "MBLSRuleDragAndDropProtocol.h"

//IB_DESIGNABLE

@interface MBLSRuleTypeTileViewer : MBLSObjectListTileViewer <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) LSDrawingRuleType          *type;


@end
