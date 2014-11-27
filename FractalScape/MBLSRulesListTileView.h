//
//  MBLSRulesListTileView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


IB_DESIGNABLE

@interface MBLSRulesListTileViewer : UIView

@property (nonatomic,strong) NSMutableOrderedSet        *rules;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showBorder;
@property (nonatomic,assign) IBInspectable BOOL         justify;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;

@property (nonatomic,assign) CGRect    lastBounds;

@end
