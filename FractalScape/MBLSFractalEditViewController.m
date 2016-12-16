//
//  MBLSFractalEditViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//
@import UIKit;
@import QuartzCore;
@import ImageIO;
@import AssetsLibrary;
@import ReplayKit;

#include <math.h>

#import "FractalScapeIconSet.h"
#import "MBAppDelegate.h"
#import "MDBAppModel.h"
#import "MBLSFractalEditViewController.h"
#import "FractalControllerProtocol.h"
#import "MDBCustomTransition.h"
#import "MBFractalLibraryViewController.h"
#import "MBFractalAppearanceEditorViewController.h"
#import "MBFractalRulesEditorViewController.h"
#import "MDBFractalFiltersControllerViewController.h"
#import "LSReplacementRule.h"
#import "LSFractal.h"
#import "MBColor.h"
#import "MBImageFilter.h"
#import "MDBDocumentController.h"
#import "MDBFractalDocumentCoordinator.h"
#import "MDBFractalInfo.h"
#import "MDBFractalDocument.h"
#import "LSFractalRenderer.h"
#import "MDBTileObjectProtocol.h"
#import "MDBEditorHelpTransitioningDelegate.h"
#import "MDBEditorIntroWhatIsFractalViewController.h"
#import "MDBPurchaseViewController.h"
#import "MDLCloudKitManager.h"

#import "UIFont+MDKProportional.h"
#import "FBKVOController.h"

#import <Crashlytics/Crashlytics.h>

//
//static inline double radians (double degrees){return degrees * M_PI/180.0;}
//static inline double degrees (double radians){return radians * 180.0/M_PI;}
#define LOGBOUNDS 0
#define DEBUGRENDERTIME

static NSString* kLibrarySelectionKeypath = @"selectedFractal";
static const BOOL SIMULTOUCH = NO;
static const CGFloat kHighPerformanceFrameRate = 4.0;
static const CGFloat kLowPerformanceFrameRate = 4.0;
static const CGFloat kHudLevelStepperDefaultMax = 16.0;
static const CGFloat kLevelNMargin = 48.0;

@interface MBLSFractalEditViewController ()  <UIGestureRecognizerDelegate,
UIActionSheetDelegate,
UIPopoverPresentationControllerDelegate,
UIScrollViewDelegate,
UIDocumentInteractionControllerDelegate,
FractalControllerDelegate,
MDBFractalDocumentDelegate,
RPPreviewViewControllerDelegate>

@property (nonatomic,assign) BOOL                   startedInLandscape;
@property (nonatomic,assign) BOOL                   hasBeenEdited;
@property (nonatomic,assign) CGFloat                pan10xValue;
@property (nonatomic,strong) NSTimer                *panIndicatorBackgroundFadeTimer;

//@property (nonatomic, strong) NSSet*                editControls;
//@property (nonatomic, strong) NSMutableArray*       cachedEditViews;
//@property (nonatomic, assign) NSInteger             cachedEditorsHeight;

@property (nonatomic, assign) double                viewNRotationFromStart;

@property (nonatomic,strong) UIMotionEffectGroup    *foregroundMotionEffect;
@property (nonatomic,strong) UIMotionEffectGroup    *backgroundMotionEffect;
@property (nonatomic,strong) UIBarButtonItem        *shareButton;
@property (nonatomic, strong) UIBarButtonItem*      cancelButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      undoButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      redoButtonItem;
//@property (nonatomic, strong) NSArray*              disabledDuringPlaybackButtons;
@property (nonatomic, strong) NSArray*              editPassThroughViews;

@property (nonatomic,weak) UIViewController*        currentPresentedController;
@property (nonatomic,assign) BOOL                   previousNavBarState;

@property (nonatomic, strong) dispatch_queue_t      levelDataGenerationQueue;
@property (nonatomic,strong) NSArray                *levelDataArray;
/*!
 Fractal background image generation queue.
 */
@property (nonatomic,readonly,strong) NSOperationQueue     *privateImageGenerationQueue;
@property (nonatomic, strong) NSTimer                      *privateImageGenerationQueueTimeoutTimer;
@property (nonatomic,assign) CGFloat                       imageGenerationTimout;
@property (nonatomic,readonly,strong) NSOperationQueue     *exportImageGenerationQueue;
@property (nonatomic,assign) NSInteger                     nodeLimit;
@property (nonatomic,strong) LSFractalRenderer             *fractalRendererL0;
@property (nonatomic,strong) LSFractalRenderer             *fractalRendererL1;
@property (nonatomic,strong) LSFractalRenderer             *fractalRendererL2;
@property (nonatomic,strong) LSFractalRenderer             *fractalRendererLN;
@property (nonatomic,assign) BOOL                          autoscaleN;
@property (nonatomic,strong) NSDate                        *lastImageUpdateTime;

@property (nonatomic,strong) NSTimer                       *playbackTimer;
@property (nonatomic,assign) CGFloat                       playFrameIncrement;
@property (nonatomic,assign) CGFloat                       playIsPercentCompleted;
@property (nonatomic,strong) NSArray                       *playbackRenderers;
@property (readonly,assign) CGContextRef                   filterBitmapContext;
@property (nonatomic,strong) NSDictionary                  *twoFingerPanProperties;
@property (nonatomic,strong) NSArray                       *panIndicators;
@property (nonatomic,strong) NSArray                       *panToolbarButtons;

@property (nonatomic,strong) UIDocumentInteractionController *documentShareController;
@property (nonatomic,strong, readonly) FBKVOController       *kvoController;
@property (nonatomic,weak) LSFractal                        *observedFractal;
@property (nonatomic,weak) id<MDBFractaDocumentProtocol>    observedDocument;
@property (nonatomic,strong) NSMutableSet                   *observedReplacementRules;

@property (nonatomic,strong) RPPreviewViewController        *previewViewController;

#pragma mark - Undo Handling
@property (nonatomic,strong) LSFractal                      *originalFractal;
@property (nonatomic,strong) UIImage                        *originalThumbnail;


//-(void) setEditMode: (BOOL) editing;
-(void) fullScreenOn;
-(void) fullScreenOff;

-(void) playNextFrame: (NSTimer*)timer;

- (void)updateUndoRedoBarButtonState;
- (void)setUpUndoManager;
- (void)cleanUpUndoManager;

-(void) logGroupingLevelFrom: (NSString*) cmd;
@end

#pragma mark -
#pragma mark ** Implementation
#pragma mark -
/*!
 Could setup KVO for model proerties to fields.
 Would be same as using bindings.
 */

@implementation MBLSFractalEditViewController

@synthesize undoManager = _undoManager;
@synthesize privateImageGenerationQueue = _privateImageGenerationQueue;
@synthesize exportImageGenerationQueue = _exportImageGenerationQueue;
//@synthesize fractal = _fractal;
@synthesize filterBitmapContext = _filterBitmapContext;
@synthesize kvoController = _kvoController;

#pragma mark Init
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}
-(void) awakeFromNib
{
    [super awakeFromNib];
    _minImagePersistence = 1.0/kHighPerformanceFrameRate;
    _pan10xValue = 1.0;
    _pan10xMultiplier = 10.0;
    
    _imageGenerationTimout = 6.0;
    
    _nodeLimit = kLSMaxNodesHiPerf;
    
    /*
     FractalScape rendering is much faster on the 64bit devices.
     Coincidentally, the 64 bit devices all have the MotionProcessor which can store activity data.
     We use the isActivityAvailable call to set app performance parameters.
     */
    if (![CMMotionActivityManager isActivityAvailable])
    {
        [self updatePropertiesForLowPerformanceDevice];
    }
    
    self.popTransition = [MDBZoomPopBounceTransition new];
    self.pushTransition = [MDBZoomPushBounceTransition new];
}

#pragma mark - UIViewController Methods
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    [self.privateImageGenerationQueue cancelAllOperations];
    if (_filterBitmapContext != NULL) {
        CGContextRelease(_filterBitmapContext);
        _filterBitmapContext = NULL;
    }
}

-(void) configureParallax
{
    BOOL showParalax = self.appModel.showParallax;
    
    if (showParalax) {
        CGFloat scale = self.view.bounds.size.width /  415.0;
        
        UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xAxis.minimumRelativeValue = @(18.0*scale);
        xAxis.maximumRelativeValue = @(-18.0*scale);
        
        UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yAxis.minimumRelativeValue = @(24.0*scale);
        yAxis.maximumRelativeValue = @(-24.0*scale);
        
        self.backgroundMotionEffect = [[UIMotionEffectGroup alloc] init];
        self.backgroundMotionEffect.motionEffects = @[xAxis, yAxis];
        
        
        UIInterpolatingMotionEffect *xFAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xFAxis.minimumRelativeValue = @(6.0*scale);
        xFAxis.maximumRelativeValue = @(-6.0*scale);
        
        UIInterpolatingMotionEffect *yFAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yFAxis.minimumRelativeValue = @(8.0*scale);
        yFAxis.maximumRelativeValue = @(-8.0*scale);
        
        self.foregroundMotionEffect = [[UIMotionEffectGroup alloc] init];
        self.foregroundMotionEffect.motionEffects = @[xFAxis, yFAxis];
        
        UIView* fractalCanvas = [self.fractalView superview];
        [fractalCanvas addMotionEffect: self.backgroundMotionEffect];
        [self.fractalViewRoot addMotionEffect: self.foregroundMotionEffect];
    }
}

-(void) configureNavBarButtons
{
    MDBAppModel* strongAppModel = self.appModel;
    
    self.stopButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem: UIBarButtonSystemItemStop
                                                                   target: self
                                                                   action: @selector(stopButtonPressed:)];
    
    //    UIBarButtonItem* backButton = [[UIBarButtonItem alloc]initWithTitle: @"Library"
    //                                                                  style: UIBarButtonItemStylePlain
    //                                                                 target: self
    //                                                                 action: @selector(backToLibrary:)];
    
    UIBarButtonItem* helpButton = [[UIBarButtonItem alloc]initWithImage: [UIImage imageNamed: @"tabBarInfoThin"]
                                                                  style: UIBarButtonItemStylePlain
                                                                 target: self
                                                                 action: @selector(showHelpScreen:)];
    
    NSString* shareLocalized = NSLocalizedString(@"Share", @"share button title");
    _shareButton = [[UIBarButtonItem alloc]initWithTitle: shareLocalized style: UIBarButtonItemStylePlain target: self action: @selector(shareButtonPressed:)];
    
//    _disabledDuringPlaybackButtons = @[self.autoExpandOff, _shareButton];
    
    [self.navigationItem setHidesBackButton: YES animated: NO];
    self.navigationItem.leftItemsSupplementBackButton = YES;
    //    self.navigationItem.backBarButtonItem = backButton;
    
    NSMutableArray* items = [self.navigationItem.leftBarButtonItems mutableCopy];
    if (!items) {
        items = [NSMutableArray new];
    }
    //    [items addObject: backButton];
//    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace target:nil action:NULL];
    space.width = 20.0;
    [items addObject: space];
    [items addObject: _shareButton];
    [self.navigationItem setLeftBarButtonItems: items];
    
    
    
    items = [self.navigationItem.rightBarButtonItems mutableCopy];
    [items addObject: helpButton];
    [items addObject: space];
    [self.navigationItem setRightBarButtonItems: items];
    
    self.previousNavBarState = NO;
    
    self.showPerformanceData = strongAppModel.showPerformanceData;
    
    if (!strongAppModel.allowPremium)
    {
        [self fullScreenOnDuration: 0];
        [self.toggleFullScreenButton removeFromSuperview];
    }
    else
    {
        if (strongAppModel.fullScreenState)
        {
            [self fullScreenOn];
        }
        else
        {
            [self fullScreenOff];
        }
    }
}

-(void)setupHUDSlider: (UISlider*)slider forProperty:(NSString*)propertyKey rotatedDegrees:(CGFloat)rotation
{
    UIImage* sliderCircleImage = [UIImage imageNamed: @"controlDragCircle"];
    slider.transform = CGAffineTransformMakeRotation(radians(rotation));
    [slider setThumbImage: sliderCircleImage forState: UIControlStateNormal];
    slider.minimumValue = [self.fractalDocument.fractal minValueForProperty: propertyKey];
    slider.maximumValue = [self.fractalDocument.fractal maxValueForProperty: propertyKey];
    slider.value = degrees([[self.fractalDocument.fractal valueForKey: propertyKey] floatValue]);
    
}

-(void)setupSlidersForCurrentFractal
{
    [self setupHUDSlider: _randomnessVerticalSlider forProperty: @"randomness" rotatedDegrees: -90.0];
    [self setupHUDSlider: _baseAngleSlider forProperty: @"baseAngle" rotatedDegrees: 0.0];
    [self setupHUDSlider: _lineWidthVerticalSlider forProperty: @"lineWidth" rotatedDegrees: 90.0];
    [self setupHUDSlider: _turnAngleSlider forProperty: @"turningAngle" rotatedDegrees: 0.0];
    [self setupHUDSlider: _lengthIncrementVerticalSlider forProperty: @"lineChangeFactor" rotatedDegrees: -90.0];
    [self setupHUDSlider: _turningAngleIncrementSlider forProperty: @"turningAngleIncrement" rotatedDegrees: 0.0];
}

#pragma message "TODO: add variables for max,min values for angles, widths, .... Add to model, class fractal category???"
-(void)viewDidLoad
{
    [super viewDidLoad];
    
    //    [[UINavigationBar appearanceWhenContainedIn: [self class],nil] setBarTintColor: self.view.tintColor];
    
    //    [self.navigationController.navigationBar setBarTintColor: [UIColor redColor]];
    
    _filterBitmapContext = NULL;
    
    self.panValueLabelHorizontal.font = [UIFont proportionalForExistingFont: self.panValueLabelHorizontal.font];
    self.panValueLabelVertical.font = [UIFont proportionalForExistingFont: self.panValueLabelVertical.font];
    self.hudText1.font = [UIFont proportionalForExistingFont: self.hudText1.font];
    self.turningAngleLabel.font = [UIFont proportionalForExistingFont: self.turningAngleLabel.font];
    
    [self configureNavBarButtons];
    
    _observedReplacementRules = [NSMutableSet new];
    
    {
        _panIndicators = @[_panIndicatorBaseAngle, _panIndicatorRandomization,
                           _panIndicatorTurnAngle, _panIndicatorLineWidth,
                           _panIndicatorDecrementsAngle, _panIndicatorDecrementsLine,
                           _panIndicatorHueFill, _panIndicatorHueLine];
        
        _panToolbarButtons = @[ _baseRotationButton,
                                _jointAngleButton,
                                _incrementsButton,
                                _hueIncrementsButton];
        
        UIPanGestureRecognizer* scrollPanGesture = self.fractalScrollView.panGestureRecognizer;
        [scrollPanGesture setMaximumNumberOfTouches: 2];
        [scrollPanGesture setMinimumNumberOfTouches: 2];
        
        [self.fractalViewRootSingleTapRecognizer requireGestureRecognizerToFail: self.fractalViewRootDoubleTapRecognizer];
    }
    //    self.fractalDocument.fractal = [self getUsersLastFractal];
    
    UIImage* sliderCircleImage = [UIImage imageNamed: @"controlDragCircle"];
    
    UISlider* strongPlayback = _playbackSlider;
    strongPlayback.hidden = YES;
    strongPlayback.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [strongPlayback setThumbImage: sliderCircleImage forState: UIControlStateNormal];
    
    // Setup the scrollView to allow the fractal image to float.
    // This is to allow the user to move the fractal out from under the HUD display.
    UIView* fractalCanvas = self.fractalView.superview;
    fractalCanvas.layer.shadowColor = [[UIColor blackColor] CGColor];
    fractalCanvas.layer.shadowOffset = CGSizeMake(5.0, 5.0);
    fractalCanvas.layer.shadowOpacity = 0.3;
    fractalCanvas.layer.shadowRadius = 3.0;
    
    self.fractalView.contentScaleFactor = [[UIScreen mainScreen] scale];
    
    [self configureParallax]; // here so changing the setting in user settings can take effect
}

-(void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

/*!
 Want to monitor the layout to resize the fractal layer of fractalViewLevelN.
 Always fit the layer in the view on layout.
 Can change the layer scale or the frame and redraw the layer?
 
 When loading the view in landscape mode, the layout gets done twice.
 Once when loaded but with the portrait bounds.
 Then with the landscape bounds.
 */
-(void) viewDidLayoutSubviews
{
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    //    [self autoScale: nil];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [[UIApplication sharedApplication] setStatusBarHidden: YES];
    
    self.hasBeenEdited = NO;
    
    self.showPerformanceData = self.appModel.showPerformanceData;
    
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    
    //    self.navigationItem.title = self.fractalDocument.fractal.name;
    self.fractalInfo.document.delegate = self;
    [self addObserverForFractalChangeInDocument: self.fractalInfo.document];
    
    [self hideToolPaletteWithAnimations: NO];
}

/* on startup, fractal should not be set until just before view didAppear */
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.fractalDocument.fractal.name != nil)
    {
        [Answers logContentViewWithName: NSStringFromClass([self class]) contentType: @"Fractal" contentId: NSStringFromClass([self class]) customAttributes: @{@"Name": self.fractalDocument.fractal.name}];
    }
    
    MDBAppModel* strongAppModel = self.appModel;
    
    if (!strongAppModel.allowPremium) // in-app purchase can only be done from settings so this should never change while the view is on screen.
    {
        [self.toggleFullScreenButton removeFromSuperview];
    }
    else
    {
        [self.toggleFullScreenButton removeFromSuperview];
    }
    
    UIEdgeInsets scrollInsets = UIEdgeInsetsMake(300.0, 300.0, 300.0, 300.0);
    
    if (!UIEdgeInsetsEqualToEdgeInsets(self.fractalScrollView.contentInset , scrollInsets))
    {
        //        self.fractalScrollView.bounds = CGRectInset(self.fractalScrollView.bounds, -300.0, -300.0);
        self.fractalScrollView.contentInset = scrollInsets;
        self.fractalScrollView.contentOffset = CGPointZero;
    }
    
    [self updateEditorContent];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(updateUIDueToUserSettingsChange)
                                                 name: NSUserDefaultsDidChangeNotification
                                               object: nil];
    
    //    self.navigationController.navigationBar.hidden = YES;
    //    [self.navigationController setNavigationBarHidden: YES animated: YES];
    if (!strongAppModel.editorIntroDone)
    {
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //            [self firstStartupSequence];
        //        });
        [self showHelpScreen: nil];
        [strongAppModel exitEditorIntroState];
    }
    [self showToolPalleteWithAnimations: YES];
}

-(void)showToolPalleteWithAnimations: (BOOL)animate
{
    CGFloat newBarConstant = -8.0;
    
    if (self.toolbarTrailingConstraint.constant == newBarConstant) return;
    
    self.toolbarTrailingConstraint.constant = newBarConstant;
    [self.fractalViewRoot setNeedsUpdateConstraints];
    
    if (animate)
    {
        [UIView animateWithDuration: 2.0 delay: 0.1
             usingSpringWithDamping: 0.5
              initialSpringVelocity: 0.0
                            options: UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [self.fractalViewRoot layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             //
                             [self startPanBackgroundFadeTimer];
                         }];
    }
    else
    {
        [self.fractalViewRoot layoutIfNeeded];
    }
    
    self.hudViewBackground.alpha = 1.0;
    self.panIndicatorsContainerView.alpha = 1.0;
}

-(void)hideToolPaletteWithAnimations: (BOOL)animate
{
    CGFloat newBarConstant = -70.0;

    if (self.toolbarTrailingConstraint.constant == newBarConstant) return;

    self.toolbarTrailingConstraint.constant = newBarConstant;
    [self.fractalViewRoot setNeedsUpdateConstraints];

    if (animate)
    {
        [UIView animateWithDuration: 0.5 delay: 0.1
             usingSpringWithDamping: 1.0
              initialSpringVelocity: 0.0
                            options: UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [self.fractalViewRoot layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             //
                         }];
    }
    else
    {
        [self.fractalViewRoot layoutIfNeeded];
    }
    
    self.hudViewBackground.alpha = 0.0;
    self.panIndicatorsContainerView.alpha = 0.0;
}

-(IBAction)showHelpScreen:(id)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"ShowHelpScreen"}];
    
    [self performSegueWithIdentifier: @"QuickIntroSegue" sender: sender];
}

- (IBAction)unwindFromEditorIntro:(UIStoryboardSegue *)segue
{
    //    UIViewController* sourceController = (UIViewController*)segue.sourceViewController;
    [self dismissViewControllerAnimated: YES completion:^{
        [self.appModel exitEditorIntroState];
        //        for (UIBarButtonItem* button in self.navigationItem.rightBarButtonItems)
        //        {
        //            button.enabled = YES;
        //        }
        //        for (UIBarButtonItem* button in self.navigationItem.leftBarButtonItems)
        //        {
        //            button.enabled = YES;
        //        }
    }];
}

- (void) setupPageControlAppearance
{
    [[UIPageControl appearance] setPageIndicatorTintColor: [UIColor lightGrayColor]];
    [[UIPageControl appearance] setCurrentPageIndicatorTintColor: self.view.tintColor];
    //    [[UIPageControl appearance] setBackgroundColor: [UIColor darkGrayColor]];
}
-(void)updateUIDueToUserSettingsChange
{
    [self updateEditorContent];
}
/*!
 Change this to use the current appModel state for determining whether to show tutorial steps or just screen.
 */
-(void) updateEditorContent
{
    if (self.presentedViewController) // dismiss any popovers, what about modal tutorial?
    {
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }
    
    
    if (self.fractalInfo.document != nil && self.fractalInfo.document.fractal && self.isViewLoaded && self.view.superview)
    {
        [self moveTwoFingerPanToJointAngle: nil]; //default
        [self regenerateLevels];
        [self updateInterface];
        [self autoScale: nil];
        
    }
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //    [self.exportImageGenerationQueue waitUntilAllOperationsAreFinished];
    [self removeObserversForObservedDocument];
    
    [self.panIndicatorBackgroundFadeTimer invalidate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void)dealloc
{
    if (_filterBitmapContext != NULL) CGContextRelease(_filterBitmapContext);
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        //        [self queueFractalImageUpdates];
        [self updateViewController: self.currentPresentedController popoverPreferredContentSizeForViewSize: size];
        //        self.fractalView.position = fractalNewPosition;
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        [self updateFilterSettingsForCanvas];
        [self queueFractalImageUpdates];
    }];
    //    subLayer.position = self.fractalView.center;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    // Return YES for supported orientations
    return YES;
}

-(void)updateFilterSettingsForCanvas
{
    for (MBImageFilter* filter in self.fractalDocument.fractal.imageFilters)
    {
        CGSize size = self.fractalView.bounds.size;
        
        CGRect filterBounds = CGRectMake(0.0, 0.0, size.width*[[UIScreen mainScreen] scale], size.height*[[UIScreen mainScreen] scale]);
        [filter setGoodDefaultsForbounds: filterBounds];
    }
}


#pragma mark - Getters & Setters

-(void)setHasBeenEdited:(BOOL)hasBeenEdited
{
    if (_hasBeenEdited != hasBeenEdited)
    {
        _hasBeenEdited = hasBeenEdited;
    }
}

-(CGContextRef)filterBitmapContext
{
    UIImageView*strongView = self.fractalView;
    
    CGSize viewSize = strongView.bounds.size;
    CGSize scaledSize = CGSizeMake(viewSize.width*[[UIScreen mainScreen] scale], viewSize.height*[[UIScreen mainScreen] scale]);
    CGRect scaledRect = CGRectMake(0, 0, scaledSize.width, scaledSize.height);
    
    int width = scaledSize.width;
    int height = scaledSize.height;
    int bytesPerRow = 4 * width;
    
    if (_filterBitmapContext == NULL && strongView)
    {
        _filterBitmapContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, [MBImageFilter colorSpace], kCGImageAlphaPremultipliedLast);
        [self updateFilterSettingsForCanvas];
    }
    else if (!CGRectEqualToRect(CGContextGetClipBoundingBox(_filterBitmapContext), scaledRect))
    {
        //        self.contextNSData = nil;
        //
        //        self.imageRef = NULL;
        
        CGContextRelease(_filterBitmapContext);
        _filterBitmapContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, [MBImageFilter colorSpace], kCGImageAlphaPremultipliedLast);
        [self updateFilterSettingsForCanvas];
    }
    
    return _filterBitmapContext;
}


-(dispatch_queue_t) levelDataGenerationQueue{
    if (!_levelDataGenerationQueue) {
        _levelDataGenerationQueue = dispatch_queue_create("com.moedae.app.levelDataQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _levelDataGenerationQueue;
}

-(NSOperationQueue*) privateImageGenerationQueue
{
    if (!_privateImageGenerationQueue)
    {
        _privateImageGenerationQueue = [[NSOperationQueue alloc] init];
        _privateImageGenerationQueue.name = @"FractalImageGenerationQueue";
    }
    return _privateImageGenerationQueue;
}

-(NSOperationQueue*) exportImageGenerationQueue
{
    if (!_exportImageGenerationQueue)
    {
        _exportImageGenerationQueue = [[NSOperationQueue alloc] init];
        _exportImageGenerationQueue.name = @"FractalExportImageGenerationQueue";
    }
    return _exportImageGenerationQueue;
}

#pragma mark Fractal Property KVO
-(FBKVOController *)kvoController
{
    if (!_kvoController)
    {
        _kvoController = [FBKVOController controllerWithObserver: self];
    }
    return _kvoController;
}

-(void)setFractalInfo:(MDBFractalInfo *)fractalInfo {
    
    if (_fractalInfo != fractalInfo) {
        
        if (_fractalInfo) {
            [self removeObserversForObservedDocument];
            [_privateImageGenerationQueueTimeoutTimer invalidate];
            [_privateImageGenerationQueue cancelAllOperations];
            _privateImageGenerationQueue = nil;
        }
        
        _fractalInfo = fractalInfo;
        
        id<MDBTileObjectProtocol> tileObject = [_fractalInfo.document.fractal.startingRules firstObject];
        
        if (_fractalInfo.document.fractal && tileObject.isDefaultObject)
        {
            //default rules and settings
            LSFractal* newFractal = _fractalInfo.document.fractal;
            
            LSDrawingRuleType* rules = self.appModel.sourceDrawingRules;
            
            [newFractal.startingRules addObjectsFromArray: [rules rulesArrayFromRuleString: @"F+F--F+F"]];
            newFractal.turningAngle = radians(45.0);
            
            LSReplacementRule* newReplacementRule = newFractal.replacementRules[0];
            newReplacementRule.contextRule = [rules ruleForIdentifierString: @"F"];
            [newReplacementRule.rules addObjectsFromArray: [rules rulesArrayFromRuleString: @"F+F--F+F"]];
            
            MBColor* defaultLine = [MBColor newMBColorWithUIColor: [UIColor blueColor]];
            defaultLine.identifier = @"blue";
            defaultLine.name = @"Blue";
            [newFractal.lineColors addObject: defaultLine];
            
            MBColor* defaultFill = [MBColor newMBColorWithUIColor: [UIColor greenColor]];
            defaultFill.identifier = @"green";
            defaultFill.name = @"Green";
            [newFractal.fillColors addObject: defaultFill];
            
            [_fractalInfo.document updateChangeCount: UIDocumentChangeDone];
        }
        
        self.autoscaleN = YES;
        self.hudLevelStepper.maximumValue = kHudLevelStepperDefaultMax;
    
        [self addObserverForFractalChangeInDocument: _fractalInfo.document];
    }
}

-(void) setFractalInfo: (MDBFractalInfo*)fractalInfo andShowCopiedAlert: (BOOL)copied
{
    MBLSFractalEditViewController* __weak weakSelf =  self;
    
    UIDocumentState docState = fractalInfo.document.documentState;
    
    if (docState != UIDocumentStateNormal)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            //
            [fractalInfo.document openWithCompletionHandler:^(BOOL success) {
                //detect if we have a new default fractal
                MBLSFractalEditViewController* editor = weakSelf;
                
                editor.fractalInfo = fractalInfo;
                if (copied)
                {
                    [editor updateEditorContent];
                    
                    editor.libraryViewController.fractalInfoBeingEdited = fractalInfo;
                    
                    [editor showCopiedAlert: fractalInfo.document.fractal.name];
                    editor.hasBeenEdited = YES;
                    //                    [self performSegueWithIdentifier: @"EditSegue" sender: self];
                }
            }];
        });
    }
    else
    {
        self.fractalInfo = fractalInfo;
        if (copied) // not sure this is ever called
        {
            [self updateEditorContent];
            //            [self performSegueWithIdentifier: @"EditSegue" sender: self];
        }
    }
}

-(void)showCopiedAlert: (NSString*)message
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Your fractal has been copied and you may begin editing.",nil)
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Ok", @"Ok, go ahead with action")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        //                                        [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                        //                                        [self updateLibraryRepresentationIfNeededNow: YES];
                                    }];
    [alert addAction: defaultAction];
    
    
    [self.navigationController presentViewController: weakAlert animated:YES completion:nil];
}

-(id<MDBFractaDocumentProtocol>)fractalDocument
{
    return _fractalInfo.document;
}

#pragma message "TODO Use an alert here rather than just deleting. Should only happen if deleted on another device."
-(void)fractalDocumentWasDeleted: (MDBFractalDocument*)deletedDocument
{
    if (self.fractalInfo.document == deletedDocument)
    {
        [self performSegueWithIdentifier: @"UnwindSegueToLibrary" sender: self];
    }
}

-(LSFractalRenderer*) fractalRendererL0
{
    if (!_fractalRendererL0)
    {
        if (self.fractalDocument.fractal)
        {
            _fractalRendererL0 = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.appModel.sourceDrawingRules];
            _fractalRendererL0.name = @"_fractalRendererL0";
            _fractalRendererL0.mainThreadImageView = self.fractalViewLevel0;
            _fractalRendererL0.flipY = NO;
            _fractalRendererL0.margin = 60.0;
            _fractalRendererL0.showOrigin = NO;
            _fractalRendererL0.autoscale = YES;
        }
    }
    return _fractalRendererL0;
}
-(LSFractalRenderer*) fractalRendererL1
{
    if (!_fractalRendererL1)
    {
        if (self.fractalDocument.fractal)
        {
            _fractalRendererL1 = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.appModel.sourceDrawingRules];
            _fractalRendererL1.name = @"_fractalRendererL1";
            _fractalRendererL1.mainThreadImageView = self.fractalViewLevel1;
            _fractalRendererL1.flipY = NO;
            _fractalRendererL1.margin = 40.0;
            _fractalRendererL1.showOrigin = NO;
            _fractalRendererL1.autoscale = YES;
        }
    }
    return _fractalRendererL1;
}
-(LSFractalRenderer*) fractalRendererL2
{
    if (!_fractalRendererL2)
    {
        if (self.fractalDocument.fractal)
        {
            _fractalRendererL2 = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.appModel.sourceDrawingRules];
            _fractalRendererL2.name = @"_fractalRendererL2";
            _fractalRendererL2.mainThreadImageView = self.fractalViewLevel2;
            _fractalRendererL2.flipY = NO;
            _fractalRendererL2.margin = 40.0;
            _fractalRendererL2.showOrigin = NO;
            _fractalRendererL2.autoscale = YES;
        }
    }
    return _fractalRendererL2;
}
-(LSFractalRenderer*) fractalRendererLN
{
    if (!_fractalRendererLN)
    {
        if (self.fractalDocument.fractal)
        {
            MDBAppModel* strongAppModel = self.appModel;
            UIImageView* strongView = self.fractalView;
            
            _fractalRendererLN = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: strongAppModel.sourceDrawingRules];
            _fractalRendererLN.name = @"_fractalRendererLNS1";
            _fractalRendererLN.mainThreadImageView = strongView;
            _fractalRendererLN.flipY = NO;
            _fractalRendererLN.margin = kLevelNMargin;
            _fractalRendererLN.showOrigin = !strongAppModel.hideOrigin;
            _fractalRendererLN.autoscale = YES;
        }
    }
    return _fractalRendererLN;
}

#pragma message "TODO: handle UIDocumentStateInConflict option to rename or overwrite"
/*!
 Device A and device B have a fractal open for editing.
 When B has no edits, and A is changed,
 B gets two stateChanged notifications,
 1. State changes to UIDocumentStateEditingDisabled just before reading in the new fractal.
 2. State changes to UIDocumentStateNormal when the new fractal has been read and replaced the fractal of the document.
 
 When state changes to UIDocumentStateEditingDisabled remove fractal observers.
 When state changes to normal, re-add the fractal observers.
 
 When B has edits and A has edits,
 B gets two stateChanged notifications
 1. States EditingDisabled AND InConflict bx01010
 Need to ask user which version they want to keep or if they want to create a new version.
 
 Do we need to keep track of previous state?
 
 @param notification
 */
- (void)handleDocumentStateChangedNotification:(NSNotification *)notification
{
#pragma message "Note there seems to be no rhyme or reason to when this gets called vs the fractal path observer so observer removal and adding is purposefully redundant."
#pragma message "TODO: add cloud progress indicator"
    
    MDBFractalDocument* document = notification.object;
    
    if (document != self.fractalInfo.document)
    {
        NSLog(@"Notification for wrong document");
    }
    
    UIDocumentState state = document.documentState;
    
    if (state == UIDocumentStateNormal)
    {
        //        [self removeObserversForFractal: self.fractalDocument.fractal];
        [self addObserversForFractal: document.fractal];
    }
    else if (state == UIDocumentStateClosed)
    {
        [self removeObserversForObservedFractal];
    }
    else if (state & UIDocumentStateInConflict)
    {
        if (self.presentedViewController && [self.presentedViewController isKindOfClass: [UIAlertController class]])
        {
            [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
        }
        else if (self.presentedViewController)
        {
            [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
        }
        
        [self resolveConflicts];
    }
    else if (state & UIDocumentStateEditingDisabled)
    {
        [self removeObserversForObservedFractal];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //        [self.tableView reloadData];
        [self updateInterface];
        [self regenerateLevels];
    });
}

- (void)resolveConflicts
{
    NSString* versionConflictMessage = [NSString stringWithFormat: @"Another one of your devices is trying to save a newly edited version over the version you are editing on this device. What do you want to do?"];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Editing Conflict!",nil)
                                                                   message: versionConflictMessage
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    MBLSFractalEditViewController* __weak weakSelf = self;
    
    UIAlertAction* pushOverwriteAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Keep this device edits",nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action)
                                          {
                                              MBLSFractalEditViewController* strongSelf = weakSelf;
                                              [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                              // Any automatic merging logic or presentation of conflict resolution UI should go here.
                                              // For this sample, just pick the current version and mark the conflict versions as resolved.
                                              [NSFileVersion removeOtherVersionsOfItemAtURL: strongSelf.fractalDocument.fileURL error:nil];
                                              
                                              NSArray *conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL: strongSelf.fractalDocument.fileURL];
                                              for (NSFileVersion *fileVersion in conflictVersions)
                                              {
                                                  fileVersion.resolved = YES;
                                              }
                                          }];
    [alert addAction: pushOverwriteAction];
    
    UIAlertAction* makeCopyAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Make a new copy of this fractal",nil)
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action)
                                     {
                                         [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                         [weakSelf copyFractal: nil];
                                     }];
    [alert addAction: makeCopyAction];
    
    [self presentViewController: alert animated: YES completion: nil];
}

-(void) addObserverForFractalChangeInDocument: (id<MDBFractaDocumentProtocol>)document
{
    id<MDBFractaDocumentProtocol> observedDocument = self.observedDocument;
    
    if (observedDocument && observedDocument == document)
    {
        return;
    }
    else
    {
        [self removeObserversForObservedDocument];
        
        if (document)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentStateChangedNotification:) name:UIDocumentStateChangedNotification object: document];
            //        [_fractalInfo.document addObserver: self forKeyPath: @"fractal" options: NSKeyValueObservingOptionOld context: NULL];
            document.delegate = self;
            
            [self.kvoController observe: document keyPath: @"fractal"
                                options: NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionPrior
                                 action: @selector(propertyDocumentFractalDidChange:object:)];
            
            [self addObserversForFractal: document.fractal];
            
            self.observedDocument = document;
        }
    }
}

-(void) removeObserversForObservedDocument
{
    id<MDBFractaDocumentProtocol> observedDocument = self.observedDocument;
    
    if (observedDocument) {
        
        [[NSNotificationCenter defaultCenter] removeObserver: self name: UIDocumentStateChangedNotification object: _fractalInfo.document];
        
        [self.kvoController unobserve: observedDocument];
        
        [self removeObserversForObservedFractal];
        
        [self updateLibraryRepresentationIfNeededNow: YES];
        
        [_privateImageGenerationQueue cancelAllOperations];
        
        observedDocument.delegate = nil;
        
        self.observedDocument = nil;
    }
}

-(void) updateLibraryRepresentationIfNeeded
{
    [self updateLibraryRepresentationIfNeededNow: NO];
}

-(void) updateLibraryRepresentationIfNeededNow: (BOOL)now
{
    if (self.hasBeenEdited)
    {
        if (now)
        {
            UIImage* fractalImage = [self snapshot: self.fractalView size: CGSizeMake(130.0, 130.0) withWatermark: NO];
            [_fractalInfo.document setThumbnail: fractalImage];
            _fractalInfo.changeDate = [NSDate date];
            
            [_fractalInfo.document updateChangeCount: UIDocumentChangeDone];
//            self.hasBeenEdited = NO;
        }
        else
        {
            MBLSFractalEditViewController* __weak weakSelf = self;
            
            [self.exportImageGenerationQueue addOperationWithBlock:^{
                UIImage* fractalImage = [self snapshot: self.fractalView size: CGSizeMake(130.0, 130.0) withWatermark: NO];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //
                    MBLSFractalEditViewController* strongSelf = weakSelf;
                    
                    [strongSelf->_fractalInfo.document setThumbnail: fractalImage];
                    strongSelf->_fractalInfo.changeDate = [NSDate date];
                    
                    [strongSelf->_fractalInfo.document updateChangeCount: UIDocumentChangeDone];
                    
//                    self.hasBeenEdited = NO;
                });
                
            }];
            
        }
    }
}

-(BOOL)checkChangeCountFor: (NSDictionary*)change
{
    return ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeSetting
            || [change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeInsertion
            || [change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeRemoval
            || [change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeReplacement);
}

-(void) propertyDocumentFractalDidChange: (NSDictionary*)change object: (id)object
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"ChangeKeyPath" : @"fractal"}];
    
    if (self.fractalInfo.document.documentState == UIDocumentStateNormal) // never called so remove?
    {
        if ([change[NSKeyValueChangeNotificationIsPriorKey] boolValue])
        {
            [self removeObserversForObservedFractal];
        }
        else
        { // goes through here twice for some reason
            LSFractal* newFractal = (LSFractal*)change[NSKeyValueChangeNewKey];
            if (newFractal) [self addObserversForFractal: newFractal];
        }
    }
}

-(void) propertyFractalLabelDidChange: (NSDictionary*)change object: (id)object
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"ChangeKeyPath" : @"label"}];
    self.hasBeenEdited = YES;
}

-(void) propertyFractalRedrawDidChange: (NSDictionary*)change object: (id)object
{
    if ([self checkChangeCountFor: change])
    {
        [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"ChangeKeyPath" : @"redraw"}];
        self.hasBeenEdited = YES;
        [self queueFractalImageUpdates];
        [self updateInterface];
    }
}

-(void) propertyFractalAppearanceDidChange: (NSDictionary*)change object: (id)object
{
    if ([self checkChangeCountFor: change])
    {
        [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"ChangeKeyPath" : @"appearance"}];
        self.hasBeenEdited = YES;
        [self queueFractalImageUpdates];
        [self updateInterface];
    }
}

-(void) propertyFractalFiltersDidChange: (NSDictionary*)change object: (id)object
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"ChangeKeyPath" : @"filter"}];
    self.hasBeenEdited = YES;
    [self updateFilterSettingsForCanvas];
    [self.fractalDocument.fractal updateApplyFiltersWithoutNotificationForFiltersListChange];
    [self queueFractalImageUpdates];
    [self updateInterface];
}

-(void) propertyFractalProductionRulesDidChange: (NSDictionary*)change object: (id)object
{
    if ([self checkChangeCountFor: change])
    {
        [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"ChangeKeyPath" : @"rule"}];
#pragma message "TODO: fix for uidocument"
        self.fractalDocument.fractal.rulesUnchanged = NO;
        self.hasBeenEdited = YES;
        
        [self regenerateLevels];
        [self updateInterface];
    }
}

-(void) propertyFractalReplacementRulesDidChange: (NSDictionary*)change object: (id)object
{
    if ([self checkChangeCountFor: change])
    {
        [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"ChangeKeyPath" : @"replacementRule"}];
        [self updateObserversForReplacementRules: self.fractalDocument.fractal.replacementRules];
        [self regenerateLevels];
        [self updateInterface];
    }
}

-(void) addObserversForFractal: (LSFractal*)fractal
{
    LSFractal* observedFractal = self.observedFractal;
    
    if (observedFractal && observedFractal == fractal)
    {
        return; // no need for observers
    }
    else
    {
        [self removeObserversForObservedFractal];
        
        if (fractal)
        {            
            [self setupSlidersForCurrentFractal];
            
            _lastImageUpdateTime = [NSDate date];
            
            NSKeyValueObservingOptions options = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
            
            [self.kvoController observe: fractal keyPaths: [[LSFractal productionRuleProperties]allObjects] options: options action: @selector(propertyFractalProductionRulesDidChange:object:)];
            [self.kvoController observe: fractal keyPaths: [[LSFractal appearanceProperties]allObjects] options: options action: @selector(propertyFractalAppearanceDidChange:object:)];
            [self.kvoController observe: fractal keyPaths: [[LSFractal redrawProperties]allObjects] options: options action: @selector(propertyFractalRedrawDidChange:object:)];
            [self.kvoController observe: fractal keyPaths: [[LSFractal labelProperties]allObjects] options: options action: @selector(propertyFractalProductionRulesDidChange:object:)];
            
            self.hasBeenEdited = NO;
            
            [self updateFilterSettingsForCanvas];
            [self queueFractalImageUpdates];
            [self updateInterface];
        }
        
        [self storeOriginalFractal: fractal thumbnail: self.fractalDocument.thumbnail];
        self.observedFractal = fractal;
    }
}

-(void)storeOriginalFractal: (LSFractal*) fractal thumbnail: (UIImage*)thumbnail
{
    self.originalFractal = [fractal copy];
    self.originalFractal.name = fractal.name; // revert name since 'copy' adds a number, should have separate copy/method for incrementing name.
    self.originalThumbnail = thumbnail;
}

-(void)restoreOriginalFractal
{
    self.fractalDocument.thumbnail = self.originalThumbnail;
    self.fractalDocument.fractal = self.originalFractal;
    [self.fractalDocument updateChangeCount: UIDocumentChangeDone];
    [self updateLibraryRepresentationIfNeededNow: YES];
    self.hasBeenEdited = NO;
}

-(void)removeObserversForObservedFractal
{
    LSFractal* observedFractal = self.observedFractal;
    [self.kvoController unobserve: observedFractal];
    self.observedFractal = nil;
}

/*!
 Most fractal properties are only changed while the appearance editor is present.
 Only add observers when presenting and remove when dismissing.
 
 Hopefully will also fix problem with fractal changing by load document and observers not being removed before hand.
 */
-(void)addObserversForAppearanceEditorChanges
{
    LSFractal* fractal = _fractalInfo.document.fractal;
    if (fractal)
    {
        [self setupSlidersForCurrentFractal];
        
        _lastImageUpdateTime = [NSDate date];
        
        NSKeyValueObservingOptions options = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
        
        [self.kvoController observe: fractal keyPaths: @[@"startingRules.allObjects"] options: options action: @selector(propertyFractalProductionRulesDidChange:object:)];
        [self.kvoController observe: fractal keyPaths: @[@"lineColors.allObjects",@"fillColors.allObjects"] options: options action: @selector(propertyFractalAppearanceDidChange:object:)];
        [self.kvoController observe: fractal keyPaths: @[@"imageFilters.allObjects"] options: options action: @selector(propertyFractalFiltersDidChange:object:)];
        
        
        [self updateObserversForReplacementRules: fractal.replacementRules];
    }
}

-(void)removeObserversForAppearanceEditorChanges
{
    LSFractal* fractal = _fractalInfo.document.fractal;
    if (fractal)
    {
        [self.kvoController unobserve: fractal keyPath: @"startingRules.allObjects"];
        [self.kvoController unobserve: fractal keyPath: @"lineColors.allObjects"];
        [self.kvoController unobserve: fractal keyPath: @"fillColors.allObjects"];
        [self.kvoController unobserve: fractal keyPath: @"imageFilters.allObjects"];
        
        for (LSReplacementRule* rRule in fractal.replacementRules)
        {
            [self.kvoController unobserve: rRule];
            [self.observedReplacementRules removeObject: rRule];
        }
    }
}

-(void) updateObserversForReplacementRules: (NSMutableArray*) newReplacementRules {
    // need to find rules missing from registered observers.
    
    NSMutableSet* copyOfCurrent = [NSMutableSet setWithArray: newReplacementRules];
    NSMutableSet* copyOfPrevious = [self.observedReplacementRules mutableCopy];
    
    NSMutableSet* repRulesToUnobserve = [copyOfPrevious mutableCopy];
    [repRulesToUnobserve minusSet: copyOfCurrent];
    
    
    for (LSReplacementRule* rRule in repRulesToUnobserve)
    {
        [self.kvoController unobserve: rRule];
        [self.observedReplacementRules removeObject: rRule];
    }
    
    NSMutableSet* repRulesToAddObserver = [copyOfCurrent mutableCopy];
    [repRulesToAddObserver minusSet: self.observedReplacementRules];
    
    for (LSReplacementRule* rRule in repRulesToAddObserver)
    {
        [self.kvoController observe: rRule keyPaths: @[[LSReplacementRule contextRuleKey], @"rules.allObjects"] options: 0 action: @selector(propertyFractalProductionRulesDidChange:object:)];
        [self.observedReplacementRules addObject: rRule];
    }
}

-(void)updatePropertiesForLowPerformanceDevice
{
    self.minImagePersistence = 1.0 / kLowPerformanceFrameRate;
    self.imageGenerationTimout = 10.0;
    self.nodeLimit = kLSMaxNodesLoPerf;
}

-(void) setShowPerformanceData:(BOOL)showPerformanceData
{
    _showPerformanceData = showPerformanceData;
    
    UILabel* strongLabel = _renderTimeLabel;
    
    if (_showPerformanceData)
    {
        strongLabel.hidden = NO;
    } else
    {
        strongLabel.hidden = YES;
    }
}


#pragma mark - view utility methods

-(void) updateInterface
{
//    [self stopButtonPressed: nil];
    [self updateValueInputs];
    [self updateLabelsAndControls];
}

-(void) updateValueInputs
{
    self.hudLevelStepper.value = self.fractalDocument.fractal.level;
    //
    self.hudText2.text =[self.twoPlaceFormatter stringFromNumber: @(degrees(self.fractalDocument.fractal.turningAngle))];
}

/*!
 Want to queue
 If HUDs are showing
 Level 0 image for level0 HUD
 Level 1 image for level1 HUD
 Level 2 image for level2 HUD
 
 LevelN images in serial order with callbacks
 level0 image
 level1 image
 level2 image
 levelN image
 
 Cancel image still in operation queue when gestures are in progress and turn off autoscaling and show origin
 */
-(void) updateLabelsAndControls
{
    self.hudText1.text = [NSString stringWithFormat: @"%li", (long)self.fractalDocument.fractal.level];
    self.hudText2.text = [self.twoPlaceFormatter stringFromNumber: @(degrees(self.fractalDocument.fractal.turningAngle))];
    
    self.baseAngleLabel.text = [self.angleFormatter stringFromNumber: [NSNumber numberWithDouble: degrees(self.fractalDocument.fractal.baseAngle)]];
    self.baseAngleSlider.value = degrees(self.fractalDocument.fractal.baseAngle);
    
    self.hudRandomnessLabel.text = [self.percentFormatter stringFromNumber: @(self.fractalDocument.fractal.randomness)];
    self.randomnessVerticalSlider.value = self.fractalDocument.fractal.randomness;
    
    self.hudLineAspectLabel.text = [NSString stringWithFormat: @"%@px by 10px long",[self.onePlaceFormatter stringFromNumber: @(self.fractalDocument.fractal.lineWidth)]];
    self.lineWidthVerticalSlider.value = self.fractalDocument.fractal.lineWidth;
    
    self.turningAngleLabel.text = [self.angleFormatter stringFromNumber: @(degrees(self.fractalDocument.fractal.turningAngle))];
    self.turnAngleSlider.value =  degrees(self.fractalDocument.fractal.turningAngle);
    
    //    double turnAngleChangeInDegrees = degrees([self.fractalDocument.fractal.turningAngleIncrement doubleValue] * [self.fractalDocument.fractal.turningAngle doubleValue]);
    self.turnAngleIncrementLabel.text = [self.percentFormatter stringFromNumber: @(self.fractalDocument.fractal.turningAngleIncrement)];
    self.turningAngleIncrementSlider.value = self.fractalDocument.fractal.turningAngleIncrement;
    
    self.hudLineIncrementLabel.text = [self.percentFormatter stringFromNumber: @(self.fractalDocument.fractal.lineChangeFactor)];
    self.lengthIncrementVerticalSlider.value = self.fractalDocument.fractal.lineChangeFactor;
    
    self.autoExpandOff.selected = self.fractalDocument.fractal.autoExpand;
    
    self.applyFiltersButton.selected = self.fractalDocument.fractal.applyFilters;
}
-(void) regenerateLevels
{
#pragma message "TODO: fix for uidocument create a separate operation queue for this stuff"
    LSFractal* strongFractal = self.fractalDocument.fractal;
    if (!strongFractal)
    {
        return;
    }
    
    dispatch_async(self.levelDataGenerationQueue, ^{
        //
        [strongFractal generateLevelData];
        NSArray* levelDataArray = @[strongFractal.level0RulesCache, strongFractal.level1RulesCache, strongFractal.level2RulesCache, strongFractal.levelNRulesCache, @(strongFractal.levelGrowthRate)];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateRendererLevels: levelDataArray];
        });
    });
}
-(NSInteger) levelNIndex
{
    NSInteger levelNIndex = self.fractalDocument.fractal.level > 3 ? 3 : self.fractalDocument.fractal.level;
    return levelNIndex;
}
-(void) updateRendererLevels: (NSArray*)levelDataArray
{
    self.levelDataArray = levelDataArray;
    
    
    if (self.levelDataArray.count == 5)
    {
        if (!self.fractalViewLevel0.superview.hidden)
        {
            self.fractalRendererL0.levelData = self.levelDataArray[0];
        }
        if (!self.fractalViewLevel1.superview.hidden)
        {
            self.fractalRendererL1.levelData = self.levelDataArray[1];
        }
        if (!self.fractalViewLevel2.superview.hidden)
        {
            self.fractalRendererL2.levelData = self.levelDataArray[2];
        }
        
        self.fractalRendererLN.levelData = self.levelDataArray[[self levelNIndex]];
        [self queueFractalImageUpdates];
        
        CGFloat currentNodeCount = (CGFloat)[(NSData*)self.levelDataArray[3] length];
        CGFloat estimatedNextNode = currentNodeCount * [self.levelDataArray[4] floatValue];
        //        NSLog(@"growth rate %f",[self.fractalDocument.fractal.levelGrowthRate floatValue]);
        UIStepper* strongLevelStepper = self.hudLevelStepper;
        if (estimatedNextNode > self.nodeLimit)
        {
            strongLevelStepper.maximumValue = strongLevelStepper.value;
        } else if (strongLevelStepper.maximumValue == strongLevelStepper.value)
        {
            strongLevelStepper.maximumValue = strongLevelStepper.value + 1;
        }
    }
}

-(void) imageGenerationStartAnimator: (NSTimer*)timer
{
    [self.activityIndicator startAnimating];
    
    self.privateImageGenerationQueueTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval: self.imageGenerationTimout
                                                                                    target: self
                                                                                  selector: @selector(imageGenerationTimeout:)
                                                                                  userInfo: nil
                                                                                   repeats: NO];
}

-(void) imageGenerationTimeout: (NSTimer*)timer
{
    NSLog(@"FractalScapes cancelling privateImageGenerationQueue due to timeout: %f",timer.timeInterval);
    [self.privateImageGenerationQueue cancelAllOperations];
}

-(void) queueFractalImageUpdates
{
    if (!self.fractalDocument.fractal.isRenderable || !self.fractalView) {
        return;
    }
    
    NSBlockOperation* strongOperation = self.fractalRendererLN.operation;
    
    if (strongOperation && !strongOperation.isFinished)
    {
        NSDate* now = [NSDate date];
        NSTimeInterval lastUpdated = [now timeIntervalSinceDate: self.lastImageUpdateTime];
        if (lastUpdated < self.minImagePersistence) {
            return;
        }
        
        [strongOperation cancel];
    }
    
    [self.privateImageGenerationQueue waitUntilAllOperationsAreFinished];
    
    [self queueHudImageUpdates];
    
    self.fractalRendererLN.autoscale = self.autoscaleN;
    self.fractalRendererLN.autoExpand = self.fractalDocument.fractal.autoExpand;
    self.fractalRendererLN.applyFilters = self.fractalDocument.fractal.applyFilters;
    if (self.fractalDocument.fractal.applyFilters) self.fractalRendererLN.showOrigin = NO; // overrides user pref
    
#pragma message "TODO define a property for the default fractal background color. Currently manually spread throughout code."
    MBColor* backgroundColor = self.fractalDocument.fractal.backgroundColor;
    if (!backgroundColor) backgroundColor = [MBColor newMBColorWithUIColor: [UIColor clearColor]];
    self.fractalRendererLN.backgroundColor = backgroundColor;
    
    //    if (!self.lowPerformanceDevice || self.fractalRendererLN.levelData.length < 150000)
    //    {
    //        self.fractalRendererLN.pixelScale = self.fractalViewHolder.contentScaleFactor;// * 2.0;
    //    }
    //    else
    //    {
    //        self.fractalRendererLN.pixelScale = self.fractalViewHolder.contentScaleFactor;
    //    }
    
    //    NSBlockOperation* startTimerOperation = [NSBlockOperation blockOperationWithBlock:^{
    //        //
    //              dispatch_async(dispatch_get_main_queue(), ^{
    //                //
    //                  self.privateImageGenerationQueueTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5
    //                                                                                                  target: self
    //                                                                                                selector: @selector(imageGenerationStartAnimator:)
    //                                                                                                userInfo: nil
    //                                                                                                 repeats: NO];
    //            });
    //    }];
    
    NSBlockOperation* operationNN1 = [self operationForRenderer: self.fractalRendererLN];
    
    //    NSBlockOperation* endTimerOperation = [NSBlockOperation blockOperationWithBlock:^{
    //        // image generation finished before the timeout.
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            if (self.privateImageGenerationQueueTimeoutTimer.isValid) [self.privateImageGenerationQueueTimeoutTimer invalidate];
    //        });
    //    }];
    //
    //    [endTimerOperation addDependency: operationNN1];
    //    [operationNN1 addDependency: startTimerOperation];
    //
    //    [self.privateImageGenerationQueue addOperations: @[startTimerOperation,operationNN1,endTimerOperation] waitUntilFinished: NO];
    [self.privateImageGenerationQueue addOperation: operationNN1];
    self.lastImageUpdateTime = [NSDate date];
}
-(void) queueHudImageUpdates
{
    if (!self.fractalViewLevel0.superview.hidden)
    {
        NSBlockOperation* operation0 = [self operationForRenderer: self.fractalRendererL0];
        self.fractalRendererL0.backgroundColor = [MBColor newMBColorWithUIColor: [UIColor clearColor]];
        self.fractalRendererL0.applyFilters = NO;
        [self.privateImageGenerationQueue addOperation: operation0];
    }
    
    if (!self.fractalViewLevel1.superview.hidden)
    {
        NSBlockOperation* operation1 = [self operationForRenderer: self.fractalRendererL1];
        self.fractalRendererL1.backgroundColor = [MBColor newMBColorWithUIColor: [UIColor clearColor]];
        self.fractalRendererL1.applyFilters = NO;
        [self.privateImageGenerationQueue addOperation: operation1];
    }
    
    if (!self.fractalViewLevel2.superview.hidden)
    {
        NSBlockOperation* operation2 = [self operationForRenderer: self.fractalRendererL2];
        self.fractalRendererL2.backgroundColor = [MBColor newMBColorWithUIColor: [UIColor clearColor]];
        self.fractalRendererL2.applyFilters = NO;
        [self.privateImageGenerationQueue addOperation: operation2];
    }
}
-(NSBlockOperation*) operationForRenderer: (LSFractalRenderer*)renderer
{
    //    [self.activityIndicator startAnimating];
    
    [renderer setValuesForFractal: self.fractalDocument.fractal];
    
    NSBlockOperation* operation = [NSBlockOperation new];
    renderer.operation = operation;
    
    [operation addExecutionBlock: ^{
        //code
        if (!renderer.operation.isCancelled)
        {
            [renderer generateImage];
            
            UIImageView* mainThreadImageView = renderer.mainThreadImageView;
            
            if (mainThreadImageView && renderer.imageRef != NULL)
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    BOOL applyFilters = YES;
                    if (renderer.applyFilters)
                    {
                        
                        //                        [self updateFiltersOnView: renderer.imageView];
                        CGFloat imageWidth = CGImageGetWidth(renderer.imageRef);
                        CGFloat imageHeight = CGImageGetHeight(renderer.imageRef);
                        CIImage *ciiInputImage = [CIImage imageWithBitmapData: renderer.contextNSData bytesPerRow: imageWidth*4 size: CGSizeMake(imageWidth, imageHeight) format: kCIFormatRGBA8 colorSpace: [MBImageFilter colorSpace]];
                        NSAssert(ciiInputImage, @"FractalScapes Error: Core Image CIImage for filters should not be nil");
                        CGImageRef filteredImage = [self newCGImageRefToBitmapFromFiltersAppliedToCIImage: ciiInputImage];
                        mainThreadImageView.layer.contents = CFBridgingRelease(filteredImage);
                    }
                    else
                    {
#pragma message "TODO: Filters view seems to use OpenGL. If a simple filter is implemented here, will this use opengl as well?"
                        mainThreadImageView.layer.contents = (__bridge id)(renderer.imageRef);
                    }
                    
                    if (renderer == self.fractalRendererLN && self.activityIndicator.isAnimating)
                    {
                        [self.activityIndicator stopAnimating];
                    }
                    if (!self.renderTimeLabel.hidden && renderer == self.fractalRendererLN)
                    {
                        UIDevice* device = [UIDevice currentDevice];
                        NSString* deviceIdentifier = device.model;
                        self.renderTimeLabel.text = [NSString localizedStringWithFormat: @"Device: %@, Render Time: %0.0fms, Nodes: %lu",
                                                     deviceIdentifier,self.fractalRendererLN.renderTime,(unsigned long)self.fractalRendererLN.levelData.length];
                    }
                }];
            }
        }
    }];
    return operation;
}

/*
 not sure this is needed?
 copied but no longer relevant?
 */
- (void)updateUndoRedoBarButtonState
{
    if (self.editing)
    {
        NSInteger level = [self.undoManager groupingLevel] > 0;
        
        if (level && [self.undoManager canRedo])
        {
            self.redoButtonItem.enabled = YES;
        } else
        {
            self.redoButtonItem.enabled = NO;
        }
        
        [self logGroupingLevelFrom: NSStringFromSelector(_cmd)];
        if (level && [self.undoManager canUndo])
        {
            self.undoButtonItem.enabled = YES;
        } else
        {
            self.undoButtonItem.enabled = NO;
        }
    }
}

#pragma mark - action utility methods
-(double) convertAndQuantizeRotationFrom: (UIRotationGestureRecognizer*)sender quanta: (double) stepRadians ratio: (double) deltaAngleToDeltaGestureRatio
{
    
    double deltaAngle = 0.0;
    
    // conver the gesture rotation to a range between +180 & -180
    double deltaGestureRotation =  remainder(sender.rotation, 2*M_PI);
    
    double deltaAngleSteps = nearbyint(deltaAngleToDeltaGestureRatio*deltaGestureRotation/stepRadians);
    double newRotation = 0;
    
    if (deltaAngleSteps != 0.0)
    {
        deltaAngle = deltaAngleSteps*stepRadians;
        
        newRotation = deltaGestureRotation - deltaAngle/deltaAngleToDeltaGestureRatio;
        sender.rotation = newRotation;
    }
    
    return deltaAngle;
}
- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        UIView *fractalView = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView: fractalView];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:fractalView.superview];
        
        fractalView.layer.anchorPoint = CGPointMake(locationInView.x / fractalView.bounds.size.width, locationInView.y / fractalView.bounds.size.height);
        fractalView.center = locationInSuperview;
    }
}



-(IBAction) info:(id)sender
{
    
}

-(void) updateViewConstraints
{
    [super updateViewConstraints];
    [self configurePlayBackSliderConstraints];
}
/*!
 Note the playbackSlider is horizontal and will be rotated vertical.
 Constraints are applied in the horizontal configuration.
 Therefore we want the center of the slider to be just inside the right edge.
 The length of the slider to be margins less than the height of the container.
 The vertical space of the slider to locate the center of the slider in the center of container height.
 */
-(void) configurePlayBackSliderConstraints
{
    UIView* slider = self.playbackSlider;
    UIView* container = self.playbackSlider.superview;
    
    CGFloat topBarOffset = self.topLayoutGuide.length;
    CGFloat verticalMargins = 60.0;
    
    
    
    [container addConstraint: [NSLayoutConstraint constraintWithItem: slider
                                                           attribute: NSLayoutAttributeWidth
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: container
                                                           attribute: NSLayoutAttributeHeight
                                                          multiplier: 1.0
                                                            constant: -2.0*verticalMargins]];
    
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem: slider
                                                                  attribute: NSLayoutAttributeCenterY
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: container
                                                                  attribute: NSLayoutAttributeCenterY
                                                                 multiplier: 1.0
                                                                   constant: topBarOffset/2.0];
    
    // lower priority to prevent warnings during orientation changes
    constraint.priority = UILayoutPriorityDefaultHigh;
    [container addConstraint: constraint];
    
    [container addConstraint: [NSLayoutConstraint constraintWithItem: slider
                                                           attribute: NSLayoutAttributeCenterX
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: container
                                                           attribute: NSLayoutAttributeTrailing
                                                          multiplier: 1.0
                                                            constant: -20.0]];
}

#pragma mark - Segues

/* close any existing popover before opening a new one.
 do not open a new one if the new popover is the same as the current */
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    BOOL should = YES;
    
    UIViewController* currentPresentedController = self.currentPresentedController;
    
    if ([identifier isEqualToString:@"EditSegue"] && [currentPresentedController isKindOfClass:[MBFractalAppearanceEditorViewController class]])
    {
        should = NO;
        MBLSFractalEditViewController* __weak weakSelf = self;
        [currentPresentedController dismissViewControllerAnimated: YES completion:^{
            //
            [weakSelf appearanceControllerWasDismissed];
        }];
    }
    else if ([identifier isEqualToString:@"LibrarySegue"] && [currentPresentedController isKindOfClass:[MBFractalLibraryViewController class]])
    {
        should = NO;
        [currentPresentedController dismissViewControllerAnimated: YES completion: nil];
    }
    return should;
}
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (self.presentedViewController)
    {
        [self dismissViewControllerAnimated: YES completion: nil];
    }
    
    [self stopButtonPressed: nil];
    
    UIViewController<FractalControllerProtocol>* newController;
    
    if ([segue.identifier isEqualToString: @"EditSegue"])
    {
        newController = (UIViewController<FractalControllerProtocol>*)segue.destinationViewController;
        [self appearanceControllerIsPresenting: newController];
    }
    else if ([segue.identifier isEqualToString: @"QuickIntroSegue"])
    {
        
    }
    else if ([segue.identifier isEqualToString: @"ShowPurchaseControllerSegue"])
    {
        UINavigationController* navCon = (UINavigationController*)segue.destinationViewController;
        MDBPurchaseViewController* pvc = [navCon.viewControllers firstObject];
        pvc.purchaseManager = self.appModel.purchaseManager;
    }
    else if ([segue.identifier isEqualToString: @"UnwindSegueToLibrary"])
    {
        [self updateLibraryRepresentationIfNeededNow: YES];
        [self.exportImageGenerationQueue waitUntilAllOperationsAreFinished];
    }
}

-(void) updateViewController: (UIViewController*)viewController popoverPreferredContentSizeForViewSize: (CGSize)size
{
    if (viewController)
    {
        /*<UITraitCollection: 0x7fc6d2842be0; _UITraitNameUserInterfaceIdiom = Phone,
         _UITraitNameDisplayScale = 2.000000,
         _UITraitNameHorizontalSizeClass = Compact,
         _UITraitNameVerticalSizeClass = Compact, _UITraitNameTouchLevel = 0, */
        CGSize popSize;
        BOOL isPortrait = size.height > size.width ? YES : NO;
        
        if (isPortrait)
        {
            [self moveCanvasForPortraitPopover];
        }
        else
        {
            [self moveCanvasForLandscapePopover];
        }
        
        UITraitCollection* traits = self.traitCollection;
        
        if (traits.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            CGFloat height;
            CGFloat width;
            
            if (isPortrait)
            {
                height = fmaxf(270.0, size.height / 2.0);
                width = size.width - self.editButton.bounds.size.width;
            }
            else
            {
                height = size.height * 0.96;
                width = size.width/2.0 - self.editButton.bounds.size.width;
            }
            popSize = CGSizeMake(width, height);
        }
        else if (traits.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            popSize = isPortrait ? CGSizeMake(728.0,350.0) : CGSizeMake(360.0,650.0);
        }
        else
        {
            popSize = isPortrait ? CGSizeMake(728.0,350.0) : CGSizeMake(400.0,650.0);
        }
        
        viewController.preferredContentSize = popSize;
    }
}

/*!
 Move the center of the canvas to the top half
 */
-(void)moveCanvasForPortraitPopover
{
    CGSize size = self.fractalView.bounds.size;
    
    [self autoScale: nil];
    [self.fractalScrollView setContentOffset: CGPointMake(size.width*0.0, size.height*0.2) animated: YES];
    [self.fractalScrollView setZoomScale: 1.0 animated: YES];
}

/*!
 Move the center of the canvas to the left half
 */
-(void)moveCanvasForLandscapePopover
{
    CGSize size = self.fractalView.bounds.size;
    
    [self autoScale: nil];
    [self.fractalScrollView setContentOffset: CGPointMake(size.width*0.25, size.height*0.0) animated: YES];
    [self.fractalScrollView setZoomScale: 1.0 animated: YES];
}

#pragma mark - UIPopoverPresentationControllerDelegate
- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController
{
    int i = 10;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}


- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return YES;
}
/*!
 Called when the popover button is pressed a second time.
 
 Not called when the Done button is pressed.
 
 @param popoverPresentationController
 */
-(void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    if ([popoverPresentationController.presentedViewController isKindOfClass: [MBFractalAppearanceEditorViewController class]])
    {
        [self appearanceControllerWasDismissed];
    }
}
-(void) appearanceControllerIsPresenting: (UIViewController<FractalControllerProtocol>*) controller
{
    if (self.fractalDocument.fractal.isImmutable) self.fractalDocument.fractal = [self.fractalDocument.fractal mutableCopy];
    
    controller.fractalControllerDelegate = self;
    controller.appModel = self.appModel;
    controller.fractalDocument = self.fractalDocument;
    controller.fractalUndoManager = self.undoManager;
    CGSize viewSize = self.view.bounds.size;
    [self updateViewController: controller popoverPreferredContentSizeForViewSize: viewSize];
    controller.popoverPresentationController.delegate = self;
    controller.popoverPresentationController.passthroughViews = @[self.fractalViewRoot];
    
    self.currentPresentedController = controller;
    
    if (!self.navigationController.navigationBar.hidden) {
        self.previousNavBarState = self.navigationController.navigationBar.hidden;
        [self.navigationController setNavigationBarHidden: YES animated: NO]; // needs to be non-animated or popover greys navBar buttons before it is hidden and then when it is restored, they are still grey.
    }
    
    self.fractalViewRootSingleTapRecognizer.enabled = NO;
    
    [self addObserversForAppearanceEditorChanges];
}

-(void) appearanceControllerWasDismissed
{
    [self removeObserversForAppearanceEditorChanges];
    [self.navigationController setNavigationBarHidden: self.previousNavBarState animated: YES];
    self.fractalViewRootSingleTapRecognizer.enabled = YES;
    self.currentPresentedController = nil;
    [self updateLibraryRepresentationIfNeeded];
    [self autoScale: nil];
}

#pragma mark - Control Actions
/*!
 
 */
- (IBAction)shareButtonPressed:(id)sender
{
    MDBAppModel* strongAppModel = self.appModel;
    
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }
    
    //    [self.shareActionsSheet showFromBarButtonItem: sender animated: YES];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Share",nil)
                                                                   message: NSLocalizedString(@"How would you like to share the image?",nil)
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    MBLSFractalEditViewController* __weak weakSelf = self;
    
    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    
    if (cameraAuthStatus == ALAuthorizationStatusNotDetermined || cameraAuthStatus == ALAuthorizationStatusAuthorized)
    {
        UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Export as Image",nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
                                       {
                                           MBLSFractalEditViewController* strongSelf = weakSelf;
                                           
                                           if (strongSelf.fractalDocument.fractal.name != nil)
                                           {
                                               [Answers logShareWithMethod: @"Image"
                                                               contentName: strongSelf.fractalDocument.fractal.name
                                                               contentType: @"Fractal"
                                                                 contentId: strongSelf.fractalDocument.fractal.name
                                                          customAttributes: nil];
                                           }
                                           
                                           [weakAlert dismissViewControllerAnimated: YES completion: nil];
                                           [strongSelf shareWithActivityController: sender];
                                       }];
        [alert addAction: cameraAction];
    }
    else
    {
        UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Re-Enable Photos Access",nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
                                       {
                                           [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                           [weakSelf.appModel sendUserToSystemiCloudSettings: sender];
                                       }];
        [alert addAction: cameraAction];
    }
    
    
    UIAlertAction* documentShare = [UIAlertAction actionWithTitle: NSLocalizedString(@"Export as Document",nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        MBLSFractalEditViewController* strongSelf = weakSelf;
                                        
                                        if (strongSelf.fractalDocument.fractal.name != nil)
                                        {
                                            [Answers logShareWithMethod: @"Document"
                                                            contentName: strongSelf.fractalDocument.fractal.name
                                                            contentType: @"Fractal"
                                                              contentId: strongSelf.fractalDocument.fractal.name
                                                       customAttributes: nil];
                                        }
                                        
                                        [weakAlert dismissViewControllerAnimated: YES completion: nil];
                                        [strongSelf shareWithDocumentInteractionController: sender];
                                    }];
    [alert addAction: documentShare];
    
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle: NSLocalizedString(@"Share to FractalCloud",nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [weakAlert dismissViewControllerAnimated: YES completion:nil]; // because of popover mode
                                       [weakSelf shareFractalToCloud: sender];
                                   }
                                   ];
    [alert addAction: fractalCloud];
    
    
    if (strongAppModel.allowPremium)
    {
        UIAlertAction* vectorPDF = [UIAlertAction actionWithTitle: NSLocalizedString(@"Export as Vector PDF",nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        MBLSFractalEditViewController* strongSelf = weakSelf;
                                        
                                        if (strongSelf.fractalDocument.fractal.name != nil)
                                        {
                                            [Answers logShareWithMethod: @"VectorPDF"
                                                            contentName: strongSelf.fractalDocument.fractal.name
                                                            contentType: @"Fractal"
                                                              contentId: strongSelf.fractalDocument.fractal.name
                                                       customAttributes: nil];
                                        }
                                        
                                        [weakAlert dismissViewControllerAnimated: YES completion:nil];
                                        [strongSelf sharePDFWithDocumentInteractionController: sender];
                                    }];
        [alert addAction: vectorPDF];
    }
    else if (strongAppModel.userCanMakePayments)
    {
        UIAlertAction* vectorPDF = [UIAlertAction actionWithTitle: NSLocalizedString(@"Upgrade to Export as Vector PDF",nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                        [weakSelf upgradeToProSelected: sender];
                                    }];
        [alert addAction: vectorPDF];
    }
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel",nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        MBLSFractalEditViewController* strongSelf = weakSelf;
                                        if (strongSelf.fractalDocument.fractal.name != nil)
                                        {
                                            [Answers logShareWithMethod: @"Cancel"
                                                            contentName: strongSelf.fractalDocument.fractal.name
                                                            contentType: @"Fractal"
                                                              contentId: strongSelf.fractalDocument.fractal.name
                                                       customAttributes: nil];
                                        }
                                        
                                        [weakAlert dismissViewControllerAnimated: YES completion:nil];
                                    }];
    [alert addAction: defaultAction];
    
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction) shareFractalToCloud:(id)sender
{
    // check for iCloud account
    // check for discovery
    MDBAppModel* appModel = self.appModel;
    
    if (appModel.isCloudAvailable)
    {
        MBLSFractalEditViewController* __weak weakSelf = self;
        
        [appModel.cloudKitManager requestDiscoverabilityPermission:^(BOOL discoverable) {
            MBLSFractalEditViewController* strongSelf = weakSelf;
            NSSet* fractalInfos = [NSSet setWithObject: strongSelf.fractalInfo];
            [appModel pushToPublicCloudFractalInfos: fractalInfos onController: strongSelf];
        }];
    }
    else
    {
        [appModel showAlertActionsToAddiCloud: sender onController: self];
    }
}

-(IBAction) upgradeToProSelected:(id)sender
{
    [self performSegueWithIdentifier: @"ShowPurchaseControllerSegue" sender: nil];
}

//-(void)presentPurchaseOptions
//{
//    if (self.presentedViewController)
//    {
//        BOOL wasAppearance = [self.presentedViewController isKindOfClass: [MBFractalAppearanceEditorViewController class]];
//
//        [self dismissViewControllerAnimated: YES completion:^{
//            if (wasAppearance) [self appearanceControllerWasDismissed];
//            [self upgradeToProSelected: nil];
//        }];
//    }
//    else
//    {
//        [self upgradeToProSelected: nil];
//    }
//}
-(void)unwindFromAppearanceController:(id)sender
{
    [self appearanceControllerWasDismissed];
}
-(void)unwindToPresentPurchaseController:(UIStoryboardSegue *)segue
{
    UIViewController* sourceController = (UIViewController*)segue.sourceViewController;
    
    // This is necessary due to presentation being over full context, popover style
    [sourceController.presentingViewController dismissViewControllerAnimated: YES completion:^{
        [self appearanceControllerWasDismissed];
        [self upgradeToProSelected: nil];
    }];
}
-(void)unwindFromPurchaseController:(UIStoryboardSegue*)segue
{
    UIViewController* sourceController = (UIViewController*)segue.sourceViewController;
    
    // This is necessary due to presentation being over full context, popover style
    [sourceController.presentingViewController dismissViewControllerAnimated: YES completion:^{
        
    }];
}

- (IBAction)shareWithDocumentInteractionController:(id)sender
{
    NSURL* fileUrl = self.fractalDocument.fileURL;
    
    _documentShareController = [UIDocumentInteractionController interactionControllerWithURL: fileUrl];
    //    documentSharer.UTI = @"com.adobe.pdf";
    _documentShareController.delegate = self;
    
    NSArray* iconList = _documentShareController.icons;
    if (iconList.count > 0)
    {
        if ([sender isKindOfClass: [UIBarButtonItem class]])
        {
            BOOL success = [_documentShareController presentOptionsMenuFromBarButtonItem: sender animated: YES];
            if (success)
            {
                //
            }
            else
            {
                
            }
            //        BOOL result = [documentSharer presentOpenInMenuFromBarButtonItem: sender animated: YES];
        } else
        {
            [_documentShareController presentOpenInMenuFromRect: [sender bounds] inView: self.fractalViewRoot animated: YES];
        }
    }
}

- (IBAction)sharePDFWithDocumentInteractionController:(id)sender
{
    NSURL* fileUrl = [self savePDFData: [self createPDF]];
    
    _documentShareController = [UIDocumentInteractionController interactionControllerWithURL: fileUrl];
    //    documentSharer.UTI = @"com.adobe.pdf";
    _documentShareController.delegate = self;
    
    NSArray* iconList = _documentShareController.icons;
    if (iconList.count > 0)
    {
        if ([sender isKindOfClass: [UIBarButtonItem class]])
        {
            BOOL success = [_documentShareController presentOptionsMenuFromBarButtonItem: sender animated: YES];
            if (success)
            {
                //
            }
            else
            {
                
            }
            //        BOOL result = [documentSharer presentOpenInMenuFromBarButtonItem: sender animated: YES];
        } else
        {
            [_documentShareController presentOpenInMenuFromRect: [sender bounds] inView: self.fractalViewRoot animated: YES];
        }
    }
}
- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    _documentShareController = nil;
}
- (IBAction)shareWithActivityController:(id)sender
{
    NSMutableArray* exportItems = [NSMutableArray new];
    
    // UIImage* fractalImage = [self snapshot: self.fractalView size: CGSizeMake(1024.0, 1024.0) withWatermark: self.appModel.useWatermark];
    UIImage* imageExport;
    CGImageRef baseImageRef = (__bridge CGImageRef)(self.fractalView.layer.contents);
    CGSize imageSize = CGSizeMake(CGImageGetWidth(baseImageRef), CGImageGetHeight(baseImageRef));
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, [[UIScreen mainScreen] scale]);
    {
        CGContextRef aCGontext = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(aCGontext);
        CGFloat flipY = -1.0;
        CGContextScaleCTM(aCGontext, 1.0, flipY);
        CGContextTranslateCTM(aCGontext, 0, -imageSize.height);
        CGContextDrawImage(aCGontext, CGRectMake(0, 0, imageSize.width, imageSize.height), baseImageRef);
        CGContextRestoreGState(aCGontext);
        
        if (self.appModel.useWatermark)
        {
            [self drawWatermarkInContext: aCGontext size: imageSize];
        }
        
        imageExport = UIGraphicsGetImageFromCurrentImageContext();
    }
    
    NSData* pngImage = UIImagePNGRepresentation(imageExport);
    
    NSData* taggedPngImage = [self taggedImageDataWithImageData: pngImage properties: [self taggingDictionary]];
    
    [exportItems addObject: taggedPngImage];
    
    UIActivityViewController *activityViewController;
    activityViewController = [[UIActivityViewController alloc] initWithActivityItems: exportItems applicationActivities:nil];
    
    [activityViewController setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError){
    
#pragma message "TODO make this more generic for other activities?"
        NSLog(@"%s %@ completed: %lu, items: %@", __PRETTY_FUNCTION__, activityType, (unsigned long)completed, returnedItems);
        
        NSString* title;
        NSString* message;
        
        if ([activityType isEqualToString: UIActivityTypePostToFacebook])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypePostToTwitter])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypePostToWeibo])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypeMessage])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypeMail])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypePrint])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypeCopyToPasteboard])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypeAssignToContact])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypeSaveToCameraRoll])
        {
            if (completed)
            {
                title = NSLocalizedString(@"Success", @"");
                message = NSLocalizedString(@"Check your PHOTOS for the fractal", @"");
            }
        }
        else if ([activityType isEqualToString: UIActivityTypeAddToReadingList])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypePostToFlickr])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypePostToVimeo])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypePostToTencentWeibo])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypeAirDrop])
        {
            
        }
        else if ([activityType isEqualToString: UIActivityTypeOpenInIBooks])
        {
            
        }
        
        if (title)
        {
            NSString *okActionTitle = NSLocalizedString(@"OK", nil);
            
            UIAlertController *completionAlertController = [UIAlertController alertControllerWithTitle: title message: message preferredStyle: UIAlertControllerStyleAlert];
            
            [completionAlertController addAction:[UIAlertAction actionWithTitle: okActionTitle style: UIAlertActionStyleDefault handler: nil]];
            
            [self presentViewController: completionAlertController animated: YES completion: nil];
        }
        
    }];
    
    UIPopoverPresentationController* ppc = activityViewController.popoverPresentationController;
    
    
    if ([sender isKindOfClass: [UIBarButtonItem class]])
    {
        ppc.barButtonItem = sender;
    } else
    {
        
        ppc.sourceView = sender;
        ppc.sourceRect = [sender bounds];
    }
    
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController: activityViewController animated: YES completion: ^{
        //
        //        self.currentPresentedController = newController;
    }];
}

-(NSDictionary*)taggingDictionary
{
    // Format the current date and time
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale: [NSLocale currentLocale]];
    //    [formatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    NSString *now = [formatter stringFromDate:[NSDate date]];
    
    NSString *version = self.appModel.buildString;
    NSString *identifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *title = self.fractalDocument.fractal.name;
    NSString *desc = self.fractalDocument.fractal.descriptor;
    
    NSString* appName = [[identifier componentsSeparatedByString: @"."] lastObject];
    
    // Exif metadata dictionary
    // Includes date and time as well as image dimensions
    NSDictionary *exifDictionary = @{(NSString *)kCGImagePropertyExifDateTimeOriginal:now,
                                     (NSString *)kCGImagePropertyExifDateTimeDigitized:now,
                                     (NSString *)kCGImagePropertyExifUserComment: title,
                                     (NSString *)kCGImagePropertyExifLensMake: appName,
                                     (NSString *)kCGImagePropertyExifLensModel:version};
    
    // kCGImagePropertyIPTCCaptionAbstract
    
    // Tiff metadata dictionary
    // Includes information about the application used to create the image
    // "Make" is the name of the app, "Model" is the version of the app
    NSDictionary *tiffDictionary = @{ (NSString *)kCGImagePropertyTIFFDateTime: now,
                                      (NSString *)kCGImagePropertyTIFFMake: appName,
                                      (NSString *)kCGImagePropertyTIFFDocumentName: title,
                                      (NSString *)kCGImagePropertyTIFFImageDescription: desc,
                                      (NSString *)kCGImagePropertyTIFFModel: version};
    
    NSDictionary* pngDictionary = @{(NSString *)kCGImagePropertyPNGDescription: desc,
                                    (NSString *)kCGImagePropertyPNGTitle: title,
                                    (NSString *)kCGImagePropertyPNGSoftware: appName,
                                    (NSString *)kCGImagePropertyPNGAuthor: appName};
    
    // Image metadata dictionary
    // Includes image dimensions, as well as the EXIF and TIFF metadata
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:exifDictionary forKey:(NSString *)kCGImagePropertyExifDictionary];
    [dict setValue:tiffDictionary forKey:(NSString *)kCGImagePropertyTIFFDictionary];
    [dict setValue:pngDictionary forKey:(NSString *)kCGImagePropertyPNGDictionary];
    
    return  dict;
}

-(NSData *)taggedImageDataWithImageData:(NSData *)imageData properties:(NSDictionary *)properties
{
    NSMutableData *mutableImageData = [[NSMutableData alloc] init];
    
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    
    CGImageDestinationRef imageDestinationRef = CGImageDestinationCreateWithData((CFMutableDataRef)mutableImageData, CGImageSourceGetType(imageSourceRef), 1, NULL);
    CGImageDestinationAddImageFromSource(imageDestinationRef, imageSourceRef, 0, (CFDictionaryRef)properties);
    CGImageDestinationFinalize(imageDestinationRef);
    CFRelease(imageDestinationRef);
    
    CFRelease(imageSourceRef);
    
    return [mutableImageData copy];
}


-(NSBlockOperation*) operationForRenderer: (LSFractalRenderer*)renderer percentStart: (CGFloat)start stop: (CGFloat)stop
{
    
    NSBlockOperation* operation = [NSBlockOperation new];
    renderer.operation = operation;
    
    [operation addExecutionBlock: ^{
        //code
        if (!renderer.operation.isCancelled)
        {
            [renderer generateImagePercentStart: start stop: stop];
            if (renderer.mainThreadImageView && renderer.imageRef)
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    renderer.mainThreadImageView.layer.contents = (__bridge id)(renderer.imageRef);
                }];
            }
        }
    }];
    return operation;
}

-(LSFractalRenderer*) newPlaybackRenderer: (NSString*)name
{
    LSFractalRenderer*newRenderer;
    
    if (self.fractalDocument.fractal)
    {
        MDBAppModel* strongAppModel = self.appModel;
        
        NSInteger levelIndex = MIN(3, self.fractalDocument.fractal.level);
        newRenderer = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: strongAppModel.sourceDrawingRules];
        newRenderer.name = name;
        newRenderer.mainThreadImageView = self.fractalView;
        newRenderer.flipY = NO;
        newRenderer.margin = kLevelNMargin;
        newRenderer.showOrigin = !strongAppModel.hideOrigin;
        newRenderer.autoscale = YES;
        newRenderer.autoExpand = self.fractalDocument.fractal.autoExpand;
        newRenderer.levelData = self.levelDataArray[levelIndex];
        MBColor* backgroundColor = self.fractalDocument.fractal.backgroundColor;
        if (!backgroundColor) backgroundColor = [MBColor newMBColorWithUIColor: [UIColor clearColor]];
        newRenderer.backgroundColor = backgroundColor;
    }
    return newRenderer;
}
-(void) swapOldButton: (UIBarButtonItem*)oldButton withNewButton: (UIBarButtonItem*)newButton
{
    NSArray* barItemsArray = self.navigationItem.rightBarButtonItems;
    NSInteger buttonIndex = 0;
    BOOL foundButton = NO;
    for (UIBarButtonItem* item in barItemsArray) {
        if (item == oldButton) {
            foundButton = YES;
            break;
        }
        buttonIndex++;
    }
    NSMutableArray* newItems = [barItemsArray mutableCopy];
    if (foundButton) {
        [newItems removeObjectAtIndex: buttonIndex];
        [newItems insertObject: newButton atIndex: buttonIndex];
    }
    [self.navigationItem setRightBarButtonItems: newItems animated: YES];
}
- (IBAction)playButtonPressed: (id)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"Playback"}];
    
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }
    
    if (!self.fractalDocument.fractal) {
        return;
    }
    
    [self.playbackTimer invalidate];
//    for (UIBarButtonItem* button in self.disabledDuringPlaybackButtons)
//    {
//        button.enabled = NO;
//    }
    
    [self hideToolPaletteWithAnimations: YES];
    [self setNavBarHidden: YES];
    self.fractalViewRootSingleTapRecognizer.enabled = NO;
    self.fractal2PanGR.enabled = NO;
    
    [self swapOldButton: self.playButton withNewButton: self.stopButton];
    
    self.playbackSlider.hidden = NO;
    
    LSFractalRenderer* playback1 = [self newPlaybackRenderer: @"Playback1"];
    LSFractalRenderer* playback2 = [self newPlaybackRenderer: @"Playback2"];
    LSFractalRenderer* playback3 = [self newPlaybackRenderer: @"Playback3"];
    
    if (playback1 && playback2 && playback3) {
        self.playbackRenderers = @[playback1,playback2,playback3];
        
        self.playFrameIncrement = 1.0;
        self.playIsPercentCompleted = 0.0;
        
        [self resumePlayback];
    }
    
    RPScreenRecorder* recorder = [RPScreenRecorder sharedRecorder];
    if (recorder.isAvailable)
    {
        [recorder startRecordingWithMicrophoneEnabled: NO handler:^(NSError * _Nullable error) {
            //
        }];
    }
}

-(void) playNextFrame: (NSTimer*)timer
{
    NSMutableSet* finishedRenderers = [NSMutableSet new];
    /*!
     TODO: add a dependency here so operations don't finish out of order?
     */
    for (LSFractalRenderer*renderer in self.playbackRenderers)
    {
        NSBlockOperation* strongOperation = renderer.operation;
        if (strongOperation == nil || strongOperation.isFinished) {
            [finishedRenderers addObject: renderer];
        }
    }
    
    if (finishedRenderers.count > 0)
    {
        // queue up the next operation
        LSFractalRenderer* availableRender = [finishedRenderers anyObject];
        
        self.playIsPercentCompleted += self.playFrameIncrement;
        
        self.playbackSlider.value = self.playIsPercentCompleted;
        
        CGFloat stop = self.playIsPercentCompleted;
        
        NSBlockOperation* operation = [self operationForRenderer: availableRender percentStart: 0 stop: stop];
        
        [self.privateImageGenerationQueue addOperation: operation];
        
        if (self.playIsPercentCompleted >= 100.0)
        {
            [self stopButtonPressed: nil];
        }
    }
}
-(IBAction) resumePlayback
{
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval: 0.07
                                                          target: self
                                                        selector: @selector(playNextFrame:)
                                                        userInfo: nil
                                                         repeats: YES];
    self.playbackTimer.tolerance = 0.05;
}
-(IBAction) pauseButtonPressed: (id)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"PlayBackPaused"}];
    if ([sender isKindOfClass: [UISlider class]])
    {
        // just pause for slider movement
        [self.playbackTimer invalidate];
        self.playbackTimer = nil;
    }
    else
    {
        if (self.playbackTimer)
        {
            //pause
            [self.playbackTimer invalidate];
            self.playbackTimer = nil;
        }
        else
        {
            //resume
            [self resumePlayback];
        }
    }
}
-(IBAction) stopButtonPressed: (id)sender
{
//    for (UIBarButtonItem* button in self.disabledDuringPlaybackButtons)
//    {
//        button.enabled = YES;
//    }
    
    UISlider* strongPlayback = self.playbackSlider;
    
    if (!strongPlayback.hidden) {
        if (self.playbackTimer)
        {
            //pause
            [self.playbackTimer invalidate];
            self.playbackTimer = nil;
        }
        
        [self queueFractalImageUpdates];
        self.playbackRenderers = nil;
        
        [self swapOldButton: self.stopButton withNewButton: self.playButton];
        strongPlayback.hidden = YES;
    }
    
    [self setNavBarHidden: NO];
    [self showToolPalleteWithAnimations: YES];
    self.fractalViewRootSingleTapRecognizer.enabled = YES;
    self.fractal2PanGR.enabled = YES;

    RPScreenRecorder* recorder = [RPScreenRecorder sharedRecorder];
    if (recorder.isAvailable)
    {
        [recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            //
            if (previewViewController)
            {
                previewViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
                previewViewController.previewControllerDelegate = self;
                self.previewViewController = previewViewController;
                [self presentViewController: previewViewController animated:YES completion:nil];
            }
        }];
    }
}

-(void)previewControllerDidFinish:(RPPreviewViewController *)previewController
{
    [previewController dismissViewControllerAnimated: YES completion: nil];
}

-(IBAction) playSliderChangedValue: (UISlider*)slider
{
    self.playIsPercentCompleted = slider.value;
    [self playNextFrame: nil];
}

-(IBAction)toggleAutoExpandFractal:(id)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"ToggleAutoExpand"}];
    self.fractalDocument.fractal.autoExpand = !self.fractalDocument.fractal.autoExpand;
}

- (IBAction)toggleNavBar:(id)sender
{
    BOOL hidden = !self.navigationController.navigationBar.isHidden;
    [self setNavBarHidden: hidden];
}

-(void) setNavBarHidden: (BOOL)hidden
{
    //    self.navigationController.navigationBar.hidden = hidden;
    //    self.previousNavBarState = self.navigationController.navigationBar.hidden;
    self.previousNavBarState = hidden;
    [self.navigationController setNavigationBarHidden: hidden animated: YES];
    
    [self.view setNeedsLayout];
}

- (IBAction)copyFractal:(id)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"CopyFractal"}];
    
    LSFractal* newFractal = [self.fractalDocument.fractal copy];
    
    self.fractalInfo = nil;
    
    MDBFractalInfo* fractalInfo = [self.appModel.documentController createFractalInfoForFractal: newFractal withImage: [self.fractalDocument.thumbnail copy] withDocumentDelegate: self];
    
    [self setFractalInfo: fractalInfo andShowCopiedAlert: YES];
}

- (IBAction)showSaveFractalAlert:(id)sender
{
    if (self.hasBeenEdited)
    {
        MBLSFractalEditViewController* __weak weakSelf = self;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"",nil)
                                                                       message: nil
                                                                preferredStyle: UIAlertControllerStyleActionSheet];
        
        
        UIAlertAction* saveAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Save As Is",nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action)
                                     {
                                         [weakSelf performSegueWithIdentifier: @"UnwindSegueToLibrary" sender: self];
                                     }];
        
        [alert addAction: saveAction];
        
        UIAlertAction* copyAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Save As Copy",nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action)
                                     {
                                         MBLSFractalEditViewController* strongSelf = weakSelf;
                                         
                                         LSFractal* newFractal = [strongSelf.fractalDocument.fractal copy];
                                         UIImage* thumbnail = [self.fractalDocument.thumbnail copy];
                                         
                                         [strongSelf restoreOriginalFractal];
                                         
                                         strongSelf.fractalInfo = nil;
                                         
                                         strongSelf.fractalInfo = [strongSelf.appModel.documentController createFractalInfoForFractal: newFractal withImage: thumbnail withDocumentDelegate: strongSelf];
                                         
                                         [strongSelf performSegueWithIdentifier: @"UnwindSegueToLibrary" sender: strongSelf];
                                     }];
        
        [alert addAction: copyAction];
        
        UIAlertAction* discardAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Discard Changes",nil)
                                                                style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction * action)
                                        {
                                            MBLSFractalEditViewController* strongSelf = weakSelf;
                                            [strongSelf restoreOriginalFractal];
                                            [strongSelf performSegueWithIdentifier: @"UnwindSegueToLibrary" sender: strongSelf];
                                        }];
        
        [alert addAction: discardAction];
        
        alert.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController* ppc = alert.popoverPresentationController;
        ppc.barButtonItem = sender;
        ppc.delegate = self;
        
        [self presentViewController: alert animated: YES completion: nil];
    }
    else
    {
        [self performSegueWithIdentifier: @"UnwindSegueToLibrary" sender: self];
    }
}

- (IBAction)levelInputChanged:(UIStepper*)sender
{
    double rawValue = sender.value;
    CGFloat roundedNumber = (CGFloat)lround(rawValue);
    self.fractalDocument.fractal.levelUnchanged = NO;
    self.fractalDocument.fractal.level = roundedNumber; // triggers observer
    self.hasBeenEdited = YES;
    //    [self updateLibraryRepresentationIfNeeded];
}

#pragma mark - HUD Slider Actions
- (IBAction)randomnessSliderChanged:(UISlider*)sender
{
    CGFloat percent = sender.value;
    CGFloat steppedPercent = percent - fmodf(percent, 0.05);
    self.fractalDocument.fractal.randomness = steppedPercent;
    //    [self updateLibraryRepresentationIfNeeded];
}

- (IBAction)baseAngleSliderChanged:(UISlider*)sender
{
    CGFloat newAngleDegrees = sender.value;
    CGFloat steppedNewAngleDegrees = newAngleDegrees - fmodf(newAngleDegrees, 5.0);
    self.fractalDocument.fractal.baseAngle = radians(steppedNewAngleDegrees);
    //    [self updateLibraryRepresentationIfNeeded];
}

- (IBAction)lineWidthSliderChanged:(UISlider*)sender
{
    CGFloat percent = sender.value;
    CGFloat steppedPercent = percent - fmodf(percent, 0.05);
    self.fractalDocument.fractal.lineWidth = steppedPercent;
    //    [self updateLibraryRepresentationIfNeeded];
}

- (IBAction)turnAngleSliderChanged:(UISlider*)sender
{
    CGFloat newAngleDegrees = sender.value;
    CGFloat steppedNewAngleDegrees = newAngleDegrees - fmodf(newAngleDegrees, 1.0);
    self.fractalDocument.fractal.turningAngle = radians(steppedNewAngleDegrees);
    //    [self updateLibraryRepresentationIfNeeded];
}

- (IBAction)lineLengthIncrementSliderChanged:(UISlider*)sender
{
    CGFloat percent = sender.value;
    CGFloat steppedPercent = percent - fmodf(percent, 0.05);
    self.fractalDocument.fractal.lineChangeFactor = steppedPercent;
    //    [self updateLibraryRepresentationIfNeeded];
}

- (IBAction)turningAngleIncrementSliderChanged:(UISlider*)sender
{
    CGFloat percent = sender.value;
    CGFloat steppedPercent = percent - fmodf(percent, 0.05);
    self.fractalDocument.fractal.turningAngleIncrement = steppedPercent;
    //    [self updateLibraryRepresentationIfNeeded];
}



#pragma mark - Filter Actions

/*!
 Returns unreleased CGImageRef
 */
-(CGImageRef)newCGImageRefToBitmapFromFiltersAppliedToCIImage: (CIImage*)ciiImage
{
    MDBFractalObjectList* filters = self.fractalDocument.fractal.imageFilters;
    
    CGImageRef filteredImageRef = NULL;
    
    if (filters && !filters.isEmpty) {
        
        CGFloat imageWidth = ciiImage.extent.size.width;
        CGFloat imageHeight = ciiImage.extent.size.height;
        CGRect imageBounds = CGRectMake(0.0, 0.0, imageWidth, imageHeight);
        //    CGFloat midX = imageWidth/2.0;
        //    CGFloat midY = imageHeight/2.0;
        CGContextClearRect(self.filterBitmapContext, CGContextGetClipBoundingBox(self.filterBitmapContext));
        
        @autoreleasepool
        {
            CIImage* filteredImage = ciiImage;
            
            for (MBImageFilter* filter in self.fractalDocument.fractal.imageFilters)
            {
                filteredImage = [filter getOutputCIImageForInputCIImage: filteredImage];
            }
            filteredImage = [filteredImage imageByCroppingToRect: imageBounds];
            
            if ((YES))
            {
                CGContextRef bitmapContext = self.filterBitmapContext;
                
                void* bitmap = CGBitmapContextGetData(bitmapContext);
                ptrdiff_t bytes = CGBitmapContextGetBytesPerRow(bitmapContext);
                CGRect bounds = CGRectMake(0, 0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext));
                CGColorSpaceRef colorSpace = CGBitmapContextGetColorSpace(bitmapContext);
                
                [[MBImageFilter filterContext] render: filteredImage toBitmap: bitmap rowBytes: bytes bounds: bounds format: kCIFormatRGBA8 colorSpace: colorSpace];
                
                filteredImageRef = CGBitmapContextCreateImage(bitmapContext);
            }
            else
            {
                filteredImageRef = [[MBImageFilter filterContext] createCGImage: filteredImage fromRect: imageBounds];
            }
        }
    }
    
    return filteredImageRef;
}

-(CGImageRef)newCGImageRefForSnapshotFromFiltersAppliedToCIImage: (CIImage*)ciiImage
{
    MDBFractalObjectList* filters = self.fractalDocument.fractal.imageFilters;
    
    CGImageRef filteredImageRef = NULL;
    
    if (filters && !filters.isEmpty) {
        //        [self.activityIndicator startAnimating];
        
        CGFloat imageWidth = ciiImage.extent.size.width;
        CGFloat imageHeight = ciiImage.extent.size.height;
        CGRect imageBounds = CGRectMake(0.0, 0.0, imageWidth, imageHeight);
        //    CGFloat midX = imageWidth/2.0;
        //    CGFloat midY = imageHeight/2.0;
        
#pragma message "TODO need to make snapshotFilters independent of screen filter context and settings..."
        @autoreleasepool
        {
            CIImage* filteredImage = ciiImage;
            
            for (MBImageFilter* filter in self.fractalDocument.fractal.imageFilters)
            {
                filteredImage = [filter getOutputCIImageForInputCIImage: filteredImage];
            }
            filteredImage = [filteredImage imageByCroppingToRect: imageBounds];
#pragma message "TODO fix crash with autoAdjustment and Drost filter"
            if ((NO)) // bad memory exec for some filters when this is enabled. Such as Drost
            {
                NSDictionary* options = @{kCIImageAutoAdjustCrop:@YES,
                                          kCIImageAutoAdjustRedEye:@NO,
                                          kCIImageAutoAdjustEnhance:@NO,
                                          kCIImageAutoAdjustFeatures:@[],
                                          kCIImageAutoAdjustLevel:@NO};
                
                NSArray *adjustments = [filteredImage autoAdjustmentFiltersWithOptions: options];
                for (CIFilter *filter in adjustments)
                {
                    [filter setValue: filteredImage forKey: kCIInputImageKey];
                    filteredImage = filter.outputImage;
                }
            }
            
            filteredImageRef = [[MBImageFilter snapshotFilterContext] createCGImage: filteredImage fromRect: imageBounds];
        }
        //        [self.activityIndicator stopAnimating];
    }
    
    return filteredImageRef;
}


//
- (IBAction)toggleApplyFilter:(id)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"ToggleApplyFilter"}];
    
    MDBFractalObjectList* filters = self.fractalDocument.fractal.imageFilters;
    BOOL filtersOn = self.fractalDocument.fractal.applyFilters;
    
    if (filters.isEmpty && filtersOn)
    {
        self.fractalDocument.fractal.applyFilters = NO;
    }
    else if (!filters.isEmpty)
    {
        self.fractalDocument.fractal.applyFilters = !filtersOn; // should trigger observers
        
        self.hasBeenEdited = YES;
        //        [self updateLibraryRepresentationIfNeeded];
    }
    [self updateFilterSettingsForCanvas];
}


#pragma mark - Gestures
// ensure that the pinch, pan and rotate gesture recognizers on a particular view can all recognize simultaneously
// prevent other gesture recognizers from recognizing simultaneously
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    // if the gesture recognizers's view isn't one of our pieces, don't allow simultaneous recognition
    if (gestureRecognizer.view != self.fractalView)
        return NO;
    
    // if the gesture recognizers are on different views, don't allow simultaneous recognition
    if (gestureRecognizer.view != otherGestureRecognizer.view)
        return NO;
    
    // if either of the gesture recognizers is the long press, don't allow simultaneous recognition
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
        return NO;
    
    //    return YES;
    return SIMULTOUCH;
}

-(void)startPanBackgroundFadeTimer
{
    if (self.panIndicatorBackgroundFadeTimer.valid) [self.panIndicatorBackgroundFadeTimer invalidate];
    
    for (UIImageView* imageView in self.backgroundsToFade)
    {
        imageView.alpha = 1.0;
    }
    
    self.panIndicatorBackgroundFadeTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0
                                                                            target: self
                                                                          selector: @selector(fadePanIndicatorBackground:)
                                                                          userInfo: nil repeats: NO];
}

-(void) fadePanIndicatorBackground:(NSTimer*)timer
{
    [UIView animateWithDuration: 2.0 animations:^{
        
        for (UIImageView* imageView in self.backgroundsToFade)
        {
            imageView.alpha = 0.0;
        }
        
    }];
}

-(void)changePanIndicatorsTo: (NSArray*)indicatorsToShow animate: (BOOL)animate
{
    [self startPanBackgroundFadeTimer];
    
    NSMutableArray* indicatorsToHide = [self.panIndicators mutableCopy];
    [indicatorsToHide removeObjectsInArray: indicatorsToShow];
    
    for (UIView* showView in indicatorsToShow)
    {
        showView.hidden = NO;
    }
    
    [UIView animateWithDuration: 1.0 animations:^{
        //
        for (UIView* hideView in indicatorsToHide)
        {
            hideView.alpha = 0.0;
        }
        
        for (UIView* showView in indicatorsToShow)
        {
            showView.alpha = 1.0;
        }
    }];
}

-(void)activateToolbarPanButton: (UIButton*)buttonToActivate
{
    NSMutableArray* buttonsToHide = [self.panToolbarButtons mutableCopy];
    [buttonsToHide removeObject: buttonToActivate];
    
    for (UIButton* button in buttonsToHide)
    {
        button.selected = NO;
    }
    
    buttonToActivate.selected = YES;
}

- (IBAction)moveTwoFingerPanToBaseRotation:(UIButton *)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"PanSelectBaseAngle"}];
    
    self.twoFingerPanProperties = @{@"imageView":self.fractalView,
                                    @"hPath":@"baseAngle",
                                    @"hScale":@5,
                                    @"hStep":@1,
                                    @"hFormatter":self.angleFormatter,
                                    @"vPath":@"randomness",
                                    @"vScale":@-0.0001,
                                    @"vFormatter":self.percentFormatter};
    
    [self activateToolbarPanButton: self.baseRotationButton];
    [self changePanIndicatorsTo: @[self.panIndicatorBaseAngle, self.panIndicatorRandomization] animate: YES];
    
    self.panValueLabelHorizontal.text = [self.angleFormatter stringFromNumber: [NSNumber numberWithFloat: degrees(self.fractalDocument.fractal.baseAngle)]];
    self.panValueLabelVertical.text = [self.percentFormatter stringFromNumber: [NSNumber numberWithFloat: self.fractalDocument.fractal.randomness]];
}

- (IBAction)moveTwoFingerPanToJointAngle:(UIButton *)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"PanSelectTurnAngle"}];
    
    self.twoFingerPanProperties = @{@"imageView":self.fractalView,
                                    @"hPath":@"turningAngle",
                                    @"hScale":@0.5,
                                    @"hStep":@0.01,
                                    @"hFormatter":self.angleFormatter,
                                    @"vPath":@"lineWidth",
                                    @"vScale":@0.01,
                                    @"vFormatter":self.onePlaceFormatter};
    
    [self activateToolbarPanButton: self.jointAngleButton];
    [self changePanIndicatorsTo: @[self.panIndicatorTurnAngle, self.panIndicatorLineWidth] animate: YES];
    
    self.panValueLabelHorizontal.text = [self.angleFormatter stringFromNumber: [NSNumber numberWithFloat: degrees(self.fractalDocument.fractal.turningAngle)]];
    self.panValueLabelVertical.text = [self.onePlaceFormatter stringFromNumber: [NSNumber numberWithFloat: self.fractalDocument.fractal.lineWidth]];
}

- (IBAction)moveTwoFingerPanToIncrements:(UIButton *)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"PanSelectIncrements"}];
    
    self.twoFingerPanProperties = @{@"imageView":self.fractalView,
                                    @"hPath":@"turningAngleIncrement",
                                    @"hScale":@0.0001,
                                    @"hStep":@0.00001,
                                    @"hFormatter":self.percentFormatter,
                                    @"vPath":@"lineChangeFactor",
                                    @"vScale":@-0.0001,
                                    @"vFormatter":self.percentFormatter};
    
    [self activateToolbarPanButton: self.incrementsButton];
    [self changePanIndicatorsTo: @[self.panIndicatorDecrementsAngle, self.panIndicatorDecrementsLine] animate: YES];
    
    self.panValueLabelHorizontal.text = [self.percentFormatter stringFromNumber: [NSNumber numberWithFloat: self.fractalDocument.fractal.turningAngleIncrement]];
    self.panValueLabelVertical.text = [self.percentFormatter stringFromNumber: [NSNumber numberWithFloat: self.fractalDocument.fractal.lineChangeFactor]];
}

- (IBAction)moveTwoFingerPanToHueIncrements:(UIButton *)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"PanSelectHues"}];
    
    self.twoFingerPanProperties = @{@"imageView":self.fractalView,
                                    @"hPath":@"fillHueRotationPercent",
                                    @"hScale":@0.001,
                                    @"hStep":@0.000001,
                                    @"hFormatter":self.percentFormatter,
                                    @"vPath":@"lineHueRotationPercent",
                                    @"vScale":@-0.001,
                                    @"vFormatter":self.percentFormatter};
    
    [self activateToolbarPanButton: self.hueIncrementsButton];
    [self changePanIndicatorsTo: @[self.panIndicatorHueFill, self.panIndicatorHueLine] animate: YES];
    
    self.panValueLabelHorizontal.text = [self.angleFormatter stringFromNumber: [NSNumber numberWithFloat: self.fractalDocument.fractal.fillHueRotationPercent]];
    self.panValueLabelVertical.text = [self.percentFormatter stringFromNumber: [NSNumber numberWithFloat: self.fractalDocument.fractal.lineHueRotationPercent]];
}

- (IBAction)togglePan10x:(UIButton *)sender
{
    [Answers logCustomEventWithName: @"FractalEdit" customAttributes: @{@"Action" : @"Toggle10X"}];
    
    [self startPanBackgroundFadeTimer];
    
    self.pan10xOn = !self.pan10xOn;
    self.pan10xToggleButton.selected = self.pan10xOn;
    if (self.pan10xOn)
    {
        self.pan10xValue = self.pan10xMultiplier;
    }
    else
    {
        self.pan10xValue = 1.0;
    }
}

/* want to use 2 finger pans for changing rotation and line thickness in place of swiping
 need to lock in either horizontal or vertical panning view a state and state change */
-(IBAction)twoFingerPanFractal:(UIPanGestureRecognizer *)gestureRecognizer
{
    NSDictionary* panProps = [self.twoFingerPanProperties copy];
    
    [self convertPan: gestureRecognizer
         onImageView: panProps[@"imageView"]
horizontalPropertyPath: panProps[@"hPath"]
              hScale: [(NSNumber*)panProps[@"hScale"] floatValue]
               hStep: [(NSNumber*)panProps[@"hStep"] floatValue]
          hFormatter: panProps[@"hFormatter"]
verticalPropertyPath: panProps[@"vPath"]
              vScale: [(NSNumber*)panProps[@"vScale"] floatValue]
          vFormatter: panProps[@"vFormatter"]];
}
- (IBAction)panLevel0:(UIPanGestureRecognizer *)sender
{
    [self convertPan: sender
         onImageView: self.fractalViewLevel0
horizontalPropertyPath: @"baseAngle"
              hScale: 5.0/1.0
               hStep:    1.0
          hFormatter: self.angleFormatter
verticalPropertyPath: @"randomness"
              vScale: -1.0/1000.0
          vFormatter: self.percentFormatter];
}
- (IBAction)panLevel1:(UIPanGestureRecognizer *)sender
{
    [self convertPan: sender
         onImageView: self.fractalViewLevel1
horizontalPropertyPath: @"turningAngle"
              hScale: 1.0/2.0
               hStep:    0.25
          hFormatter: self.angleFormatter
verticalPropertyPath:@"lineWidth"
              vScale: 5.0/50.0
          vFormatter: self.onePlaceFormatter];
}
- (IBAction)panLevel2:(UIPanGestureRecognizer *)sender
{
    [self convertPan: sender
         onImageView: self.fractalViewLevel2
horizontalPropertyPath: @"turningAngleIncrement"
              hScale: 1.0/1000.0
               hStep: 0.01
          hFormatter: self.percentFormatter
verticalPropertyPath: @"lineChangeFactor"
              vScale: -1.0/1000.0
          vFormatter: self.percentFormatter];
}

-(void) convertPan: (UIPanGestureRecognizer*) gestureRecognizer
       onImageView: (UIImageView*) subLayer
horizontalPropertyPath: (NSString*) horizontalPath
            hScale: (CGFloat) hScale
             hStep: (CGFloat) hStepSize
        hFormatter: (NSNumberFormatter*)hFormatter
verticalPropertyPath: (NSString*) verticalPath
            vScale: (CGFloat) vScale
        vFormatter:(NSNumberFormatter*)vFormatter
{
    [self startPanBackgroundFadeTimer];
    
    static CGPoint initialPosition;
    static CGFloat  initialHValue;
    static CGFloat  initialVValue;
    static NSInteger determinedState;
    static BOOL     isIncreasing;
    static NSInteger axisState;
    
    hScale *= self.pan10xValue;
    vScale *= self.pan10xValue;
    
    LSFractal* fractal = self.fractalDocument.fractal;
    
    UIView *fractalView = [gestureRecognizer view];
    UIGestureRecognizerState state = gestureRecognizer.state;
    
    CGFloat hMin = [fractal minValueForProperty: horizontalPath];
    CGFloat hMax = [fractal maxValueForProperty: horizontalPath];
    
    CGFloat vMin = [fractal minValueForProperty: verticalPath];
    CGFloat vMax = [fractal maxValueForProperty: verticalPath];
    
    if (state == UIGestureRecognizerStateBegan)
    {
        self.autoscaleN = NO;
        
        //        [self.undoManager beginUndoGrouping];
        //        [self.fractalDocument.fractal.managedObjectContext processPendingChanges];
        
        initialPosition = CGPointZero;//subLayer.position;
        
        if (horizontalPath)
        {
            if ([fractal isAngularProperty: horizontalPath])
            {
                initialHValue =  floorf(100.0 * degrees([[fractal valueForKey: horizontalPath] doubleValue])) / 100.0;
            }
            else
            {
                initialHValue = floorf(100.0 * [[fractal valueForKey: horizontalPath] doubleValue]) / 100.0;
            }
        }
        if (verticalPath)
        {
            initialVValue = floorf(100.0 * [[fractal valueForKey: verticalPath] doubleValue]) / 100.0;
        }
        
        determinedState = 0;
        isIncreasing = NO;
        
    } else if (state == UIGestureRecognizerStateChanged)
    {
        
        CGPoint translation = [gestureRecognizer translationInView: fractalView];
        //        CGPoint velocity = [gestureRecognizer velocityInView: fractalView];
        
        if (determinedState==0)
        {
            if (fabs(translation.x) >= fabs(translation.y))
            {
                axisState = 0;
            } else
            {
                axisState = 1;
            }
            determinedState = 1;
        } else
        {
            if (axisState && verticalPath)
            {
                // vertical, change aspect
                CGFloat scaledWidth = floorf(translation.y * vScale * 100000.0)/100000.0;
                CGFloat newWidth = fminf(fmaxf(initialVValue + scaledWidth, vMin), vMax);
                [fractal setValue: @(newWidth) forKey: verticalPath];
                self.panValueLabelVertical.text = [vFormatter stringFromNumber: @(newWidth)];
                //self.fractalDocument.fractal.lineWidth = @(newidth);
                
            }
            else if (!axisState && horizontalPath)
            {
                // hosrizontal
                if ([fractal isAngularProperty: horizontalPath])
                {
                    CGFloat scaledStepAngle = floorf(translation.x * hScale)/100;
                    CGFloat newAngleDegrees = fminf(fmaxf(initialHValue + scaledStepAngle, hMin), hMax);
                    CGFloat steppedNewDegrees = newAngleDegrees - fmodf(newAngleDegrees, hStepSize);
                    [fractal setValue: @(radians(steppedNewDegrees)) forKey: horizontalPath];
                    self.panValueLabelHorizontal.text = [hFormatter stringFromNumber: @(steppedNewDegrees)];
                }
                else
                {
                    CGFloat scaled = floorf(translation.x * hScale * 100000.0)/100000.0;
                    CGFloat newValue = fminf(fmaxf(initialHValue + scaled, hMin), hMax);
                    [fractal setValue: @(newValue) forKey: horizontalPath];
                    self.panValueLabelHorizontal.text = [hFormatter stringFromNumber: @(newValue)];
                }
                
            }
        }
        
    } else if (state == UIGestureRecognizerStateCancelled)
    {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
        if ([fractal isAngularProperty: horizontalPath])
        {
            [fractal setValue:  @(radians(initialHValue)) forKey: horizontalPath];
        }else
        {
            [fractal setValue:  @(initialHValue) forKey: horizontalPath];
        }
        //[self.fractalDocument.fractal setTurningAngleAsDegrees:  @(initialAngleDegrees)];
        determinedState = 0;
        //        if ([self.undoManager groupingLevel] > 0)
        //        {
        //            [self.undoManager endUndoGrouping];
        //            [self.undoManager undoNestedGroup];
        //        }
    } else if (state == UIGestureRecognizerStateEnded)
    {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
        determinedState = 0;
        self.autoscaleN = YES;
        self.hasBeenEdited = YES;
        //        [self updateLibraryRepresentationIfNeeded];
    }
}

-(IBAction) autoScale:(id)sender
{
    //    CALayer* subLayer = nil; //[self fractalLevelNLayer];
    //    subLayer.transform = CATransform3DIdentity;
    //    subLayer.position = self.fractalView.center;
    // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
    [self.fractalScrollView setZoomScale: 1.0 animated: YES];
    [self.fractalScrollView setContentOffset: CGPointZero animated: YES];
}

- (IBAction)toggleFullScreen:(id)sender
{
    BOOL fullScreenState;
    if (self.fractalViewLevel0.superview.hidden == YES)
    {
        [self fullScreenOff];
        fullScreenState = NO;
    } else
    {
        [self fullScreenOn];
        fullScreenState = YES;
    }
    [self.appModel setFullScreenState: fullScreenState];
}

-(void) fullScreenOnDuration: (NSTimeInterval)duration
{
    self.panIndicatorsContainerView.hidden = NO;
    
    [UIView animateWithDuration: duration
                     animations:^{
                         self.panIndicatorsContainerView.alpha = 1.0;
                         self.fractalViewLevel0.superview.alpha = 0;
                         self.fractalViewLevel1.superview.alpha = 0;
                         self.fractalViewLevel2.superview.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         self.fractalViewLevel0.superview.hidden = YES;
                         [self setFractalRendererL0: nil];
                         
                         self.fractalViewLevel1.superview.hidden = YES;
                         [self setFractalRendererL1: nil];
                         
                         self.fractalViewLevel2.superview.hidden = YES;
                         [self setFractalRendererL2: nil];
                     }];
}

-(void) fullScreenOn
{
    [self fullScreenOnDuration: 0.5];
}

-(void) fullScreenOff
{
    //    [self moveEditorHeightTo: self.cachedEditorsHeight];
    self.fractalViewLevel0.superview.hidden = NO;
    self.fractalViewLevel1.superview.hidden = NO;
    self.fractalViewLevel2.superview.hidden = NO;
    [self queueHudImageUpdates];
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.panIndicatorsContainerView.alpha = 0;
                         self.fractalViewLevel0.superview.alpha = 0.75;
                         self.fractalViewLevel1.superview.alpha = 0.75;
                         self.fractalViewLevel2.superview.alpha = 0.75;
                     } completion:^(BOOL finished) {
                         self.panIndicatorsContainerView.hidden = YES;
                     }];
}

- (UIImage *)snapshot:(UIView *)view size: (CGSize)imageSize withWatermark: (BOOL)useWatermark
{
    UIImage* imageExport;
    
    static CIFilter* contrastFilter = nil;
    
    if (!contrastFilter) contrastFilter = [CIFilter filterWithName: @""];
    
    LSFractalRenderer* renderer = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.appModel.sourceDrawingRules];
    NSInteger level = MIN(self.fractalDocument.fractal.level, 3) ;
    renderer.levelData = self.levelDataArray[level];
    renderer.name = @"Image renderer";
    renderer.margin = imageSize.width > 500.0 ? 24.0 : 8.0;
    renderer.autoscale = YES;
    renderer.flipY = YES;
    renderer.showOrigin = NO;
    renderer.applyFilters = self.fractalDocument.fractal.applyFilters;
    
    MBColor* backgroundColor = self.fractalDocument.fractal.backgroundColor;
    if (!backgroundColor) backgroundColor = [MBColor newMBColorWithUIColor: [UIColor clearColor]];
    renderer.backgroundColor = backgroundColor;
    renderer.autoExpand = !self.fractalDocument.fractal.applyFilters || self.fractalDocument.fractal.autoExpand;
    
    CGFloat maxOriginalDimension = MAX(self.fractalView.bounds.size.width,self.fractalView.bounds.size.height);
    
    CGFloat aspect = MIN(maxOriginalDimension/self.fractalView.bounds.size.width,maxOriginalDimension/self.fractalView.bounds.size.height);
    
    CGSize renderSize = CGSizeMake(maxOriginalDimension, maxOriginalDimension);
    
    CGFloat maxSnapshotDimension = MAX(imageSize.width, imageSize.height);
    
    CGFloat scale = maxSnapshotDimension/maxOriginalDimension;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, [[UIScreen mainScreen] scale]);
    {
        CGContextRef aCGontext = UIGraphicsGetCurrentContext();
        
        CGContextScaleCTM(aCGontext, scale, scale);
        [renderer drawInContext: aCGontext size: renderSize];
        
        if (useWatermark && !renderer.applyFilters) [self drawWatermarkInContext: aCGontext size: imageSize];
        
        if (renderer.applyFilters)
        {
            
            CGImageRef tempImage = CGBitmapContextCreateImage(aCGontext);
            CIImage* inputImage = [CIImage imageWithCGImage: tempImage];
            
            CGRect snapshotBounds = CGRectMake(0.0, 0.0, imageSize.width*[[UIScreen mainScreen] scale], imageSize.height*[[UIScreen mainScreen] scale]*aspect);
            
            for (MBImageFilter* filter in self.fractalDocument.fractal.imageFilters)
            {
                [filter setGoodDefaultsForbounds: snapshotBounds];
            }
            
            CGImageRef outputImage = [self newCGImageRefForSnapshotFromFiltersAppliedToCIImage: inputImage];
            imageExport = [UIImage imageWithCGImage: outputImage];
            [self updateFilterSettingsForCanvas];
            if (tempImage != NULL) CGImageRelease(tempImage);
            if (outputImage != NULL) CGImageRelease(outputImage);
        }
        else
        {
            imageExport = UIGraphicsGetImageFromCurrentImageContext();
        }
    }
    UIGraphicsEndImageContext();
    
    if (useWatermark && renderer.applyFilters)
    {
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 2.0);
        {
            CGContextRef aCGContext = UIGraphicsGetCurrentContext();
            CGContextSaveGState(aCGContext);
            CGContextTranslateCTM(aCGContext, 0.0, imageSize.height);
            CGContextScaleCTM(aCGContext, 1.0, -1.0);
            CGContextDrawImage(aCGContext, CGRectMake(0, 0, imageSize.width, imageSize.height), imageExport.CGImage);
            CGContextRestoreGState(aCGContext);
            [self drawWatermarkInContext: aCGContext size: imageSize];
            imageExport = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
    }
    
    return imageExport;
}

-(void)drawWatermarkInContext: (CGContextRef)aCGContext size: (CGSize)imageSize
{
    //    NSString* watermark = @"FractalScapes";
    //    UIFont* font = [UIFont fontWithName: @"Papyrus" size: 96];
    //    CGSize wSize = [watermark sizeWithAttributes: @{NSFontAttributeName : font}];
    //    CGRect wRect = CGRectOffset(CGRectMake(-wSize.width/2.0, -wSize.height/2.0, wSize.width, wSize.height), imageSize.width/2.0, imageSize.height/8.0);
    //    CGContextSetBlendMode(aCGContext, kCGBlendModeDifference);
    //    [watermark drawInRect: wRect withAttributes: @{NSFontAttributeName:font,NSForegroundColorAttributeName:[FractalScapeIconSet selectionBackgrundColor]}];
    
    CGFloat fontSize = 32.0;
    CGFloat width = 682.0/2.0;
    CGFloat height = 168.0/1.0;
    CGFloat margin = 64.0;
    //    CGRect textRect = CGRectMake(imageSize.width - margin - width, imageSize.height - margin - height, width, height);
    CGRect textRect = CGRectMake(imageSize.width - width, imageSize.height - height, width, height);
    NSString* watermark = @"FractalScapes";
    CGContextSaveGState(aCGContext);
    {
        CGContextSetShadowWithColor(aCGContext, FractalScapeIconSet.topShadow.shadowOffset, FractalScapeIconSet.topShadow.shadowBlurRadius, [FractalScapeIconSet.topShadow.shadowColor CGColor]);
        NSMutableParagraphStyle* textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
        textStyle.alignment = NSTextAlignmentCenter;
        
        NSDictionary* textFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"Papyrus" size: fontSize], NSForegroundColorAttributeName: FractalScapeIconSet.selectionBackgroundColor, NSParagraphStyleAttributeName: textStyle};
        
        CGFloat textTextHeight = [watermark boundingRectWithSize: CGSizeMake(textRect.size.width, INFINITY)  options: NSStringDrawingUsesLineFragmentOrigin attributes: textFontAttributes context: nil].size.height;
        CGRect textTextRect = CGRectMake(CGRectGetMinX(textRect), CGRectGetMinY(textRect) + (CGRectGetHeight(textRect) - textTextHeight) / 2, CGRectGetWidth(textRect), textTextHeight);
        CGContextSaveGState(aCGContext);
        {
            CGContextClipToRect(aCGContext, textRect);
            [watermark drawInRect: textTextRect withAttributes: textFontAttributes];
        }
        CGContextRestoreGState(aCGContext);
        
        ////// Text Text Inner Shadow
        CGContextSaveGState(aCGContext);
        {
            UIRectClip(textRect);
            CGContextSetShadowWithColor(aCGContext, CGSizeZero, 0, NULL);
            
            CGContextSetAlpha(aCGContext, CGColorGetAlpha([FractalScapeIconSet.dropShadowInner.shadowColor CGColor]));
            CGContextBeginTransparencyLayer(aCGContext, NULL);
            {
                UIColor* opaqueShadow = [FractalScapeIconSet.dropShadowInner.shadowColor colorWithAlphaComponent: 1];
                CGContextSetShadowWithColor(aCGContext, FractalScapeIconSet.dropShadowInner.shadowOffset, FractalScapeIconSet.dropShadowInner.shadowBlurRadius, [opaqueShadow CGColor]);
                
                CGContextSetBlendMode(aCGContext, kCGBlendModeSourceOut);
                CGContextBeginTransparencyLayer(aCGContext, NULL);
                
                textFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"Papyrus" size: fontSize], NSForegroundColorAttributeName: opaqueShadow, NSParagraphStyleAttributeName: textStyle};
                [watermark drawInRect: textTextRect withAttributes: textFontAttributes];
                
                CGContextEndTransparencyLayer(aCGContext);
            }
            CGContextEndTransparencyLayer(aCGContext);
        }
        CGContextRestoreGState(aCGContext);
    }
    CGContextRestoreGState(aCGContext);
}
-(NSData*) createPDF
{
    CGRect imageBounds = CGRectMake(0, 0, 1024, 1024);
    
    LSFractalRenderer* renderer = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.appModel.sourceDrawingRules];
    renderer.levelData = self.levelDataArray[3];
    renderer.name = @"PDF renderer";
    renderer.margin = 72.0;
    renderer.autoscale = YES;
    renderer.autoExpand = self.fractalDocument.fractal.autoExpand;
    renderer.flipY = YES;
    renderer.showOrigin = NO;
    MBColor* backgroundColor = self.fractalDocument.fractal.backgroundColor;
    if (!backgroundColor) backgroundColor = [MBColor newMBColorWithUIColor: [UIColor clearColor]];
    renderer.backgroundColor = backgroundColor;
    
    NSMutableData* pdfData = [NSMutableData data];
    NSDictionary* pdfMetaData = @{(NSString*)kCGPDFContextCreator:@"FractalScape", (NSString*)kCGPDFContextTitle:self.fractalDocument.fractal.name};
    
    UIGraphicsBeginPDFContextToData(pdfData, imageBounds, pdfMetaData);
    
    {
        UIGraphicsBeginPDFPage();
        CGContextRef pdfContext = UIGraphicsGetCurrentContext();
        [renderer drawInContext: pdfContext size: imageBounds.size];
    }
    UIGraphicsEndPDFContext();
    
    //    CFDataRef myPDFData        = (CFDataRef)pdfData;
    //    CGDataProviderRef provider = CGDataProviderCreateWithCFData(myPDFData);
    //    CGPDFDocumentRef pdf       = CGPDFDocumentCreateWithProvider(provider);
    return pdfData;
}
-(NSURL*)savePDFData: (NSData*)pdfData
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    // The file extension is important so that some mime magic happens!
    NSString* fileName = [NSString stringWithFormat: @"%@.pdf",self.fractalDocument.fractal.name];
    NSString *filePath = [docsPath stringByAppendingPathComponent: fileName];
    NSURL *fileUrl     = [NSURL fileURLWithPath:filePath];
    
    [pdfData writeToURL:fileUrl atomically:YES]; // save the file
    
    return fileUrl;
}

/*
 Unused but save as a reference to handling image meta data.
 */
//-(void) shareFractalToCameraRoll
//{
//    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
//
//    if (cameraAuthStatus == ALAuthorizationStatusNotDetermined || cameraAuthStatus == ALAuthorizationStatusAuthorized)
//    {
//        ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
//
//        UIImage* fractalImage = [self snapshot: self.fractalView size: CGSizeMake(1024.0, 1024.0) withWatermark: !self.appModel.allowPremium];
//        NSData* pngImage = UIImagePNGRepresentation(fractalImage);
//
//        // Format the current date and time
//        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//        [formatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
//        NSString *now = [formatter stringFromDate:[NSDate date]];
//
//        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
//        NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
//
//        // Exif metadata dictionary
//        // Includes date and time as well as image dimensions
//        NSDictionary *exifDictionary = @{(NSString *)kCGImagePropertyExifDateTimeOriginal:now,
//                                         (NSString *)kCGImagePropertyExifDateTimeDigitized:now,
//                                         (NSString *)kCGImagePropertyExifPixelXDimension:@(fractalImage.size.width),
//                                         (NSString *)kCGImagePropertyExifPixelYDimension:@(fractalImage.size.height),
//                                         (NSString *)kCGImagePropertyExifUserComment:self.fractalDocument.fractal.name,
//                                         (NSString *)kCGImagePropertyExifLensMake:@"FractalScape",
//                                         (NSString *)kCGImagePropertyExifLensModel:version};
//
//        // Tiff metadata dictionary
//        // Includes information about the application used to create the image
//        // "Make" is the name of the app, "Model" is the version of the app
//        NSMutableDictionary *tiffDictionary = [NSMutableDictionary dictionary];
//        [tiffDictionary setValue:now forKey:(NSString *)kCGImagePropertyTIFFDateTime];
//        [tiffDictionary setValue:@"FractalScape" forKey:(NSString *)kCGImagePropertyTIFFMake];
//        [tiffDictionary setValue:self.fractalDocument.fractal.name forKey:(NSString *)kCGImagePropertyTIFFDocumentName];
//        [tiffDictionary setValue:self.fractalDocument.fractal.descriptor forKey:(NSString *)kCGImagePropertyTIFFImageDescription];
//
//        [tiffDictionary setValue:[NSString stringWithFormat:@"%@ (%@)", version, build] forKey:(NSString *)kCGImagePropertyTIFFModel];
//
//        NSDictionary* pngDictionary = @{(NSString *)kCGImagePropertyPNGDescription:self.fractalDocument.fractal.descriptor,
//                                        (NSString *)kCGImagePropertyPNGTitle:self.fractalDocument.fractal.name,
//                                        (NSString *)kCGImagePropertyPNGSoftware:@"FractalScape",
//                                        (NSString *)kCGImagePropertyPNGAuthor:@"FractalScape"};
//
//        // Image metadata dictionary
//        // Includes image dimensions, as well as the EXIF and TIFF metadata
//        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//        [dict setValue:[NSNumber numberWithFloat:fractalImage.size.width] forKey:(NSString *)kCGImagePropertyPixelWidth];
//        [dict setValue:[NSNumber numberWithFloat:fractalImage.size.height] forKey:(NSString *)kCGImagePropertyPixelHeight];
//        [dict setValue:exifDictionary forKey:(NSString *)kCGImagePropertyExifDictionary];
//        [dict setValue:tiffDictionary forKey:(NSString *)kCGImagePropertyTIFFDictionary];
//        [dict setValue:pngDictionary forKey:(NSString *)kCGImagePropertyPNGDictionary];
//
//
//        [library writeImageDataToSavedPhotosAlbum: pngImage metadata: dict completionBlock:^(NSURL *assetURL, NSError *error){
//            // call method for UIAlert about successful save with save text
//            [self showSharedCompletionAlertWithText: @"your camera roll." error: error];
//
////            NSLog(@"Sharing to camera status %@.", error);
//        }];
//
//        //        [library writeImageToSavedPhotosAlbum: [fractalImage CGImage] orientation: ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error){
//        //            // call method for UIAlert about successful save with save text
//        //            [self showSharedCompletionAlertWithText: @"your camera roll." error: error];
//        //
//        //            NSLog(@"Sharing to camera status %@.", error);
//        //        }];
//    }
//
////    NSLog(@"Sharing to camera called.");
//}

-(void) showSharedCompletionAlertWithText: (NSString*) alertText error: (NSError*) error
{
    
    NSString* successText;
    
    if (error==nil)
    {
        successText = [NSString stringWithFormat: @"Your fractal was shared to %@.", alertText];
    } else
    {
        successText = [NSString stringWithFormat: @"There was a problem sharing your fractal. \nError: %@", error];
    }
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Share Status",nil)
                                                                   message: successText
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Ok",nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                    }];
    [alert addAction: defaultAction];
    
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - UIScrollViewDelegate
-(UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.fractalView.superview;
}
-(void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    // TODO: if view is smaller than scrollview, center view in scrollview.
}

#pragma mark - core data
-(void) setUndoManager:(NSUndoManager *)undoManager
{
    if (undoManager != _undoManager)
    {
        if (undoManager == nil)
        {
            [self cleanUpUndoManager];
        }
        _undoManager = undoManager;
    }
}

-(NSUndoManager*) undoManager
{
    if (_undoManager == nil)
    {
        [self setUpUndoManager];
    }
    return _undoManager;
}

- (void)setUpUndoManager
{
    //
    //    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    //    [dnc addObserver:self selector:@selector(undoManagerDidUndo:) name:NSUndoManagerDidUndoChangeNotification object:fractalUndoManager];
    //    [dnc addObserver:self selector:@selector(undoManagerDidRedo:) name:NSUndoManagerDidRedoChangeNotification object:fractalUndoManager];
}


- (void)cleanUpUndoManager
{
    
    // Remove self as an observer.
    //    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //
    //    if (self.fractalDocument.fractal.managedObjectContext.undoManager == _undoManager)
    //    {
    //        self.fractalDocument.fractal.managedObjectContext.undoManager = nil;
    //        _undoManager = nil;
    //    }
}


- (void)undoManagerDidUndo:(NSNotification *)notification
{
    [self updateInterface];
}


- (void)undoManagerDidRedo:(NSNotification *)notification
{
    [self updateInterface];
}

-(void)undoEdit:(id)sender
{
    
}

#pragma mark - Utilities

-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo
{
    if (LOGBOUNDS)
    {
        CFDictionaryRef boundsDict = CGRectCreateDictionaryRepresentation(bounds);
        NSString* boundsDescription = [(__bridge NSDictionary*)boundsDict description];
        CFRelease(boundsDict);
        
        NSLog(@"%@ = %@", boundsInfo,boundsDescription);
    }
}
-(void) logGroupingLevelFrom:  (NSString*) cmd
{
    if (/* DISABLES CODE */ (NO))
    {
        NSLog(@"%@: Undo group levels = %ld", cmd, (long)[self.undoManager groupingLevel]);
    }
}
-(NSNumberFormatter*) onePlaceFormatter
{
    if (_onePlaceFormatter == nil)
    {
        _onePlaceFormatter = [[NSNumberFormatter alloc] init];
        [_onePlaceFormatter setAllowsFloats: YES];
        [_onePlaceFormatter setMaximumFractionDigits: 1];
        [_onePlaceFormatter setMaximumIntegerDigits: 3];
        [_onePlaceFormatter setPositiveFormat: @"##0.0"];
        [_onePlaceFormatter setNegativeFormat: @"-##0.0"];
    }
    return _onePlaceFormatter;
}
-(NSNumberFormatter*) twoPlaceFormatter
{
    if (_twoPlaceFormatter == nil)
    {
        _twoPlaceFormatter = [[NSNumberFormatter alloc] init];
        [_twoPlaceFormatter setAllowsFloats: YES];
        [_twoPlaceFormatter setMaximumFractionDigits: 2];
        [_twoPlaceFormatter setMaximumIntegerDigits: 3];
        [_twoPlaceFormatter setPositiveFormat: @"##0.00"];
        [_twoPlaceFormatter setNegativeFormat: @"-##0.00"];
    }
    return _twoPlaceFormatter;
}
-(NSNumberFormatter*) percentFormatter
{
    if (_percentFormatter == nil)
    {
        _percentFormatter = [[NSNumberFormatter alloc] init];
        _percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
    }
    return _percentFormatter;
}
-(NSNumberFormatter*) angleFormatter
{
    if (_angleFormatter == nil)
    {
        _angleFormatter = [[NSNumberFormatter alloc] init];
        [_angleFormatter setPositiveFormat: @"##0.00°"];
        [_angleFormatter setNegativeFormat: @"-##0.00°"];
    }
    return _angleFormatter;
}
@end
