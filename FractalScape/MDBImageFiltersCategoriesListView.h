//
//  MDBImageFiltersCategoriesListView.h
//  FractalScapes
//
//  Created by Taun Chapman on 04/12/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBLSRuleDragAndDropProtocol.h"

#pragma message "TODO Create a common subclass for this and MBColorCategoriesListView"

@interface MDBImageFiltersCategoriesListView : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) NSArray                    *filterCategories;

@property (nonatomic,assign) IBInspectable CGFloat      rowSpacing;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;

@end
