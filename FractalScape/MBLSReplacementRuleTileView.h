//
//  MBLSReplacementRuleTileView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "LSReplacementRule.h"
#import "LSDrawingRule.h"

#import "MBLSObjectListTileViewer.h"
#import "MBLSRuleDragAndDropProtocol.h"

IB_DESIGNABLE


/*!
 Shows the replacement rule in the form of "ruleTile => replacementRulesTiles"
 */
@interface MBLSReplacementRuleTileView : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) LSReplacementRule          *replacementRule;
//@property (nonatomic,strong) UII

@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;

-(void) startBlinkOutline;
-(void) endBlinkOutline;

@end
