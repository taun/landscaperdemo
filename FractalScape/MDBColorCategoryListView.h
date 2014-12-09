//
//  MDBColorCategoryListView.h
//  FractalScape
//
//  Created by Taun Chapman on 12/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "MBColorCategory+addons.h"
#import "MBLSObjectListTileViewer.h"
#import "MBLSRuleDragAndDropProtocol.h"

//IB_DESIGNABLE

@interface MDBColorCategoryListView : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) MBColorCategory            *colorCategory;
@property (nonatomic,weak) NSManagedObjectContext       *context;
@property (nonatomic,strong) UILabel                    *categoryLabel;

@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;

@end
