//
//  MBFractalRulesEditorViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalRulesEditorViewController.h"
#import "LSFractal.h"
#import "MBColor.h"
#import "LSDrawingRuleType.h"

#import "MBLSRuleDragAndDropProtocol.h"

#import "FractalScapeIconSet.h"

@interface MBFractalRulesEditorViewController ()
@end

@implementation MBFractalRulesEditorViewController

-(void) updateFractalDependents
{
    [super updateFractalDependents];
    self.rulesModeSegmentedControl.selectedSegmentIndex = self.fractalDocument.fractal.advancedMode;
    
    [self.destinationView setDefaultObjectClass: [LSDrawingRule class]];
    self.destinationView.objectList = self.fractalDocument.fractal.startingRules;
    self.destinationView.layer.name = @"startingRules";
    [self.destinationView setNeedsUpdateConstraints];
    
    self.replacementRules.replacementRules = [self.fractalDocument.fractal mutableArrayValueForKey: @"replacementRules"];
    
    [self.sourceListView setValue: self.fractalDocument.sourceDrawingRules forKey: @"type"];
    
    // a convenient place to override autoScroll. Should be in viewDidLoad but this is fine.
    self.autoScroll = YES;
    
    [self.view setNeedsUpdateConstraints];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    BOOL allowPremium = self.appModel.allowPremium;
    
    self.rulesModeSegmentedControl.enabled = allowPremium;
    self.destinationView.userInteractionEnabled = allowPremium;
    self.replacementRules.userInteractionEnabled = allowPremium;
    [(UIView*)(self.sourceListView) setUserInteractionEnabled: allowPremium];
    if (!allowPremium)
    {
        CGFloat disabledAlpha = 0.6;
        self.destinationView.alpha = disabledAlpha;
        self.replacementRules.alpha = disabledAlpha;
        [(UIView*)self.sourceListView setAlpha: disabledAlpha];
        self.ruleHelpLabel.text = @"Rule Editing is only available with in-app purchase";
    }
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.editing = YES;
    
    [self.scrollView flashScrollIndicators];
}
-(void) viewDidDisappear:(BOOL)animated {
#pragma message "TODO: uidocument fix"
//    if ([self.fractalDocument hasChanges]) {
//        [self saveContext];
//    }
    [super viewDidDisappear:animated];
}

-(void) viewWillLayoutSubviews
{
    self.allowedDestinationViews = [@[self.replacementRules] arrayByAddingObjectsFromArray: self.allowedDestinationViews];
    [super viewWillLayoutSubviews];
}

-(void) updateViewConstraints
{
    [super updateViewConstraints];
    
    [self.contentView layoutIfNeeded]; // For some reason, layout never happens on contentView without this call.
}


#pragma mark - Drag & Drop
- (IBAction)sourceDragLongGesture:(UILongPressGestureRecognizer *)sender {
    [self cleanUpUIState];
    [super sourceDragLongGesture: sender];
}
-(void) deleteObjectIfUnreferenced: (LSDrawingRule*) rule {
#pragma message "TODO: uidocument fix"
//    if (rule != nil && !rule.isReferenced) {
//        [rule.managedObjectContext deleteObject: rule];
//    }
}
- (IBAction)ruleModeChange:(UISegmentedControl *)sender
{
    self.fractalDocument.fractal.advancedMode = sender.selectedSegmentIndex;
}

- (IBAction)replacementRuleLongPressGesture:(id)sender {
    [self cleanUpUIState];
    [self sourceDragLongGesture: sender];
}

- (IBAction)startRulesLongPressGesture:(UILongPressGestureRecognizer *)sender {
    [self sourceDragLongGesture: sender];
}

- (IBAction)sourceTapGesture:(UIGestureRecognizer *)sender {
    [self cleanUpUIState];
    CGPoint touchPoint = [sender locationInView: self.view];
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
    [self showInfoForView: viewUnderTouch];
}

- (IBAction)rulesStartTapGesture:(UITapGestureRecognizer *)sender {
    [self cleanUpUIState];
    NSString* infoString = @"Holder for the starting set of rules to draw.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.destinationView];
}
#pragma message "TODO move info string to proper class instance."
- (IBAction)replacementTapGesture:(UITapGestureRecognizer *)sender {
    [self cleanUpUIState];
    NSString* infoString = @"Occurences of rule to left of '=>' replaced by rules to the right.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.replacementRules];
}

- (IBAction)upgradeToProClicked:(UIButton *)sender {
}
/*!
 Close any open Add or Delete views and get rid of text editing.
 */
-(void) cleanUpUIState
{
    MBLSReplacementRulesListView* strongReplacementRulesView = self.replacementRules;
    
    if (strongReplacementRulesView.addDeleteState != MDBLSNeutral) {
        [strongReplacementRulesView tapGestureRecognized: nil];
    }
    
    [self.sourceListView becomeFirstResponder];
}

@end
