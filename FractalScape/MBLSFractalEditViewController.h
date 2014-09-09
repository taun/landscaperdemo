//
//  MBLSFractalEditViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBLSFractalViewController.h"

@class MBFractalLibraryViewController;
@class MBFractalLineSegmentsEditorViewController;
@class MBFractalAxiomEditViewController;
@class MBFractalAppearanceEditorViewController;

@class MBFractalPropertyTableHeaderView;
@class LSFractal;
@class MBLSFractalLevelNView;

// Application preference keys
static NSString*  kLastEditedFractalURI = @"lastEditedFractalURI";


@interface MBLSFractalEditViewController : UIViewController <UIGestureRecognizerDelegate,
UIPopoverControllerDelegate, UIActionSheetDelegate, UIPopoverPresentationControllerDelegate>

#pragma mark Model
@property (nonatomic, strong) LSFractal            *fractal;

/* So a setNeedsDisplay can be sent to each layer when a fractal property is changed. */
@property (nonatomic, strong) NSMutableArray*               fractalDisplayLayersArray;
/* a generator for each level being displayed. */
@property (nonatomic, strong) NSMutableArray*               generatorsArray;
@property (nonatomic, strong) NSNumberFormatter*            twoPlaceFormatter;
#pragma message "Unused"
@property (nonatomic, strong) UIBarButtonItem*              spaceButtonItem;
@property (weak, nonatomic) IBOutlet UILabel                *toolbarTitle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem        *appearanceButton;

#pragma mark FractalLevel Nib outlets
@property (weak, nonatomic) IBOutlet UIView        *fractalViewHolder;
@property (weak, nonatomic) IBOutlet UIView        *fractalViewRoot;
@property (weak, nonatomic) IBOutlet UIView        *fractalViewParent;
@property (weak, nonatomic) IBOutlet UIView        *fractalView;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *fractalPanGR;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *fractal2PanGR;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *fractalRightSwipeGR;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *fractalLeftSwipeGR;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *fractalUpSwipeGR;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *fractalDownSwipeGR;
@property (weak, nonatomic) IBOutlet UIPinchGestureRecognizer *fractalPinchGR;
@property (weak, nonatomic) IBOutlet UIRotationGestureRecognizer *fractalRotationGR;

#pragma mark FractalLevel0 Nib outlets

#pragma mark FractalLevel1 Nib outlets

#pragma mark Info HUD
@property (weak, nonatomic) IBOutlet UIView        *hudViewBackground;
@property (weak, nonatomic) IBOutlet UILabel       *hudLabel;
@property (weak, nonatomic) IBOutlet UILabel       *hudText1;
@property (weak, nonatomic) IBOutlet UILabel       *hudText2;
@property (weak, nonatomic) IBOutlet UIStepper     *hudLevelStepper;


#pragma mark Obsolete
//@property (weak, nonatomic) IBOutlet UIView         *fractalPropertiesView;
@property (weak, nonatomic) IBOutlet UIView         *fractalDefinitionPlaceholderView;
@property (strong, nonatomic) IBOutlet UIView       *fractalDefinitionRulesView;
@property (strong, nonatomic) IBOutlet UIView       *fractalDefinitionAppearanceView;

#pragma mark Property Input Views
@property (weak, nonatomic) IBOutlet UIView             *fractalEditorsHolder;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fractalEditorsHolderHeightConstraint;


#pragma mark - Drawing Views
//@property (weak, nonatomic) IBOutlet UILabel        *fractalViewLevelNLabel;
@property (weak, nonatomic) IBOutlet UIView         *fractalViewLevel0;
@property (weak, nonatomic) IBOutlet UIView         *fractalViewLevel1;
@property (weak, nonatomic) IBOutlet UIView         *fractalViewLevel2;


#pragma mark - Popovers
@property (strong, nonatomic) MBFractalLibraryViewController            *libraryViewController;
@property (strong, nonatomic) MBFractalAppearanceEditorViewController   *appearanceViewController;

//@property (strong, nonatomic) UIActionSheet                             *shareActionsSheet;

@property (nonatomic, strong) NSDictionary                              *portraitViewFrames;

@property (nonatomic, strong) NSUndoManager                             *undoManager;


#pragma mark - Generation and Display
-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo;

-(void) setupLevelGeneratorForFractal: (LSFractal*) fractal View: (UIView*) aView name: (NSString*) name forceLevel: (NSInteger) aLevel;
-(void) fitLayer: (CALayer*) layerInner inLayer: (CALayer*) layerOuter margin: (double) margin;
-(void) configureNavButtons;
-(void) refreshLayers;
-(void) refreshValueInputs;
-(void) refreshContents;

-(double) convertAndQuantizeRotationFrom: (UIRotationGestureRecognizer*)sender quanta: (double) stepRadians ratio: (double) deltaAngleToDeltaGestureRatio;

#pragma mark - Gesture Actions
- (IBAction)rotateTurningAngle:(UIRotationGestureRecognizer*)gestureRecognizer;
- (IBAction)panFractal:(UIPanGestureRecognizer *)gestureRecognizer;
- (IBAction)swipeFractal:(UISwipeGestureRecognizer *)gestureRecognizer; //obsolete
- (IBAction)rotateFractal:(UIRotationGestureRecognizer*)gestureRecognizer;
- (IBAction)magnifyFractal:(UILongPressGestureRecognizer*)gestureRecognizer;
- (IBAction)scaleFractal:(UIPinchGestureRecognizer *)gestureRecognizer;
- (IBAction)twoFingerPanFractal:(UIPanGestureRecognizer *)gestureRecognizer;

#pragma mark - Level0 Gesture Actions
- (IBAction)panLevel0:(UIPanGestureRecognizer *)sender;

#pragma mark - Level1 Gesture Actions

#pragma mark - Toolbar Button actions
- (IBAction)undoEdit:(id)sender;
- (IBAction)redoEdit:(id)sender;
- (IBAction)cancelEdit:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)libraryButtonPressed:(id)sender;
- (IBAction)appearanceButtonPressed:(id)sender;
- (IBAction)shareButtonPressed:(id)sender;

#pragma mark - Screen Controller Actions
- (IBAction)copyFractal:(id)sender;
- (IBAction)levelInputChanged: (UIControl*)sender;
- (IBAction)autoScale:(id)sender;

#pragma mark - Description Control Actions
//- (IBAction)nameInputDidEnd:(UITextField*)sender;
//- (IBAction)switchFractalDefinitionView:(UISegmentedControl*)sender;


#pragma mark - Appearance Control Actions
//- (IBAction)lineLengthInputChanged: (UIStepper*)sender;
//- (IBAction)lineLengthScaleFactorInputChanged: (UIStepper*)sender;
//- (IBAction)lineWidthInputChanged: (id)sender;
//- (IBAction)lineWidthIncrementInputChanged: (id)sender;
//- (IBAction)turningAngleInputChanged: (UIStepper*)sender;
//- (IBAction)turningAngleIncrementInputChanged: (UIStepper*)sender;
- (IBAction)incrementLineWidth: (id) sender;
- (IBAction)decrementLineWidth: (id) sender;
- (IBAction)incrementTurnAngle: (id) sender;
- (IBAction)decrementTurnAngle: (id) sender;

@end
