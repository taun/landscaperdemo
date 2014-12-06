//
//  MBLSObjectListTileViewer.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSObjectListTileViewer.h"

#import "MDBLSObjectTileView.h"

#import "FractalScapeIconSet.h"



@interface MBLSObjectListTileViewer ()

@end

@implementation MBLSObjectListTileViewer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupDefaults];
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaults];
        [self setupSubviews];
    }
    return self;
}

-(void) setupDefaults {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.opaque = NO;
//    self.contentMode = UIViewContentModeRedraw;
    
    _tileWidth = 26.0;
    _tileMargin = 2.0;
    _outlineMargin = 6.0;
    _itemConstraints = [NSMutableArray new];
    
}
//-(void) drawRect:(CGRect)rect {
//    [super drawRect:rect];
//}
-(void) setObjectList:(NSMutableOrderedSet *)objects {
    _objectList = objects;
    [self setupSubviews];
}

-(void) setTileMargin:(CGFloat)tileMargin {
    _tileMargin = tileMargin;
    [self setNeedsUpdateConstraints];
}

-(void) setTileWidth:(CGFloat)tileWidth {
    _tileWidth = tileWidth;
    
    for (MDBLSObjectTileView* subview in self.subviews) {
        subview.width = _tileWidth;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) setShowTileBorder:(BOOL)showTileBorder {
    _showTileBorder = showTileBorder;
    
    for (MDBLSObjectTileView* subview in self.subviews) {
        subview.showTileBorder = _showTileBorder;
    }
    
}
-(void) setShowOutline:(BOOL)showOutline {
    _showOutline = showOutline;
    
    if (_showOutline) {
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 6.0;
        self.layer.borderColor = [FractalScapeIconSet groupBorderColor].CGColor;
    } else {
        self.layer.borderWidth = 0.0;
    }
}
-(CGFloat) outlineMargin {
    return  _showOutline ? _outlineMargin : 0.0;
}
-(void) setReadOnly:(BOOL)readOnly {
    _readOnly = readOnly;
    
    for (MDBLSObjectTileView* subview in self.subviews) {
        subview.readOnly = _readOnly;
    }
    
}
-(void) setJustify:(BOOL)justify {
    _justify = justify;
    
    [self setNeedsUpdateConstraints];
}
-(void) setDefaultObjectClass:(Class)defaultObjectClass {
    _defaultObjectClass = defaultObjectClass;
    
    if (_objectList.count == 0) {
        [self setupSubviews];
    }
}
-(void) setDefaultObjectClass:(Class)defaultObjectClass inContext: (NSManagedObjectContext*) context {
    _context = context;
    self.defaultObjectClass = defaultObjectClass;
}

#pragma mark - View Layout Details
-(void) setupSubviews {
    
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }
    
    [self.itemConstraints removeAllObjects];
    
    [self removeConstraints: self.constraints];

    
#if TARGET_INTERFACE_BUILDER
    [self populateRulesWithProxy];
#endif
    
    if (_objectList.count == 0 && _defaultObjectClass && self.context) {
        [_objectList addObject: [_defaultObjectClass insertNewObjectIntoContext: self.context]];
    }
    
    NSInteger index = 0;
    for (int i = 0; i < _objectList.count; i++) {
        
        [self addViewForRepresentedObject: _objectList[i] atIndex: i];
        
    }

    _heightConstraint = [NSLayoutConstraint constraintWithItem: self attribute: NSLayoutAttributeHeight relatedBy: NSLayoutRelationEqual toItem: nil attribute: NSLayoutAttributeNotAnAttribute multiplier: 1.0 constant: 26.0];
    [self addConstraint: _heightConstraint];

    [self setNeedsUpdateConstraints];
}

-(NSUInteger) itemsPerLine {
    return floorf(self.bounds.size.width / (_tileWidth+_tileMargin));
}

-(NSUInteger) lines {
    NSUInteger lines;
    NSUInteger itemsPerLine = self.itemsPerLine;
    if (_objectList.count == 0 || itemsPerLine == 0) {
        lines = 1;
    } else {
        lines = ceilf(_objectList.count / (float)itemsPerLine);
    }
    return lines;
}

-(NSUInteger) lineHeight {
    return _tileWidth+_tileMargin;
}

-(void) calcConstraintConstantsForIndex: (NSUInteger) index {
    
    NSUInteger itemsPerLine = self.itemsPerLine;
    
    NSUInteger widthMargin = _justify ? (self.bounds.size.width - (itemsPerLine * _tileWidth)) / (itemsPerLine-1) : _tileMargin;

    NSUInteger lineNumber = floorf((float)index/(float)itemsPerLine);
    
    NSInteger hOffset = self.outlineMargin + (_tileWidth + widthMargin) * (index - lineNumber*itemsPerLine);
    
    NSInteger vOffset = (lineNumber==0 && _showOutline) ? self.outlineMargin : lineNumber*(_tileWidth+_tileMargin);

    MDBListItemConstraints* listItemConstraints = self.itemConstraints[index];
    listItemConstraints.hConstraint.constant = hOffset;
    listItemConstraints.vConstraint.constant = vOffset;
}

#pragma message "TODO: make for generic using protocol so can be used for colors"
/*!
 Creates and adds the view to the subviews for the tile item.
 Also adds generic constraints for the view and adds both to the itemConstraints property.
 
 Does not calculate constraints.
  */
-(MDBLSObjectTileView*) addViewForRepresentedObject: (id<MDBTileObjectProtocol>) aTileableObject atIndex: (NSUInteger) index {
    
    MDBLSObjectTileView* tileView = [[MDBLSObjectTileView alloc] initWithFrame: CGRectMake(0.0, 0.0, _tileWidth, _tileWidth)];
    tileView.showTileBorder = _showTileBorder;
    tileView.width = _tileWidth;
    tileView.readOnly = _readOnly;
    tileView.representedObject = aTileableObject;
    
    [self insertSubview: tileView atIndex: index];
    
    NSLayoutConstraint* hConstraint = [NSLayoutConstraint constraintWithItem: tileView attribute: NSLayoutAttributeLeft relatedBy: NSLayoutRelationEqual toItem: self attribute: NSLayoutAttributeLeft multiplier: 1.0 constant: 0.0];
    NSLayoutConstraint* vConstraint = [NSLayoutConstraint constraintWithItem: tileView attribute: NSLayoutAttributeTop relatedBy: NSLayoutRelationEqual toItem: self attribute: NSLayoutAttributeTop multiplier: 1.0 constant: 0.0];
    [self addConstraints: @[hConstraint,vConstraint]];
    
    [self.itemConstraints insertObject: [MDBListItemConstraints newItemConstraintsWithView: tileView hConstraint: hConstraint vConstraint: vConstraint]  atIndex: index];
    
    [self calcConstraintConstantsForIndex: index];
    
    return tileView;
}
/*!
 Move the view in the container and itemContraints array
 
 @param fIndex initial index
 @param tIndex destination index
 */
-(void) moveViewForRepresentedObjectFrom: (NSUInteger) fIndex to: (NSUInteger) tIndex {
    MDBListItemConstraints* itemToMove = self.itemConstraints[fIndex];
    [self.itemConstraints removeObjectAtIndex: fIndex];
    
    [self insertSubview: itemToMove.view atIndex: tIndex];
    
    if (fIndex < tIndex) tIndex--;
    
    [self.itemConstraints insertObject: itemToMove atIndex: tIndex];
}
/*!
 Removes the item view and constraints from the superview and itemConstraints.
 
 Does not recalculate constraints.
 
 @param index the item index
 
 @return the removed view
 */
-(MDBLSObjectTileView*) removeViewForRepresentedObjectAtIndex: (NSUInteger) index {
    
    MDBLSObjectTileView* removedView = self.subviews[index];
    
    [self.itemConstraints removeObjectAtIndex: index];
    
    [removedView removeFromSuperview];
    
    return removedView;
}

/*!
 Offsets from the containing view edges rather than inter item margins are used so the items can
 be moved around using constraint animation. For example moving items to fill a gap would be done
 by changing the offsets of the items > the gap.
 */
-(void) updateConstraints {
    
    self.lastBounds = self.bounds;
    
    [self assignAllConstraintConstants];
    
    [super updateConstraints];
    
#if TARGET_INTERFACE_BUILDER
    self.backgroundColor = [UIColor greenColor];
#endif
}
-(void) assignAllConstraintConstants {
    
    if (_objectList.count == self.subviews.count) {
        // a way to check if all of the subviews have been laid out.
        // it is possible for update constraints to be called while subviews are still being laid out.
        for (int i=0 ; i < _objectList.count; i++ ) {
            
            [self calcConstraintConstantsForIndex: i ];
            
            self.heightConstraint.constant = self.lines*self.lineHeight+2*self.outlineMargin;
        }
    }
    
}
-(void) animateConstraintChanges {
    [self layoutIfNeeded]; // Ensures that all pending layout operations have been completed
    [UIView animateWithDuration: 0.5 animations:^{
        // Make all constraint changes here
        
        [self assignAllConstraintConstants];
        
        [self layoutIfNeeded]; // Forces the layout of the subtree animation block and then captures all of the frame changes
    }];
}
-(void) layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, self.lastBounds)) {
        //
        [self setNeedsUpdateConstraints];
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
}

-(void) populateRulesWithProxy {
    _objectList = [[NSMutableOrderedSet alloc]initWithCapacity: 10];
    for (int i=0; i<10; i++) {
        [_objectList addObject: [MDBTileObjectProxy new]];
    }
}

#pragma mark - Drag&Drop Implementation Details
-(id<MDBTileObjectProtocol>) objectUnderPoint:(CGPoint)aPoint {
    id<MDBTileObjectProtocol> object;
    
    UIView* viewUnderTouch = [self hitTest: aPoint withEvent: nil];
    if ([viewUnderTouch isKindOfClass: [MDBLSObjectTileView class]]) {
        object = [(MDBLSObjectTileView*)viewUnderTouch representedObject];
    }
    
    return object;
}
-(NSUInteger) insertionIndexForPoint: (CGPoint) insertionPoint {
    NSUInteger insertionIndex;
    
    id<MDBTileObjectProtocol> objectUnderPoint = [self objectUnderPoint: insertionPoint];
    if (objectUnderPoint) {
        insertionIndex = [self.objectList indexOfObject: objectUnderPoint];
    } else {
        // are we in the view but inbetween or at the end of items?
        NSUInteger lastIndex = self.itemConstraints.count - 1;
        // We could use views but we arent keeping views in order.
        MDBListItemConstraints* lastItemConstraints = self.itemConstraints[lastIndex];
        CGFloat itemTopRightX = lastItemConstraints.hConstraint.constant + self.tileWidth;
        CGFloat itemTopRightY = lastItemConstraints.vConstraint.constant;
        CGFloat width = self.bounds.size.width - itemTopRightX;
        CGFloat height = self.bounds.size.height - itemTopRightY;
        CGRect endSpaceRect = CGRectMake(itemTopRightX, itemTopRightY, width, height);
        if (CGRectContainsPoint(endSpaceRect, insertionPoint)) {
            // we are at the end of the list
            insertionIndex = self.objectList.count;
        } else {
            insertionIndex = NSNotFound;
        }
    }
    return insertionIndex;
}

/*!
 Needs to be able to handle insert/move. Is the rule already in the list or newly being added?
 If it already exists, move.
 
 @param aRule       the rule to insert/move
 @param insertPoint the point over the list.
 */
-(void) insertRepresentedObject:(id<MDBTileObjectProtocol>)aRule atPoint:(CGPoint)insertPoint {
    if (aRule) {
        
        NSUInteger insertionIndex = [self insertionIndexForPoint: insertPoint];
        
        if (insertionIndex != NSNotFound) {
            // NSNotFound might happen if the insertPoint is in between views.
            NSUInteger currentIndex = [self.objectList indexOfObject: aRule];
            
            if (currentIndex != NSNotFound) {
                [self moveRepresentedObjectFrom: currentIndex to: insertionIndex];
            } else {
                // insert
                [self insertRepresentedObject: aRule atIndex: insertionIndex];
            }
        }
        
    }
}

-(void) insertRepresentedObject: (id<MDBTileObjectProtocol>) newRule atIndex: (NSUInteger) insertionIndex {
    id<MDBTileObjectProtocol> firstObject = [self.objectList firstObject];
    
    // check and replace if the default rule placeholder
    if (firstObject.isDefaultObject) {
        [self.objectList removeObjectAtIndex: 0];
        [self removeViewForRepresentedObjectAtIndex: 0];
        if ([firstObject isKindOfClass: [NSManagedObject class]] && self.context) {
            [self.context deleteObject: firstObject];
        }
        insertionIndex = 0;
    }
        
    
    [self.objectList insertObject: newRule atIndex: insertionIndex]; // works for index == count
    [self addViewForRepresentedObject: newRule atIndex: insertionIndex];
    
    [self animateConstraintChanges];
}
-(void) moveRepresentedObjectFrom: (NSUInteger) fromIndex to: (NSUInteger) toIndex {

    BOOL alreadyThere = fromIndex == (toIndex -1) || fromIndex == toIndex;
    // only move if the indexes are different
    if (!alreadyThere) {
        NSUInteger adjustedToIndex = toIndex;
        if (toIndex > fromIndex) {
            adjustedToIndex -= 1; // allow for the removal of the from item
        }
        
        
        id<MDBTileObjectProtocol> object = [self.objectList objectAtIndex: fromIndex];
        [self.objectList removeObject: object];
        [self.objectList insertObject: object atIndex: adjustedToIndex];

        [self moveViewForRepresentedObjectFrom: fromIndex to: toIndex];
        
        [self animateConstraintChanges];
    }
}
-(void) removeRepresentedObject: (id<MDBTileObjectProtocol>) object {
    NSUInteger objectIndex = [self.objectList indexOfObject: object];
    
    if (objectIndex != NSNotFound) {
        [self.objectList removeObject: object];
        
        [self removeViewForRepresentedObjectAtIndex: objectIndex];
        
        if (self.objectList.count == 0 && self.defaultObjectClass && self.context) {
            [self insertNewDefaultObjectOfClass: self.defaultObjectClass atIndex: 0];
        }
        [self animateConstraintChanges];
    }
}

-(void) insertNewDefaultObjectOfClass: (Class) aClass atIndex: (NSUInteger)index {
    
    [_objectList addObject: [aClass insertNewObjectIntoContext: self.context]];
    [self addViewForRepresentedObject: _objectList[index] atIndex: index];
}

#pragma mark - Drag&Drop
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    UIView* dragView;
    
    return dragView;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    if (!self.readOnly) {
        [self insertRepresentedObject: (id<MDBTileObjectProtocol>)draggingItem.dragItem atPoint: point];
    }
    
    return needsLayout;
}
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    if (!self.readOnly) {
        [self insertRepresentedObject: (id<MDBTileObjectProtocol>)draggingItem.dragItem atPoint: point];
    }
    
    return needsLayout;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    
    return needsLayout;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    [self removeRepresentedObject: draggingItem.dragItem];
    
    return needsLayout;
}

@end

@implementation MDBListItemConstraints

+(instancetype) newItemConstraintsWithView:(UIView*)view hConstraint:(NSLayoutConstraint *)hc vConstraint:(NSLayoutConstraint *)vc {
    return [[self alloc] initWithView: view hConstraint: hc vConstraint: vc];
}

-(instancetype) initWithView: (UIView*) view hConstraint: (NSLayoutConstraint*) hc vConstraint: (NSLayoutConstraint*) vc {
    self = [super init];
    if (self) {
        _view = view;
        _hConstraint = hc;
        _vConstraint = vc;
    }
    return self;
}

@end

@implementation MDBTileObjectProxy

-(BOOL) isDefaultObject {
    return YES;
}

-(UIImage*) asImage {
    UIImage* cellImage = [FractalScapeIconSet imageOfKBIconRulePlaceEmpty];
    return cellImage;
}
@end

