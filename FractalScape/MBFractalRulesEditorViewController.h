//
//  MBFractalRulesEditorViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"

#import "MBLSFractalSummaryEditView.h"
#import "MBLSObjectListTileViewer.h"
#import "MBLSReplacementRulesListView.h"
#import "MBLSReplacementRuleTileView.h"
#import "MBLSRuleTypeTileViewer.h"

#import "MBLSRuleDragAndDropProtocol.h"
#import "MBDraggingItem.h"


@class LSFractal;

@interface MBFractalRulesEditorViewController : UIViewController <FractalControllerProtocol>

@property (nonatomic,strong) LSFractal          *fractal;
@property (nonatomic,weak) NSUndoManager        *fractalUndoManager;
@property (nonatomic,strong) MBDraggingItem     *draggingItem;


@property (weak, nonatomic) IBOutlet UIView                         *contentView;
@property (weak, nonatomic) IBOutlet UIScrollView                   *scrollView;
@property (weak, nonatomic) IBOutlet MBLSFractalSummaryEditViewer   *summaryEditView;
@property (weak, nonatomic) IBOutlet MBLSObjectListTileViewer       *rulesView;
@property (weak, nonatomic) IBOutlet MBLSReplacementRulesListView   *replacementRules;
@property (weak, nonatomic) IBOutlet MBLSRuleTypeTileViewer         *ruleTypeListView;
@property (weak, nonatomic) IBOutlet UILabel                        *ruleHelpLabel;

- (IBAction)ruleTypeLongGesture:(UILongPressGestureRecognizer *)sender;
- (IBAction)replacementRuleLongPressGesture:(UILongPressGestureRecognizer *)sender;
- (IBAction)startRulesLongPressGesture:(UILongPressGestureRecognizer *)sender;
- (IBAction)ruleTypeTapGesture:(UITapGestureRecognizer *)sender;
- (IBAction)rulesStartTapGesture:(UITapGestureRecognizer *)sender;
- (IBAction)replacementTapGesture:(UITapGestureRecognizer *)sender;

@end
