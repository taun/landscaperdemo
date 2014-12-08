//
//  MDBLSRuleTileView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LSDrawingRule+addons.h"

#import "MBLSRuleDragAndDropProtocol.h"
#import "MDBTileObjectProtocol.h"
#import "MBLSObjectListTileViewer.h"


//IB_DESIGNABLE


@interface MDBLSObjectTileView : UIImageView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) id<MDBTileObjectProtocol>  representedObject;
@property (nonatomic,readonly) id                       item;

@property (nonatomic,assign) IBInspectable CGFloat      width;
@property (nonatomic,assign) IBInspectable CGFloat      tileCornerRadius;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;
@property (nonatomic,assign) IBInspectable BOOL         replaceable;

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem;
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem;
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem;
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingItem;
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingItem;

@end
