//
//  MDBLSRuleImageView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LSDrawingRule+addons.h"

#import "MBLSRuleDragAndDropProtocol.h"

IB_DESIGNABLE


@interface MDBLSRuleImageView : UIImageView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) LSDrawingRule*             rule;
@property (nonatomic,readonly) id                       item;

@property (nonatomic,assign) IBInspectable CGFloat      width;
@property (nonatomic,assign) IBInspectable CGFloat      cornerRadius;
@property (nonatomic,assign) IBInspectable BOOL         showBorder;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;
@property (nonatomic,assign) IBInspectable BOOL         replaceable;

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule;

@end
