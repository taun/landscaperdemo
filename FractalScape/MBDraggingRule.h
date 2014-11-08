//
//  MBDraggingRule.h
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
@interface MBDraggingRule : NSObject
/*!
 The rule to be represented. Generates the view when the rule property is changed.
 */
@property (nonatomic,strong) LSDrawingRule                      *rule;
/*!
 If a rule is overwritten, it is stored in case we need to restore the original rule.
 */
@property (nonatomic,strong) LSDrawingRule                      *oldReplacedRule;
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
 Store the initial state.
 */
@property (nonatomic,weak) UICollectionView                     *sourceCollection;
/*!
 Store the initial state.
 */
@property (nonatomic,copy) NSIndexPath                          *sourceCollectionIndexPath;
/*!
 Store the current state.
 */
@property (nonatomic,copy) NSIndexPath                          *currentIndexPath;
/*!
 Store the previous state.
 */
@property (nonatomic,copy) NSIndexPath                          *lastTableIndexPath;
/*!
 Store the previous state.
 */
@property (nonatomic,copy) NSIndexPath                          *lastCollectionIndexPath;
/*!
 Store the previous state.
 */
@property (nonatomic,weak) UICollectionView                     *lastDestinationCollection;
/*!
 Store the previous state.
 */
@property (nonatomic,weak) NSMutableOrderedSet                  *lastDestinationArray;

#pragma mark - Conveniences properties
@property (nonatomic,readonly) BOOL                             isAlreadyDropped;

#pragma mark - instantiation
/*!
 Convenience class method.
 
 @param rule the rule to be represented.
 @param size the size of the view to be dragged.
 
 @return the instance
 */
+(instancetype) newWithRule: (LSDrawingRule*)rule size: (NSInteger)size; //__attribute__((objc_method_family(new)))
/*!
 Designated intializer.
 
 @param rule the rule to be represented.
 @param size the size of the view to be dragged.
 
 @return the instance
 */
-(instancetype) initWithRule: (LSDrawingRule*)rule size: (NSInteger)size NS_DESIGNATED_INITIALIZER;

#pragma mark - state change
/*!
 Has side effects! If the new value is different from the old, then all of the state values are nil'd.
 Reasoning - If the new value for the 'lastTableIndexPath' is different from the old, it means we are
 in a different table cell and need to start over with the drop. Starting over means removing any previous
 dropped representation in the other table cell and setting the other associated values to nil.
 */
-(void) setLastTableIndexPath:(NSIndexPath *)lastTableIndexPath andResetRuleIfDifferent: (BOOL) reset notify: (id)object forPropertyChange:(NSString*)property;
-(void) removePreviousDropRepresentationNotify: (id)object forPropertyChange:(NSString*)property;
/*!
 move the rule either between collections or within a collection.
 
 @param aCollectionType a collection which handles insert and move
 @param indexPath       indexPath to place the rule
 @param object          object to notify of change
 @param property        object property being changed
 
 @return BOOL = YES if collection has added a row needed the eclosing view to be resized.
 */
-(BOOL) moveRuleToArray: (id)aCollectionType indexPath: (NSIndexPath*) indexPath notify: (id)object forPropertyChange:(NSString*)property;
@end
