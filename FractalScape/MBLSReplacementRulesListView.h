//
//  MBLSReplacementRulesListView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LSReplacementRule+addons.h"
#import "LSDrawingRule+addons.h"

#import "MBLSRuleDragAndDropProtocol.h"

IB_DESIGNABLE


@interface MBLSReplacementRulesListView : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) NSMutableOrderedSet      *replacementRules;

@property (nonatomic,assign) IBInspectable CGFloat      rowSpacing;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule;

@end
