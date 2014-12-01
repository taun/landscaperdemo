//
//  MDBLSFractalBaseView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/30/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MDBLSFractalBaseView.h"

@implementation MDBLSFractalBaseView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark - Drag&Drop
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    UIView* dragView;
    
    return dragView;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}

@end
