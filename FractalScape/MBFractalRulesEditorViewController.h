//
//  MBFractalRulesEditorViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import UIKit;

#import "MBLSFractalSummaryEditView.h"
#import "MBLSReplacementRulesListView.h"
#import "MBLSReplacementRuleTileView.h"
#import "MBLSRuleTypeTileViewer.h"
#import "MDKLayerViewDesignable.h"
#import "MBFractalPrefConstants.h"


@class LSFractal;

#import "MDBLSObjectTilesViewBaseController.h"

@interface MBFractalRulesEditorViewController : MDBLSObjectTilesViewBaseController 

@property (weak, nonatomic) IBOutlet UIView                         *contentView;
@property (weak, nonatomic) IBOutlet MBLSFractalSummaryEditViewer   *summaryEditView;
@property (weak, nonatomic) IBOutlet MBLSReplacementRulesListView   *replacementRules;
@property (weak, nonatomic) IBOutlet MDKLayerViewDesignable         *destinationOutlineView;

- (IBAction)replacementRuleLongPressGesture: (UILongPressGestureRecognizer *)sender;
- (IBAction)startRulesLongPressGesture: (UILongPressGestureRecognizer *)sender;
- (IBAction)sourceTapGesture: (UITapGestureRecognizer *)sender;
- (IBAction)rulesStartTapGesture: (UITapGestureRecognizer *)sender;
- (IBAction)replacementTapGesture: (UITapGestureRecognizer *)sender;

@end
