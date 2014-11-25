//
//  MBLSRulesListTileView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/24/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface MBLSRulesListTileViewB : UIView

@property (nonatomic,strong) NSMutableOrderedSet        *rules;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showBorder;
@end
