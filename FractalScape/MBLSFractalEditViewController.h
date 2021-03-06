//
//  MBLSFractalEditViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

@import Foundation;


#import "MBLSFractalViewController.h"
#import "FractalControllerProtocol.h"
#import "MDBNavConTransitionCoordinator.h"
#import "MBFractalPrefConstants.h"

@class MDBAppModel;
@class MDBFractalDocument;
@class MDBFractalInfo;
@class MDBDocumentController;
@class MBFractalLibraryViewController;
@class MBFractalRulesEditorViewController;
@class MBFractalAxiomEditViewController;
@class MBFractalAppearanceEditorViewController;
@class MDBFractalFiltersControllerViewController;

@class MBFractalPropertyTableHeaderView;
@class LSFractal;
@class MBLSFractalLevelNView;

// Application preference keys


@interface MBLSFractalEditViewController : UIViewController <MDBNavConTransitionProtocol>

#pragma mark Model
@property (nonatomic, copy) NSString                        *currentIdentifier;
@property (nonatomic,readonly) MDBFractalDocument           *fractalDocument;
@property (nonatomic, strong) MDBFractalInfo                *fractalInfo;
@property (nonatomic, weak) MDBAppModel                     *appModel;
@property (nonatomic, assign) BOOL                          pan10xOn;
@property (nonatomic, assign) CGFloat                       pan10xMultiplier;

@property (nonatomic, assign) BOOL                 showPerformanceData;
/*!
 When updating the image due to gestures or playback, allow the image to stay on the screen at least
 minImagePersistence seconds. This value can be varied depending on the device performance or user input.
 */
@property (nonatomic, assign) CGFloat              minImagePersistence;

@property (nonatomic, strong) NSNumberFormatter*    twoPlaceFormatter;
@property (nonatomic, strong) NSNumberFormatter*    onePlaceFormatter;
@property (nonatomic, strong) NSNumberFormatter*    percentFormatter;
@property (nonatomic, strong) NSNumberFormatter*    angleFormatter;
/*!
 Strong retain so the button can be removed from the navigationBar without being released.
 */
@property (strong,nonatomic)  IBOutlet UIBarButtonItem      *playButton;
/*!
 Strong retain so the button can be removed from the navigationBar without being released.
 */
@property (strong,nonatomic)  UIBarButtonItem      *stopButton;
@property (weak, nonatomic) IBOutlet UIButton       *editButton;
/*!
 Playback slider constraints are configured in code. The storyboard constraints are all removed at build time.
 */
@property (weak, nonatomic) IBOutlet UISlider       *playbackSlider;
@property (strong,nonatomic) IBOutlet UIButton      *toggleFullScreenButton; // strong so it can be removed and re-added with in-app purchase of pro
@property (weak, nonatomic) IBOutlet UIButton       *autoExpandOff;
@property (weak, nonatomic) IBOutlet UIButton       *applyFiltersButton;
@property (weak, nonatomic) IBOutlet UIButton       *baseRotationButton;
@property (weak, nonatomic) IBOutlet UIButton       *jointAngleButton;
@property (weak, nonatomic) IBOutlet UIButton       *incrementsButton;
@property (weak, nonatomic) IBOutlet UIButton       *hueIncrementsButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarTrailingConstraint;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *fractalViewRootSingleTapRecognizer;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *fractalViewRootDoubleTapRecognizer;

#pragma mark PanStatusIndicator Outlets
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *backgroundsToFade;

@property (weak, nonatomic) IBOutlet UIView         *panIndicatorsContainerView;
@property (weak, nonatomic) IBOutlet UIImageView    *panIndicatorCornerView;
@property (weak, nonatomic) IBOutlet UIButton       *pan10xToggleButton;

@property (weak, nonatomic) IBOutlet UILabel *panValueLabelHorizontal;
@property (weak, nonatomic) IBOutlet UILabel *panValueLabelVertical;

@property (weak, nonatomic) IBOutlet UIImageView *panIndicatorBaseAngle;
@property (weak, nonatomic) IBOutlet UIImageView *panIndicatorRandomization;
@property (weak, nonatomic) IBOutlet UIImageView *panIndicatorTurnAngle;
@property (weak, nonatomic) IBOutlet UIImageView *panIndicatorLineWidth;
@property (weak, nonatomic) IBOutlet UIImageView *panIndicatorDecrementsAngle;
@property (weak, nonatomic) IBOutlet UIImageView *panIndicatorDecrementsLine;
@property (weak, nonatomic) IBOutlet UIImageView *panIndicatorHueFill;
@property (weak, nonatomic) IBOutlet UIImageView *panIndicatorHueLine;

#pragma mark FractalLevel Nib outlets
@property (weak, nonatomic) IBOutlet UIView        *interfaceGuideView;
@property (weak, nonatomic) IBOutlet UIView        *fractalViewHolder;
@property (weak, nonatomic) IBOutlet UIView        *fractalViewRoot;
@property (weak, nonatomic) IBOutlet UIView        *fractalViewParent;
@property (weak, nonatomic) IBOutlet UIScrollView  *fractalScrollView;
@property (weak, nonatomic) IBOutlet UIImageView   *fractalView;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *fractal2PanGR;

#pragma mark FractalLevel0 Nib outlets
@property (weak, nonatomic) IBOutlet UILabel *baseAngleLabel;
@property (weak, nonatomic) IBOutlet UILabel *turningAngleLabel;
@property (weak, nonatomic) IBOutlet UILabel *turnAngleIncrementLabel;
@property (weak, nonatomic) IBOutlet UILabel *hudRandomnessLabel;
@property (weak, nonatomic) IBOutlet UILabel *hudLineAspectLabel;
@property (weak, nonatomic) IBOutlet UILabel *hudLineIncrementLabel;

#pragma mark Info HUD
@property (weak, nonatomic) IBOutlet UIView        *hudViewBackground;
@property (weak, nonatomic) IBOutlet UILabel       *hudLabel;
@property (weak, nonatomic) IBOutlet UILabel       *hudText1;
@property (weak, nonatomic) IBOutlet UILabel       *hudText2;
@property (weak, nonatomic) IBOutlet UIStepper     *hudLevelStepper;
@property (weak, nonatomic) IBOutlet UILabel       *renderTimeLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


#pragma mark - Drawing Views
@property (weak, nonatomic) IBOutlet UIImageView    *fractalViewLevel0;
@property (weak, nonatomic) IBOutlet UIImageView    *fractalViewLevel1;
@property (weak, nonatomic) IBOutlet UIImageView    *fractalViewLevel2;
@property (weak, nonatomic) IBOutlet UISlider       *baseAngleSlider;
@property (weak, nonatomic) IBOutlet UISlider       *randomnessVerticalSlider;
@property (weak, nonatomic) IBOutlet UISlider       *turnAngleSlider;
@property (weak, nonatomic) IBOutlet UISlider       *turningAngleIncrementSlider;
@property (weak, nonatomic) IBOutlet UISlider       *lineWidthVerticalSlider;
@property (weak, nonatomic) IBOutlet UISlider       *lengthIncrementVerticalSlider;


#pragma mark - Popovers
/*!
 Retained. May need to be manually nil'd to save memory. Each image generator retains/caches the image for the collectionView.
 */
@property (strong, nonatomic) MBFractalLibraryViewController            *libraryViewController;
@property (strong, nonatomic) MBFractalAppearanceEditorViewController   *appearanceViewController;

//@property (strong, nonatomic) UIActionSheet                             *shareActionsSheet;

@property (nonatomic, strong) NSUndoManager                             *undoManager;


#pragma mark - Generation and Display
-(void) setFractalInfo: (MDBFractalInfo*)fractalInfo andShowCopiedAlert: (BOOL)update;
-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo;
-(double) convertAndQuantizeRotationFrom: (UIRotationGestureRecognizer*)sender quanta: (double) stepRadians ratio: (double) deltaAngleToDeltaGestureRatio;

#pragma mark - Gesture Actions
- (IBAction)twoFingerPanFractal:(UIPanGestureRecognizer *)gestureRecognizer;

#pragma mark - Level0 Gesture Actions
- (IBAction)panLevel0:(UIPanGestureRecognizer *)sender;

#pragma mark - Level1 Gesture Actions
- (IBAction)panLevel1:(UIPanGestureRecognizer *)sender;

#pragma mark - Level2 Gesture Actions
- (IBAction)panLevel2:(UIPanGestureRecognizer *)sender;

#pragma mark - Toolbar Button actions
- (IBAction)copyFractal:(id)sender;
- (IBAction)undoEdit:(id)sender;
- (IBAction)redoEdit:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)shareButtonPressed:(id)sender;
- (IBAction)playButtonPressed:(id)sender;
-(IBAction) pauseButtonPressed: (id)sender;
- (IBAction)stopButtonPressed:(id)sender;
-(IBAction) playSliderChangedValue: (UISlider*)slider;
-(IBAction) toggleAutoExpandFractal:(id)sender;
- (IBAction)toggleNavBar:(id)sender;
- (IBAction)moveTwoFingerPanToBaseRotation:(UIButton *)sender;
- (IBAction)moveTwoFingerPanToJointAngle:(UIButton *)sender;
- (IBAction)moveTwoFingerPanToIncrements:(UIButton *)sender;
- (IBAction)moveTwoFingerPanToHueIncrements:(UIButton *)sender;
- (IBAction)togglePan10x:(UIButton *)sender;

#pragma mark - HUD Sliders
- (IBAction)baseAngleSliderChanged:(id)sender;
- (IBAction)turnAngleSliderChanged:(id)sender;
- (IBAction)turningAngleIncrementSliderChanged:(id)sender;
- (IBAction)randomnessSliderChanged:(id)sender;
- (IBAction)lineWidthSliderChanged:(id)sender;
- (IBAction)lineLengthIncrementSliderChanged:(id)sender;

#pragma mark - Screen Controller Actions
- (IBAction)levelInputChanged: (UIControl*)sender;
- (IBAction)autoScale:(id)sender;

#pragma mark - Segue Actions
- (IBAction)unwindFromEditorIntro:(UIStoryboardSegue *)segue;
- (IBAction)unwindFromPurchaseController:(UIStoryboardSegue *)segue;
- (IBAction)unwindFromAppearanceController:(UIStoryboardSegue *)segue;
- (IBAction)unwindToPresentPurchaseController:(UIStoryboardSegue *)segue;

-(IBAction)showHelpScreen:(id)sender;
-(IBAction) upgradeToProSelected:(id)sender;

#pragma mark - Filter Actions
- (IBAction)toggleApplyFilter:(id)sender;

#pragma mark - NavConTransitionProtocol
@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      pushTransition;
@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      popTransition;
@property (nonatomic,assign) CGRect                                         transitionDestinationRect;
@property (nonatomic,assign) CGRect                                         transitionSourceRect;

-(void) presentPurchaseOptions;

@end
