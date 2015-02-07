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
    [self.sourceListView setValue: self.fractal.drawingRulesType forKey: @"type"];
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

#pragma mark - Drag & Drop
-(void) deleteObjectIfUnreferenced: (LSDrawingRule*) rule {
    if (rule != nil && !rule.isReferenced) {
        [rule.managedObjectContext deleteObject: rule];
    }
}
- (IBAction)replacementRuleLongPressGesture:(id)sender {
    [self sourceDragLongGesture: sender];
}

- (IBAction)startRulesLongPressGesture:(UILongPressGestureRecognizer *)sender {
    [self sourceDragLongGesture: sender];
}

- (IBAction)ruleTypeTapGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView: self.view];
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
    [self showInfoForView: viewUnderTouch];
}
- (IBAction)rulesStartTapGesture:(UITapGestureRecognizer *)sender {
    NSString* infoString = @"Holder for the starting set of rules to draw.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.destinationView];
}

- (IBAction)replacementTapGesture:(UITapGestureRecognizer *)sender {
    NSString* infoString = @"Occurences of rule to left of ':' replaced by rules to the right.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.replacementRules];
}

- (IBAction)replacementSwipeGesture:(id)sender {
}

@end
