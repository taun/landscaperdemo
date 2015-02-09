//
//  MBFractalRulesEditorViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBLSFractalSummaryEditView.h"
#import "MBLSReplacementRulesListView.h"
#import "MBLSReplacementRuleTileView.h"
#import "MBLSRuleTypeTileViewer.h"



@class LSFractal;

#import "MDBLSObjectTilesViewBaseController.h"

@interface MBFractalRulesEditorViewController : MDBLSObjectTilesViewBaseController 

@property (weak, nonatomic) IBOutlet UIView                         *contentView;
@property (weak, nonatomic) IBOutlet MBLSFractalSummaryEditViewer   *summaryEditView;
@property (weak, nonatomic) IBOutlet MBLSReplacementRulesListView   *replacementRules;

- (IBAction)replacementRuleLongPressGesture:(UILongPressGestureRecognizer *)sender;
- (IBAction)startRulesLongPressGesture:(UILongPressGestureRecognizer *)sender;
- (IBAction)ruleTypeTapGesture:(UITapGestureRecognizer *)sender;
- (IBAction)rulesStartTapGesture:(UITapGestureRecognizer *)sender;
- (IBAction)replacementTapGesture:(UITapGestureRecognizer *)sender;

@end
