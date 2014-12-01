//
//  MBLSRulesListTileView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBLSRuleDragAndDropProtocol.h"


IB_DESIGNABLE

@interface MBLSRulesListTileViewer : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) NSMutableOrderedSet        *rules;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;

@property (nonatomic,assign) CGRect             lastBounds;
@property (nonatomic,strong) NSLayoutConstraint *heightConstraint;
@property (nonatomic,strong) NSMutableArray     *itemConstraints;

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule;

@end

@interface MDBListItemConstraints : NSObject
@property (nonatomic,strong) id                     item;
@property (nonatomic,strong) NSLayoutConstraint     *hConstraint;
@property (nonatomic,strong) NSLayoutConstraint     *vConstraint;
+(instancetype) newItemConstraintsWithItem:  (id) item hConstraint: (NSLayoutConstraint*) hc vConstraint: (NSLayoutConstraint*) vc;
-(instancetype) initWithItem: (id) item hConstraint: (NSLayoutConstraint*) hc vConstraint: (NSLayoutConstraint*) vc;
@end

