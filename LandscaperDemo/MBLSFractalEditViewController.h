//
//  MBLSFractalEditViewController.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSFractal+addons.h"
#import "FractalDefinitionKeyboardView.h"

@interface MBLSFractalEditViewController : UIViewController <FractalDefinitionKVCDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) LSFractal*            currentFractal;
@property (weak, nonatomic) IBOutlet UITextField    *fractalName;
@property (weak, nonatomic) IBOutlet UITextView     *fractalDescription;
@property (weak, nonatomic) IBOutlet UITextField    *fractalAxiom;
@property (weak, nonatomic) IBOutlet UIView         *fractalViewLevel0;
@property (weak, nonatomic) IBOutlet UIView         *fractalViewLevel1;
@property (weak, nonatomic) IBOutlet UIView         *fractalViewLevelN;
@property (weak, nonatomic) IBOutlet UITextField    *fractalLineLength;
@property (weak, nonatomic) IBOutlet UIStepper      *lineLengthStepper;

@property (weak, nonatomic) IBOutlet UITextField    *fractalTurningAngle;
@property (weak, nonatomic) IBOutlet UIStepper      *turnAngleStepper;
@property (weak, nonatomic) IBOutlet UIScrollView   *fractalPropertiesView;



@property (nonatomic, strong) NSUndoManager *undoManager;

- (void)setUpUndoManager;
- (void)cleanUpUndoManager;
- (void)updateRightBarButtonItemState;

#pragma mark - Fractal Definition Input Protocol
- (void)keyTapped:(NSString*)title;
- (void)doneTapped;

#pragma mark - Control Actions
- (IBAction)lineLengthInputChanged:(id)sender;
- (IBAction)turnAngleInputChanged:(id)sender;
- (IBAction)axiomInputChanged:(UITextField*)sender;
- (IBAction)nameInputDidEnd:(UITextField*)sender;

@end
