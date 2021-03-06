//
//  MBLSReplacementRulesListView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import UIKit;

#import "LSReplacementRule.h"
#import "LSDrawingRule.h"

#import "MBLSRuleDragAndDropProtocol.h"
#import "MDBLSObjectTileListAddDeleteView.h"

IB_DESIGNABLE


/*!
 View to show a vertical list of MBLSReplacementRuleTileView(s).
 */
@interface MBLSReplacementRulesListView : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) NSMutableArray             *replacementRules;

@property (nonatomic,assign) IBInspectable CGFloat      rowSpacing;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;
@property (readonly) MDBLSAddDeleteState                addDeleteState;

- (IBAction)addSwipeRecognized:(id)sender;
- (IBAction)deleteSwipeRecognized:(id)sender;
- (IBAction)tapGestureRecognized:(id)sender;

- (IBAction)addPressed:(id)sender;
- (IBAction)deletePressed:(id)sender;

-(void) startBlinkOutline;
-(void) endBlinkOutline;

@end
