//
//  MDBImageFiltersListView.h
//  FractalScapes
//
//  Created by Taun Chapman on 04/12/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "MBLSObjectListTileViewer.h"
#import "MBLSRuleDragAndDropProtocol.h"

#pragma message "TODO make a common subclass of this and MBColorCategoriesListView"

@interface MDBImageFiltersListView : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) NSString                   *filterCategory;
@property (nonatomic,strong) UILabel                    *categoryLabel;

@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;

@end
