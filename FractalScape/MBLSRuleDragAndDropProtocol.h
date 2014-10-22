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

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule;
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule;
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule;
-(BOOL) dragDidEndDraggingRule: (MBDraggingRule*) draggingRule;
-(BOOL) dragDidExitDraggingRule: (MBDraggingRule*) draggingRule;

@end
