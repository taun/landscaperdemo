//
//  MBFractalRulesEditorViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalRulesEditorViewController.h"
#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "LSDrawingRuleType+addons.h"

#import "MBLSRuleDragAndDropProtocol.h"

#import "FractalScapeIconSet.h"

@interface MBFractalRulesEditorViewController ()
@end

@implementation MBFractalRulesEditorViewController

-(void) updateFractalDependents {
    self.summaryEditView.fractal = self.fractal;
    
    [self.destinationView setDefaultObjectClass: [LSDrawingRule class] inContext: self.fractal.managedObjectContext];
    self.destinationView.objectList = [self.fractal mutableOrderedSetValueForKey: [LSFractal startingRulesKey]];
    
    self.replacementRules.replacementRules = [self.fractal mutableOrderedSetValueForKey: [LSFractal replacementRulesKey]];
    self.replacementRules.context = self.fractal.managedObjectContext;
    
    [self.sourceListView setValue: self.fractal.drawingRulesType forKey: @"type"];
    
    // a convenient place to override autoScroll. Should be in viewDidLoad but this is fine.
    self.autoScroll = YES;
    
    [self.view setNeedsUpdateConstraints];
}


-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.editing = YES;
    
    [self.scrollView flashScrollIndicators];
}
-(void) viewDidDisappear:(BOOL)animated {
    if ([self.fractal hasChanges]) {
        [self saveContext];
    }
    [super viewDidDisappear:animated];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self.view setNeedsUpdateConstraints];
    [self.replacementRules setNeedsUpdateConstraints];
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
}

#pragma mark - Drag & Drop
- (IBAction)sourceDragLongGesture:(UILongPressGestureRecognizer *)sender {
    if (self.replacementRules.addDeleteState != MDBLSNeutral) {
        [self.replacementRules tapGestureRecognized: nil];
    } else {
        [super sourceDragLongGesture: sender];
    }
}
-(void) deleteObjectIfUnreferenced: (LSDrawingRule*) rule {
    if (rule != nil && !rule.isReferenced) {
        [rule.managedObjectContext deleteObject: rule];
    }
}
- (IBAction)replacementRuleLongPressGesture:(id)sender {
    if (self.replacementRules.addDeleteState != MDBLSNeutral) {
        [self.replacementRules tapGestureRecognized: nil];
    } else {
        [self sourceDragLongGesture: sender];
    }
}

- (IBAction)startRulesLongPressGesture:(UILongPressGestureRecognizer *)sender {
    [self sourceDragLongGesture: sender];
}

- (IBAction)ruleTypeTapGesture:(UITapGestureRecognizer *)sender {
    if (self.replacementRules.addDeleteState != MDBLSNeutral) {
        [self.replacementRules tapGestureRecognized: nil];
    } else {
        CGPoint touchPoint = [sender locationInView: self.view];
        UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
        [self showInfoForView: viewUnderTouch];
    }
}
- (IBAction)rulesStartTapGesture:(UITapGestureRecognizer *)sender {
    if (self.replacementRules.addDeleteState != MDBLSNeutral) {
        [self.replacementRules tapGestureRecognized: nil];
    } else {
        NSString* infoString = @"Holder for the starting set of rules to draw.";
        self.ruleHelpLabel.text = infoString;
        [self infoAnimateView: self.destinationView];
    }
}
#pragma message "TODO move info string to proper class instance."
- (IBAction)replacementTapGesture:(UITapGestureRecognizer *)sender {
    NSString* infoString = @"Occurences of rule to left of '=>' replaced by rules to the right.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.replacementRules];
}

@end
