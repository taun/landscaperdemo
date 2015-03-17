//
//  MDBColorCategoriesListView.h
//  FractalScape
//
//  Created by Taun Chapman on 12/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import UIKit;

#import "MBColorCategory.h"
#import "MBLSRuleDragAndDropProtocol.h"

//IB_DESIGNABLE


@interface MDBColorCategoriesListView : UIView  <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) NSArray                    *colorCategories;

@property (nonatomic,assign) IBInspectable CGFloat      rowSpacing;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;

@end
