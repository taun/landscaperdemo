//
//  MBFractalAppearanceViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"

@class LSFractal;

@interface MBFractalLineSegmentsEditorViewController : UIViewController <FractalControllerProtocol>

@property (nonatomic,strong) LSFractal        *fractal;
@property (nonatomic,weak) NSUndoManager    *fractalUndoManager;

#pragma mark - Appearance Fields
@property (weak, nonatomic) IBOutlet UITextField    *fractalLineLength;
@property (weak, nonatomic) IBOutlet UIStepper      *lineLengthStepper;

@property (weak, nonatomic) IBOutlet UITextField    *fractalWidth;
@property (weak, nonatomic) IBOutlet UIStepper      *widthStepper;

@property (weak, nonatomic) IBOutlet UITextField    *fractalTurningAngle;
@property (weak, nonatomic) IBOutlet UIStepper      *turnAngleStepper;
@property (weak, nonatomic) IBOutlet UILabel        *fractalBaseAngle;


@property (weak, nonatomic) IBOutlet UISwitch       *fillEvenOddSwitch;

@property (weak, nonatomic) IBOutlet UISegmentedControl *lineCapSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *lineJoinSegment;

@property (weak, nonatomic) IBOutlet UITextField        *randomness;
@property (weak, nonatomic) IBOutlet UIStepper          *randomnessStepper;

@property (nonatomic, strong) NSNumberFormatter*            twoPlaceFormatter;

#pragma mark - Appearance Control Actions
- (IBAction)lineLengthStepperChanged: (UIStepper*)sender;
- (IBAction)lineLengthTextInputChanged:(id)sender;

- (IBAction)lineLengthScaleFactorInputChanged: (UIStepper*)sender;

- (IBAction)lineWidthStepperChanged: (UIStepper*)sender;
- (IBAction)lineWidthTextInputChanged:(id)sender;

- (IBAction)lineWidthIncrementInputChanged: (id)sender;

- (IBAction)turningAngleStepperInputChanged: (id)sender;
- (IBAction)turningAngleTextInputChanged: (id)sender;

- (IBAction)turningAngleIncrementInputChanged: (UIStepper*)sender;

- (IBAction)toggleStroke: (UISwitch*)sender;
- (IBAction)toggleFill: (UISwitch*)sender;
//Todo: pages in Appearance controller for fill and stroke colors
//- (IBAction)incrementLineWidth: (id) sender;
//- (IBAction)decrementLineWidth: (id) sender;
//- (IBAction)incrementTurnAngle: (id) sender;
//- (IBAction)decrementTurnAngle: (id) sender;
- (IBAction)toggleFillMode:(UISwitch *)sender;
- (IBAction)changeLineCap:(UISegmentedControl *)sender;
- (IBAction)changeLineJoin:(UISegmentedControl *)sender;

- (IBAction)randomnessStepperChanged:(UIStepper *)sender;
- (IBAction)randomnessInputChanged:(UITextField *)sender;

@end
