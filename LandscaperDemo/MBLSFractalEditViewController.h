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

@interface MBLSFractalEditViewController : UIViewController <UIGestureRecognizerDelegate, FractalDefinitionKVCDelegate, UITextFieldDelegate, UITextViewDelegate, ColorPickerDelegate, UITableViewDataSource, UITableViewDelegate, MBLSRuleTableViewCellDelegate>

#pragma mark Model
@property (nonatomic, strong) LSFractal            *currentFractal;

/* So a setNeedsDisplay can be sent to each layer when a fractal property is changed. */
@property (nonatomic, strong) NSMutableArray*               fractalDisplayLayersArray;
/* a generator for each level being displayed. */
@property (nonatomic, strong) NSMutableArray*               generatorsArray;
@property (nonatomic, strong) NSArray*                      replacementRulesArray;
@property (nonatomic, strong) NSNumberFormatter*            twoPlaceFormatter;
@property (nonatomic, strong) UIBarButtonItem*              aCopyButtonItem;
@property (nonatomic, strong) UIBarButtonItem*              infoButtonItem;
@property (nonatomic, strong) UIBarButtonItem*              spaceButtonItem;

#pragma mark FractalLevel Nib outlets
@property (weak, nonatomic) IBOutlet UIView        *fractalViewHolder;
@property (weak, nonatomic) IBOutlet UIView        *fractalViewRoot;
@property (weak, nonatomic) IBOutlet UIView        *fractalViewParent;
@property (weak, nonatomic) IBOutlet UIView        *fractalView;
@property (weak, nonatomic) IBOutlet UIView        *sliderContainerView;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *fractalPanGR;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *fractalRightSwipeGR;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *fractalLeftSwipeGR;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *fractalUpSwipeGR;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *fractalDownSwipeGR;

#pragma mark Info HUD
@property (weak, nonatomic) IBOutlet UIView        *hudViewBackground;
@property (weak, nonatomic) IBOutlet UILabel       *hudLabel;
@property (weak, nonatomic) IBOutlet UILabel       *hudText1;
@property (weak, nonatomic) IBOutlet UILabel       *hudText2;

@property (weak, nonatomic) IBOutlet UISlider      *slider;


@property (strong, nonatomic) IBOutlet UIView      *fractalPropertyTableHeaderView;
@property (weak, nonatomic)  IBOutlet UITextField  *fractalName;
@property (weak, nonatomic)  IBOutlet UITextField  *fractalCategory;
@property (weak, nonatomic)  IBOutlet UITextView   *fractalDescriptor;


#pragma mark Obsolete
@property (weak, nonatomic) IBOutlet UIView         *fractalPropertiesView;
@property (weak, nonatomic) IBOutlet UIView         *fractalDefinitionPlaceholderView;
@property (strong, nonatomic) IBOutlet UIView       *fractalDefinitionRulesView;
@property (strong, nonatomic) IBOutlet UIView       *fractalDefinitionAppearanceView;

#pragma mark Property Input Views
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

#pragma mark - Popovers
@property (nonatomic, strong) UIPopoverController*  colorPopover;
@property (nonatomic, strong) NSString*             coloringKey;
@property (nonatomic, strong) NSDictionary*         portraitViewFrames;


@property (nonatomic, strong) NSUndoManager *undoManager;


#pragma mark - Generation and Display
-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo;

-(void) setupLevelGeneratorForView: (UIView*) aView name: (NSString*) name forceLevel: (NSInteger) aLevel;
-(void) fitLayer: (CALayer*) layerInner inLayer: (CALayer*) layerOuter margin: (double) margin;
-(void) configureNavButtons;
-(void) reloadLabels;
-(void) refreshLayers;
-(void) refreshValueInputs;
-(void) refreshContents;

-(double) convertAndQuantizeRotationFrom: (UIRotationGestureRecognizer*)sender quanta: (double) stepRadians ratio: (double) deltaAngleToDeltaGestureRatio;

#pragma mark - Fractal Definition Input Protocol
- (void)keyTapped:(NSString*)title;
- (void)doneTapped;

#pragma mark - Gesture Actions
- (IBAction)rotateTurningAngle:(UIRotationGestureRecognizer*)gestureRecognizer;
- (IBAction)panFractal:(UIPanGestureRecognizer *)gestureRecognizer;
- (IBAction)swipeFractal:(UISwipeGestureRecognizer *)gestureRecognizer;
- (IBAction)rotateFractal:(UIRotationGestureRecognizer*)gestureRecognizer;
- (IBAction)magnifyFractal:(UILongPressGestureRecognizer*)gestureRecognizer;
- (IBAction)scaleFractal:(UIPinchGestureRecognizer *)gestureRecognizer;

#pragma mark - Button actions
- (IBAction)undoEdit:(id)sender;
- (IBAction)redoEdit:(id)sender;
- (IBAction)cancelEdit:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;

#pragma mark - Screen Controller Actions
- (IBAction)copyFractal:(id)sender;
- (IBAction)levelInputChanged: (UIControl*)sender;
- (IBAction)autoScale:(id)sender;

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
- (IBAction)incrementLineWidth: (id) sender;
- (IBAction)decrementLineWidth: (id) sender;
- (IBAction)incrementTurnAngle: (id) sender;
- (IBAction)decrementTurnAngle: (id) sender;

@end
