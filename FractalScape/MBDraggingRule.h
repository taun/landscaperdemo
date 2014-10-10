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
 A view representing the rule for dragging around on the screen.
 */
@property (nonatomic,strong) UIView                             *view;
/*!
 Size of the draggable view.
 */
@property (nonatomic,assign) CGFloat                            size;
/*!
 Convenience class method.
 
 @param rule the rule to be represented.
 @param size the size of the view to be dragged.
 
 @return the instance
 */
+(instancetype) newWithRule: (LSDrawingRule*)rule size: (NSInteger)size;
/*!
 Designated intializer.
 
 @param rule the rule to be represented.
 @param size the size of the view to be dragged.
 
 @return the instance
 */
-(instancetype) initWithRule: (LSDrawingRule*)rule size: (NSInteger)size;
@end
