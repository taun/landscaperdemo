//
//  MBDraggingItem.h
//  FractalScape
//
//  Created by Taun Chapman on 10/09/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSDrawingRule+addons.h"

/*!
 Class for easily handling dragging a rule around on the tableView.
 Encapsulates the rule, view, size.
 */
@interface MBDraggingItem : NSObject
/*!
 The rule to be represented. Generates the view when the rule property is changed.
 */
@property (nonatomic,strong) id   dragItem;
/*!
 If a rule is overwritten, it is stored in case we need to restore the original rule.
 */
@property (nonatomic,strong) id   oldReplacedDragItem;
/*!
 A view representing the rule for dragging around on the screen.
 */
@property (nonatomic,strong) UIView                             *view;
/*!
 Size of the draggable view.
 */
@property (nonatomic,assign) CGFloat                            size;
@property (nonatomic,readonly) UIImage                          *asImage;

@property (nonatomic,assign) CGPoint                            touchToDragViewOffset;
/*!
 Coordinates at which to display the dragged view. Must be in the coordinate space of the containing view.
 */
@property (nonatomic,assign) CGPoint                            viewCenter;

#pragma mark - state tracking properties
/*!
 Store the initial state.
 */
@property (nonatomic,copy) NSIndexPath                          *sourceTableIndexPath;
/*!
 Store the current state.
 */
@property (nonatomic,copy) NSIndexPath                          *currentIndexPath;
/*!
 Store the previous state.
 */
@property (nonatomic,copy) NSIndexPath                          *lastTableIndexPath;


#pragma mark - instantiation
/*!
 Convenience class method.
 
 @param rule the rule to be represented.
 @param size the size of the view to be dragged.
 
 @return the instance
 */
+(instancetype) newWithItem: (id)representedObject size: (NSInteger)size; //__attribute__((objc_method_family(new)))
/*!
 Designated intializer.
 
 @param rule the rule to be represented.
 @param size the size of the view to be dragged.
 
 @return the instance
 */
-(instancetype) initWithItem: (id)representedObject size: (NSInteger)size NS_DESIGNATED_INITIALIZER;

@end
