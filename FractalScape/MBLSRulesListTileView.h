//
//  MBLSRulesListTileView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBLSRuleDragAndDropProtocol.h"
#import "LSDrawingRule+addons.h"
#import "NSManagedObject+Shortcuts.h"

IB_DESIGNABLE

@interface MBLSRulesListTileViewer : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) NSMutableOrderedSet        *rules;
/*!
 Save the context in case the rules go to zero.
 */
@property (nonatomic,weak) NSManagedObjectContext       *context;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;

@property (nonatomic,assign) CGRect             lastBounds;
@property (nonatomic,strong) NSLayoutConstraint *heightConstraint;
@property (nonatomic,strong) NSMutableArray     *itemConstraints;

-(LSDrawingRule*) ruleUnderPoint: (CGPoint) aPoint;
-(void) insertRule: (LSDrawingRule*)aRule atPoint: (CGPoint)insertPoint;

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

