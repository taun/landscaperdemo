//
//  MBLSObjectListTileViewer.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBLSRuleDragAndDropProtocol.h"
#import "LSDrawingRule+addons.h"
#import "NSManagedObject+Shortcuts.h"
#import "MDBTileObjectProtocol.h"

IB_DESIGNABLE

/*!
 A UICollectionView style IB_Designable view without the NScrollView subclassing and issues.
 Designed to be used as a resizable subview which always shows all of the tiles and allows 
 drag and drop reordering of the tiles.
 */
@interface MBLSObjectListTileViewer : UIView <MBLSRuleDragAndDropProtocol>

/*!
 An ordered set of the items to be displayed.
 */
@property (nonatomic,strong) NSMutableOrderedSet        *objectList;
/*!
 Save the context in case the items go to zero and we want to add a functional placeholder.
 Needs to be eliminated at some time and replaced with a more functional MDBTileItemProxy.
 */
@property (nonatomic,weak) NSManagedObjectContext       *context;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) CGFloat                    outlineMargin;
@property (nonatomic,assign) IBInspectable BOOL         justify;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;

@property (nonatomic,assign) CGRect             lastBounds;
@property (nonatomic,strong) NSLayoutConstraint *heightConstraint;
@property (nonatomic,strong) NSMutableArray     *itemConstraints;
@property (nonatomic,readonly) NSUInteger       itemsPerLine;
@property (nonatomic,readonly) NSUInteger       lines;
@property (nonatomic,readonly) NSUInteger       lineHeight;

/*!
 The item represented bythe tile at the indicate local context point.
 
 @param aPoint the point in the container context.
 
 @return the object represented by the tile.
 */
-(id<MDBTileObjectProtocol>) objectUnderPoint: (CGPoint) aPoint;
/*!
 Determines the insertion index including cases when the insertion is in the container but past the last tile. 
 In which case the index == the item count so NSMutableArray insertion methods still work inserting the item 
 at the end of the array.
 
 @param insertionPoint the point in the container context.
 
 @return the insertion index which should range from zero to items.count
 */
-(NSUInteger) insertionIndexForPoint: (CGPoint) insertionPoint;
-(void) insertRepresentedObject: (id<MDBTileObjectProtocol>)aRule atPoint: (CGPoint)insertPoint;

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem;
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem;
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem;
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingItem;
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingItem;

@end

/*!
 A class to hold tile constraints so they can be updated as tiles are inserted/removed and transposed.
 Holding the constraints and changing the constraint constants allows the movements to be animated.
 */
@interface MDBListItemConstraints : NSObject
/*!
 The item supplying the view for the tile. Must be protocol compliant.
 */
@property (nonatomic,strong) UIView                 *view;
/*!
 The horizontal constraint. Specified from the container left boundary for each tile.
 This facilitates moving tiles by changing the constraint constant and updating the layout.
 */
@property (nonatomic,strong) NSLayoutConstraint     *hConstraint;
/*!
 The vertical constraint. Specified from the container top boundary for each tile.
 This facilitates moving tiles by changing the constraint constant and updating the layout.
 */
@property (nonatomic,strong) NSLayoutConstraint     *vConstraint;

+(instancetype) newItemConstraintsWithView:  (UIView*) view hConstraint: (NSLayoutConstraint*) hc vConstraint: (NSLayoutConstraint*) vc;
-(instancetype) initWithView: (UIView*) view hConstraint: (NSLayoutConstraint*) hc vConstraint: (NSLayoutConstraint*) vc;
@end

/*!
 A proxy item to supply a default view for interface builder during IB_Designable.
 */
@interface LSDrawingRuleProxy : NSObject

@property (nonatomic,strong) id             rule;
@property (nonatomic,strong) NSString       *iconIdentifierString;

/*!
 Required for the protocol.
 
 @return returns a default UIImage.
 */
-(UIImage*) asImage;

@end

