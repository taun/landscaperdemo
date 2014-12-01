//
//  MDBLSFractalBaseView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/30/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBLSRuleDragAndDropProtocol.h"


/*!
 Base for the Fractal views. 
 */
@interface MDBLSFractalBaseView : UIView <MBLSRuleDragAndDropProtocol>


-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule;
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule;

@end
