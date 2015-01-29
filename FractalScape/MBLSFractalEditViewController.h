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
@class MBFractalRulesEditorViewController;
@class MBFractalAxiomEditViewController;
@class MBFractalAppearanceEditorViewController;

@class MBFractalPropertyTableHeaderView;
@class LSFractal;
@class MBLSFractalLevelNView;

// Application preference keys
static NSString*  kPrefLastEditedFractalURI = @"lastEditedFractalURI";
static NSString*  kPrefFullScreenState = @"fullScreenState";
static NSString*  kPrefShowPerformanceData = @"showPerformanceData";


@interface MBLSFractalEditViewController : UIViewController <UIGestureRecognizerDelegate,
UIPopoverControllerDelegate, UIActionSheetDelegate, UIPopoverPresentationControllerDelegate, UIScrollViewDelegate, UIDocumentInteractionControllerDelegate>

#pragma mark Model
@property (nonatomic, strong) LSFractal            *fractal;
/*!
 Change some performance parameters based the device. Default is high performance.
 */
@property (nonatomic, assign) BOOL                 lowPerformanceDevice;
@property (nonatomic, assign) BOOL                 showPerformanceData;
/*!
 When updating the image due to gestures or playback, allow the image to stay on the screen at least
 minImagePersistence seconds. This value can be varied depending on the device performance or user input.
 */
@property (nonatomic, assign) CGFloat              minImagePersistence;

@property (nonatomic, strong) NSNumberFormatter*    twoPlaceFormatter;
@property (nonatomic, strong) NSNumberFormatter*    percentFormatter;
//@property (weak, nonatomic) IBOutlet UILabel                *toolbarTitle;
//@property (weak, nonatomic) IBOutlet UIToolbar              *toolbar;
@property (strong, nonatomic)  UIBarButtonItem      *playButton;
@property (strong, nonatomic)  UIBarButtonItem      *stopButton;
@property (weak, nonatomic) IBOutlet UIButton       *editButton;
@property (weak, nonatomic) IBOutlet UISlider       *playbackSlider;

#pragma mark FractalLevel Nib outlets
@property (weak, nonatomic) IBOutlet UIView        *fractalViewHolder;
@property (weak, nonatomic) IBOutlet UIView        *fractalViewRoot;
@property (weak, nonatomic) IBOutlet UIView        *fractalViewParent;
@property (weak, nonatomic) IBOutlet UIScrollView  *fractalScrollView;
@property (weak, nonatomic) IBOutlet UIImageView   *fractalView;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *fractal2PanGR;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toggleFullScreenButton;

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


#pragma mark - Drawing Views
@property (weak, nonatomic) IBOutlet UIImageView    *fractalViewLevel0;
@property (weak, nonatomic) IBOutlet UIImageView    *fractalViewLevel1;
@property (weak, nonatomic) IBOutlet UIImageView    *fractalViewLevel2;
@property (weak, nonatomic) IBOutlet UISlider       *baseAngleSlider;
@property (weak, nonatomic) IBOutlet UISlider       *randomnessVerticalSlider;
@property (weak, nonatomic) IBOutlet UISlider       *turnAngleSlider;
@property (weak, nonatomic) IBOutlet UISlider       *turnIncrementSlider;
@property (weak, nonatomic) IBOutlet UISlider       *widthDecrementVerticalSlider;
@property (weak, nonatomic) IBOutlet UISlider       *lengthIncrementVerticalSlider;


#pragma mark - Popovers
@property (strong, nonatomic) MBFractalLibraryViewController            *libraryViewController;
@property (strong, nonatomic) MBFractalAppearanceEditorViewController   *appearanceViewController;

//@property (strong, nonatomic) UIActionSheet                             *shareActionsSheet;

@property (nonatomic, strong) NSUndoManager                             *undoManager;


#pragma mark - Generation and Display
-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo;

-(void) updateNavButtons;

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
- (IBAction)libraryButtonPressed:(id)sender;
- (IBAction)appearanceButtonPressed:(id)sender;
- (IBAction)shareButtonPressed:(id)sender;
- (IBAction)playButtonPressed:(id)sender;
-(IBAction) pauseButtonPressed: (id)sender;
- (IBAction)stopButtonPressed:(id)sender;
-(IBAction) playSliderChangedValue: (UISlider*)slider;

#pragma mark - Screen Controller Actions
- (IBAction)levelInputChanged: (UIControl*)sender;
- (IBAction)autoScale:(id)sender;

@end
