//
//  MBLSObjectListTileViewer.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSObjectListTileViewer.h"



@implementation MBLSObjectListTileViewer

- (instancetype)initWithFrame:(CGRect)frame {
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
    _didSetupSubviews = NO;
    _itemConstraintsObjectViewMap = [NSMapTable strongToStrongObjectsMapTable];
    
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
    self.didSetupSubviews = NO;
    
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }
    
    [self.itemConstraintsObjectViewMap removeAllObjects];
    
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

    self.didSetupSubviews = YES;
    [self setNeedsUpdateConstraints];
}

-(NSUInteger) itemsPerLine {
    NSUInteger itemsPerLine = floorf((self.bounds.size.width - self.outlineMargin*2.0) / (_tileWidth+_tileMargin));
    
    if (itemsPerLine == 0) {
        itemsPerLine = 1;
    }
    return itemsPerLine;
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

-(void) calcHConstraint: (NSLayoutConstraint*)hConstraint vConstraint: (NSLayoutConstraint*) vConstraint forIndex: (NSUInteger) index {
    
    NSUInteger itemsPerLine = self.itemsPerLine;
    
    NSUInteger widthMargin = _justify ? (self.bounds.size.width - 2.0*self.outlineMargin - (itemsPerLine * _tileWidth)) / (itemsPerLine-1) : _tileMargin;

    NSUInteger lineNumber = floorf((float)index/(float)itemsPerLine);
    
    NSInteger hOffset = self.outlineMargin + (_tileWidth + widthMargin) * (index - lineNumber*itemsPerLine);
    
    NSInteger vOffset = (lineNumber==0 && _showOutline) ? self.outlineMargin : lineNumber*(_tileWidth+_tileMargin);

#pragma message "TODO: fix constraint limits to ? hardware?"
    if (vOffset < 0) {
        NSAssert(YES, @"Constraint out of range");
    }
    hOffset = hOffset < 0 ? 0 : hOffset;
    vOffset = vOffset < 0 ? 0 : vOffset;
    hOffset = hOffset > 1024 ? 1024 : hOffset;
    vOffset = vOffset > 1024 ? 1024 : vOffset;
    
    hConstraint.constant = hOffset;
    vConstraint.constant = vOffset;
}

/*!
 Creates and adds the view to the subviews for the tile item.
 Also adds generic constraints for the view and adds both to the itemConstraintsObjectViewMap property.
 
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
    
    [self.itemConstraintsObjectViewMap setObject: [MDBListItemConstraints newItemView: tileView hConstraint: hConstraint vConstraint: vConstraint] forKey: aTileableObject];
    
    [self calcHConstraint: hConstraint vConstraint: vConstraint forIndex: index];
    
    return tileView;
}
/*!
 Move the view in the container and itemContraints array
 
 @param fIndex initial index
 @param tIndex destination index
 */
//-(void) moveViewForRepresentedObjectFrom: (NSUInteger) fIndex to: (NSUInteger) tIndex {
//    MDBListItemConstraints* itemToMove = self.itemConstraintsObjectViewMap[fIndex];
//    [self.itemConstraintsObjectViewMap removeObjectAtIndex: fIndex];
//    
//    [self insertSubview: itemToMove.view atIndex: tIndex];
//    
//    if (fIndex < tIndex) tIndex--;
//    
//    [self.itemConstraintsObjectViewMap insertObject: itemToMove atIndex: tIndex];
//}
/*!
 Removes the item view and constraints from the superview and itemConstraintsObjectViewMap.
 
 Does not recalculate constraints.
 
 @param index the item index
 
 @return the removed view
 */
//-(MDBLSObjectTileView*) removeViewForRepresentedObjectAtIndex: (NSUInteger) index {
//    
//    MDBLSObjectTileView* removedView = self.subviews[index];
//    
//    [self.itemConstraintsObjectViewMap removeObjectAtIndex: index];
//    
//    [removedView removeFromSuperview];
//    
//    return removedView;
//}

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
/*!
 Assumes the objectList has changed and we need to handle to additions and removals here.
 
 Need to find 2 cases
    views no longer represented in objectList
    objects in list without a view.
 */
-(void) assignAllConstraintConstants {
    
    if (self.didSetupSubviews && self.objectList != nil && self.objectList.count > 0) {
        // a way to check if all of the subviews have been laid out.
        // it is possible for update constraints to be called while subviews are still being laid out.
    
        // Get set of objects already represented
        NSMutableSet* representedObjectsSet = [[NSMutableSet alloc] initWithCapacity: self.subviews.count];
        NSArray* subviewsCopy = [self.subviews copy];
        
        // remove the old
        for (MDBLSObjectTileView* view in subviewsCopy) {
            id representedObject = view.representedObject;
            
            if (![self.objectList containsObject: representedObject]) {
                // views representedObject no longer in master list, remove it
                MDBListItemConstraints* item = [self.itemConstraintsObjectViewMap objectForKey: representedObject];
                [self.itemConstraintsObjectViewMap removeObjectForKey: representedObject];
                [(UIView*)item.view removeFromSuperview];
            } else {
                [representedObjectsSet addObject: representedObject];
            }
        }
        
        // add the new
        NSMutableSet* representationsToAdd = [self.objectList.set mutableCopy];
        [representationsToAdd minusSet: representedObjectsSet];
        
        for (id object in representationsToAdd) {
            NSUInteger newIndex = [self.objectList indexOfObject: object];
            [self addViewForRepresentedObject: object atIndex: newIndex];
        }
        
        // re-flow
        for (int i=0 ; i < self.objectList.count; i++ ) {
            id object = self.objectList[i];
            MDBListItemConstraints* item = [self.itemConstraintsObjectViewMap objectForKey: object];
            NSLayoutConstraint* hConstraint = item.hConstraint;
            NSLayoutConstraint* vConstraint = item.vConstraint;
            
            [self calcHConstraint: hConstraint vConstraint: vConstraint forIndex: i ];
        }
        self.heightConstraint.constant = self.lines*self.lineHeight+2*self.outlineMargin;

    }
    
}
-(void) animateConstraintChanges {
    [self layoutIfNeeded]; // Ensures that all pending layout operations have been completed
    [UIView animateWithDuration: 0.1 animations:^{
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
        id lastObject = [self.objectList lastObject];
        
        // We could use views but we arent keeping views in order.
        MDBListItemConstraints* lastItemConstraints = [self.itemConstraintsObjectViewMap objectForKey: lastObject];
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
        if ([firstObject isKindOfClass: [NSManagedObject class]] && self.context) {
            [self.context deleteObject: firstObject];
        }
        insertionIndex = 0;
    }
        
    
    [self.objectList insertObject: newRule atIndex: insertionIndex]; // works for index == count
    
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
        
        [self animateConstraintChanges];
    }
}
-(void) removeRepresentedObject: (id<MDBTileObjectProtocol>) object {
    NSUInteger objectIndex = [self.objectList indexOfObject: object];
    
    if (objectIndex != NSNotFound) {
        [self.objectList removeObject: object];
        
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

+(instancetype) newItemView: (MDBLSObjectTileView*) view hConstraint:(NSLayoutConstraint *)hc vConstraint:(NSLayoutConstraint *)vc {
    return [[self alloc] initWithView: view hConstraint: hc vConstraint: vc];
}

-(instancetype) initWithView: (MDBLSObjectTileView*) view hConstraint: (NSLayoutConstraint*) hc vConstraint: (NSLayoutConstraint*) vc {
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

+(instancetype) insertNewObjectIntoContext:(id)managedObjectContext {
    return [[[self class] alloc] init];
}

-(BOOL) isDefaultObject {
    return YES;
}

-(BOOL) isReferenced {
    return NO;
}

-(UIImage*) asImage {
    UIImage* cellImage = [FractalScapeIconSet imageOfKBIconRulePlaceEmpty];
    return cellImage;
}
@end

