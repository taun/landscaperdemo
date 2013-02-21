//
//  MBLSFractalEditViewController.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalDefinitionKeyboardView.h"
#import "ColorPickerController.h"
#import "MBLSRuleTableViewCell.h"
#import "MBLSFractalViewController.h"

@class MBFractalPropertyTableHeaderView;
@class LSFractal;
@class MBLSFractalLevelNView;

@interface MBLSFractalEditViewController : MBLSFractalViewController <FractalDefinitionKVCDelegate, UITextFieldDelegate, UITextViewDelegate, ColorPickerDelegate, UITableViewDataSource, UITableViewDelegate, MBLSRuleTableViewCellDelegate>


@property (nonatomic, strong) UIPopoverController*  colorPopover;
@property (nonatomic, strong) NSString*             coloringKey;
@property (nonatomic, strong) NSDictionary*         portraitViewFrames;


@property (strong, nonatomic) IBOutlet UIView*      fractalPropertyTableHeaderView;
@property (weak, nonatomic)  IBOutlet UITextField*  fractalName;
@property (weak, nonatomic)  IBOutlet UITextField*  fractalCategory;
@property (weak, nonatomic)  IBOutlet UITextView*   fractalDescriptor;

#pragma mark - obsolete
@property (weak, nonatomic) IBOutlet UIView         *fractalPropertiesView;
@property (weak, nonatomic) IBOutlet UIView         *fractalDefinitionPlaceholderView;
@property (strong, nonatomic) IBOutlet UIView       *fractalDefinitionRulesView;
@property (strong, nonatomic) IBOutlet UIView       *fractalDefinitionAppearanceView;

#pragma mark - Property Input Views
@property (weak, nonatomic) IBOutlet UIView         *fractalEditorsHolder;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fractalEditorsHolderHeightConstraint;

@property (weak, nonatomic) IBOutlet UITableView    *fractalPropertiesTableView;

#pragma mark - Drawing Views
@property (weak, nonatomic) IBOutlet UILabel        *fractalViewLevelNLabel;
@property (weak, nonatomic) IBOutlet UIView         *fractalViewLevel0;
@property (weak, nonatomic) IBOutlet UIView         *fractalViewLevel1;

#pragma mark - Production Fields
@property (weak, nonatomic) IBOutlet UITextField    *fractalAxiom;

#pragma mark - Appearance Fields
@property (weak, nonatomic) IBOutlet UITextField    *fractalLineLength;
@property (weak, nonatomic) IBOutlet UIStepper      *lineLengthStepper;

@property (weak, nonatomic) IBOutlet UITextField    *fractalWidth;
@property (weak, nonatomic) IBOutlet UIStepper      *widthStepper;
@property (weak, nonatomic) IBOutlet UISlider       *widthSlider;

@property (weak, nonatomic) IBOutlet UITextField    *fractalTurningAngle;
@property (weak, nonatomic) IBOutlet UIStepper      *turnAngleStepper;
@property (weak, nonatomic) IBOutlet UILabel        *fractalBaseAngle;

@property (weak, nonatomic) IBOutlet UITextField    *fractalLevel;
@property (weak, nonatomic) IBOutlet UIStepper      *levelStepper;
@property (weak, nonatomic) IBOutlet UISlider       *levelSlider;


@property (weak, nonatomic) IBOutlet UISwitch       *strokeSwitch;
@property (weak, nonatomic) IBOutlet UIButton       *strokeColorButton;
@property (weak, nonatomic) IBOutlet UISwitch       *fillSwitch;
@property (weak, nonatomic) IBOutlet UIButton       *fillColorButton;

@property (nonatomic, strong) NSUndoManager *undoManager;

#pragma mark - Fractal Definition Input Protocol
- (void)keyTapped:(NSString*)title;
- (void)doneTapped;

#pragma mark - Description Control Actions
- (IBAction)nameInputDidEnd:(UITextField*)sender;
- (IBAction)switchFractalDefinitionView:(UISegmentedControl*)sender;

#pragma mark - Production Control Actions
- (IBAction)axiomInputChanged:(UITextField*)sender;
- (IBAction)axiomInputEnded:(UITextField*)sender;

#pragma mark - Appearance Control Actions
- (IBAction)lineLengthInputChanged: (UIStepper*)sender;
- (IBAction)lineLengthScaleFactorInputChanged: (UIStepper*)sender;
- (IBAction)lineWidthInputChanged: (id)sender;
- (IBAction)lineWidthIncrementInputChanged: (id)sender;
- (IBAction)turningAngleInputChanged: (UIStepper*)sender;
- (IBAction)turningAngleIncrementInputChanged: (UIStepper*)sender;
- (IBAction)selectStrokeColor: (UIButton*)sender;
- (IBAction)selectFillColor: (UIButton*)sender;
- (IBAction)toggleStroke: (UISwitch*)sender;
- (IBAction)toggleFill: (UISwitch*)sender;

- (IBAction)rotateTurningAngle:(UIRotationGestureRecognizer*)sender;

- (IBAction)rotateFractal:(UIRotationGestureRecognizer*)sender;
- (IBAction)magnifyFractal:(UILongPressGestureRecognizer*)sender;

#pragma mark - Button actions
- (IBAction)undoEdit:(id)sender;
- (IBAction)redoEdit:(id)sender;
- (IBAction)cancelEdit:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
@end
