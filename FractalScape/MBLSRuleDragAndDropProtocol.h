//
//  MBLSRuleDragAndDropProtocol.h
//  FractalScape
//
//  Created by Taun Chapman on 10/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <CoreGraphics/CoreGraphics.h>
#import "MBDraggingRule.h"


@protocol MBLSRuleDragAndDropProtocol <NSObject>

-(void) gestureBeganAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule;
-(void) gestureChangedToLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule;
-(void) gestureEndedAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule;
-(void) gestureBeganCancelledDraggingRule: (MBDraggingRule*) draggingRule;

@end
