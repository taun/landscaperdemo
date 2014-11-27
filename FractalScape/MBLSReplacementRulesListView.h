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

IB_DESIGNABLE


@interface MBLSReplacementRulesListView : UIView

@property (nonatomic,strong) NSMutableOrderedSet      *replacementRules;

@property (nonatomic,assign) IBInspectable CGFloat      rowSpacing;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;


@end
