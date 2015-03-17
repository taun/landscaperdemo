//
//  MBLSRuleDragAndDropProtocol.h
//  FractalScape
//
//  Created by Taun Chapman on 10/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import UIKit;
@import CoreGraphics;

#import "MBDraggingItem.h"

/*!
 A protocol to facillitate the drag and drop between embedded views independent of the containing controllers.
 Drag and drop is trivial when there is one controller with a table or collection view. FractalScape uses 
 collection views embedded in the table cells which disassociates the sources and controllers. Adding this 
 protocol to the embedded views and customising the table cells to act like mini-controllers. This protocol
 allows each view mini-controller to know when the drag is starting, entering, changing, exiting, ending. 
 This is important given the touch passes through different mini-contoller views.
 */
@protocol MBLSRuleDragAndDropProtocol <NSObject>

/*!
 Supply the source for the drag.
 
 @param point        point in the views coordinates
 @param draggingRule which transports the dragged item across the mini-controller boundaries.
 
 @return the view representation of the dragged item
 */
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
/*!
 A dragged item is entering the view of the mini-controller and should be handled. Usually by showing the effect
 of dragging the item into the view such as inserting the item into the collection.
 
 @param point        point in the views coordinates
 @param draggingRule which transports the dragged item across the mini-controller boundaries.
 
 @return YES if the view needs to be resized in the container due to an increase in size after inserting item.
 */
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
/*!
 A dragged item is moving within the view of the mini-controller and should be handled. Usually by showing the effect
 of moving the item from one index to another of the collection.
 
 @param point        point in the views coordinates
 @param draggingRule which transports the dragged item across the mini-controller boundaries.
 
 @return YES if the view needs to be resized in the container due to an increase in size after inserting item.
 */
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
/*!
 A dragged item is staying in the view of the mini-controller and should be handled. Maybe by saving the changes if
 they haven't already been saved.
 
 @param point        point in the views coordinates
 @param draggingRule which transports the dragged item across the mini-controller boundaries.
 
 @return YES if the view needs to be resized in the container due to an increase in size after inserting item.
 */
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule;
/*!
 A dragged item is exiting the view of the mini-controller and should be handled. Usually by showing the effect
 of un-dropping the item since it is just passing through to another destination.
 
 @param point        point in the views coordinates
 @param draggingRule which transports the dragged item across the mini-controller boundaries.
 
 @return YES if the view needs to be resized in the container due to an increase in size after inserting item.
 */
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule;

@end
