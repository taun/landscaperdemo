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

//
//static inline double radians (double degrees){return degrees * M_PI/180.0;}
//static inline double degrees (double radians){return radians * 180.0/M_PI;}
#define LOGBOUNDS 0
#define DEBUGRENDERTIME

static NSString* kLibrarySelectionKeypath = @"selectedFractal";
static const BOOL SIMULTOUCH = NO;
static const CGFloat kHighPerformanceFrameRate = 20.0;
static const CGFloat kLowPerformanceFrameRate = 8.0;
static const CGFloat kHudLevelStepperDefaultMax = 16.0;
static const CGFloat kLevelNMargin = 40.0;

@interface MBLSFractalEditViewController ()  <UIGestureRecognizerDelegate,
                                                    UIActionSheetDelegate,
                                                    UIPopoverPresentationControllerDelegate,
                                                    UIScrollViewDelegate,
                                                    UIDocumentInteractionControllerDelegate,
                                                    FractalControllerDelegate,
                                                    MDBFractalDocumentDelegate>

@property (nonatomic,strong) NSMutableSet           *observedReplacementRules;
@property (nonatomic,assign) BOOL                   startedInLandscape;
@property (nonatomic,assign) BOOL                   hasBeenEdited;

//@property (nonatomic, strong) NSSet*                editControls;
//@property (nonatomic, strong) NSMutableArray*       cachedEditViews;
//@property (nonatomic, assign) NSInteger             cachedEditorsHeight;

@property (nonatomic, assign) double                viewNRotationFromStart;

@property (nonatomic,strong) UIMotionEffectGroup    *foregroundMotionEffect;
@property (nonatomic,strong) UIMotionEffectGroup    *backgroundMotionEffect;
@property (nonatomic, strong) UIBarButtonItem*      cancelButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      undoButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      redoButtonItem;
#pragma message "TODO Add autoExpand as LSFractal model property."
@property (nonatomic, strong) NSArray*              disabledDuringPlaybackButtons;
@property (nonatomic, strong) NSArray*              editPassThroughViews;

@property (nonatomic,weak) UIViewController*        currentPresentedController;
@property (nonatomic,assign) BOOL                   previousNavBarState;

@property (nonatomic, strong) dispatch_queue_t      levelDataGenerationQueue;
@property (nonatomic,strong) NSArray                *levelDataArray;
/*!
 Fractal background image generation queue.
 */
@property (nonatomic,strong) NSOperationQueue              *privateImageGenerationQueue;
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
@property (readonly,strong) CIContext                      *filterContext;
@property (nonatomic,strong) NSDictionary                  *twoFingerPanProperties;

@property (nonatomic,strong) UIDocumentInteractionController *documentShareController;

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
//@synthesize fractal = _fractal;
@synthesize filterContext = _filterContext;

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
    
    /*
     FractalScape rendering is much faster on the 64bit devices.
     Coincidentally, the 64 bit devices all have the MotionProcessor which can store activity data.
     We use the isActivityAvailable call to set app performance parameters.
     */
    self.lowPerformanceDevice = ![CMMotionActivityManager isActivityAvailable];

    self.popTransition = [MDBZoomPopBounceTransition new];
    self.pushTransition = [MDBZoomPushBounceTransition new];
}

#pragma mark - UIViewController Methods
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}

-(void) configureParallax
{
    BOOL showParalax = self.appModel.showParallax;
    
    if (showParalax) {
        UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xAxis.minimumRelativeValue = @(9.0);
        xAxis.maximumRelativeValue = @(-9.0);
        
        UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yAxis.minimumRelativeValue = @(12.0);
        yAxis.maximumRelativeValue = @(-12.0);
        
        self.backgroundMotionEffect = [[UIMotionEffectGroup alloc] init];
        self.backgroundMotionEffect.motionEffects = @[xAxis, yAxis];
        

        UIInterpolatingMotionEffect *xFAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xFAxis.minimumRelativeValue = @(6.0);
        xFAxis.maximumRelativeValue = @(-6.0);
        
        UIInterpolatingMotionEffect *yFAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yFAxis.minimumRelativeValue = @(8.0);
        yFAxis.maximumRelativeValue = @(-8.0);
        
        self.foregroundMotionEffect = [[UIMotionEffectGroup alloc] init];
        self.foregroundMotionEffect.motionEffects = @[xFAxis, yFAxis];
        
        [self.fractalView addMotionEffect: self.backgroundMotionEffect];
        [self.fractalViewRoot addMotionEffect: self.foregroundMotionEffect];
    }
}

-(void) configureNavBarButtons
{
    
    self.stopButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem: UIBarButtonSystemItemStop
                                                                   target: self
                                                                   action: @selector(stopButtonPressed:)];
    
//    UIBarButtonItem* backButton = [[UIBarButtonItem alloc]initWithTitle: @"Library"
//                                                                  style: UIBarButtonItemStylePlain
//                                                                 target: self
//                                                                 action: @selector(backToLibrary:)];

    UIBarButtonItem* copyButton = [[UIBarButtonItem alloc]initWithImage: [UIImage imageNamed: @"toolBarCopyIcon"]
                                                                  style: UIBarButtonItemStylePlain
                                                                 target: self
                                                                 action: @selector(copyFractal:)];
    
    UIBarButtonItem* shareButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem: UIBarButtonSystemItemAction
                                                                 target: self
                                                                 action: @selector(shareButtonPressed:)];
    
    _disabledDuringPlaybackButtons = @[self.autoExpandOff, copyButton, shareButton];
    
    [self.navigationItem setHidesBackButton: YES animated: NO];
    self.navigationItem.leftItemsSupplementBackButton = YES;
//    self.navigationItem.backBarButtonItem = backButton;
    
    NSMutableArray* items = [self.navigationItem.leftBarButtonItems mutableCopy];
    if (!items) {
        items = [NSMutableArray new];
    }
//    [items addObject: backButton];
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace target:nil action:NULL];
    space.width = 20.0;
    [items addObject: space];
    [items addObject: copyButton];
    [self.navigationItem setLeftBarButtonItems: items];
    
    
    
    items = [self.navigationItem.rightBarButtonItems mutableCopy];
    [items addObject: space];
    [items addObject: shareButton];
    [self.navigationItem setRightBarButtonItems: items];
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
    if (!self.appModel.allowPremium)
    {
        [self.toggleFullScreenButton removeFromSuperview];
    }
    else
    {
        
    }
    
    _observedReplacementRules = [NSMutableSet new];
    
    [self configureParallax];
    [self configureNavBarButtons];
    [self moveTwoFingerPanToJointAngle: nil]; //default
    
    // hide navBar on load because the Appearance Popover is auto popped on load
    // and if this is done during the appearance code, the view moves up as the navBar is hidden
    self.previousNavBarState = NO;
//    self.navigationController.navigationBar.hidden = YES;
    [self.navigationController setNavigationBarHidden: YES animated: YES];
    
    self.showPerformanceData = self.appModel.showPerformanceData;

    BOOL fullScreenState = self.appModel.fullScreenState;
    if (fullScreenState)
    {
        [self fullScreenOnDuration: 0.0];
    }

    [self.fractalViewRootSingleTapRecognizer requireGestureRecognizerToFail: self.fractalViewRootDoubleTapRecognizer];
    
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
    
    [super viewDidLoad];
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
    
    
    self.navigationItem.title = self.fractalDocument.fractal.name;
    [self setupSlidersForCurrentFractal];
    [self.appModel setLastEditedURL: self.fractalInfo.URL];
}

/* on staartup, fractal should not be set until just before view didAppear */
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateAndShowEditor];
    
    UIEdgeInsets scrollInsets = UIEdgeInsetsMake(300.0, 300.0, 300.0, 300.0);

    if (!UIEdgeInsetsEqualToEdgeInsets(self.fractalScrollView.contentInset , scrollInsets))
    {
//        self.fractalScrollView.bounds = CGRectInset(self.fractalScrollView.bounds, -300.0, -300.0);
        self.fractalScrollView.contentInset = scrollInsets;
        self.fractalScrollView.contentOffset = CGPointZero;
    }
}

-(void) updateAndShowEditor
{
    if (self.fractalInfo.document != nil && self.fractalInfo.document.fractal && self.isViewLoaded && self.view.superview)
    {
        [self regenerateLevels];
        [self updateInterface];
        [self autoScale: nil];
        
        [self performSegueWithIdentifier: @"EditSegue" sender: self];
    }
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (_fractalInfo) {
        [self setFractalInfo: nil];
    }
}


-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        [self queueFractalImageUpdates];
        [self updateViewController: self.currentPresentedController popoverPreferredContentSizeForViewSize: size];
        //        self.fractalView.position = fractalNewPosition;
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
    }];
    //    subLayer.position = self.fractalView.center;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    // Return YES for supported orientations
    return YES;
}

/* observer fractal.replacementRules */
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
//    NSInteger changeCount = 0;
#pragma message "TODO: fix for uidocument"
//    if ([object isKindOfClass:[NSManagedObject class]])
//    {
//        NSDictionary* changes = [object changedValuesForCurrentEvent];
//        changeCount = changes.count;
//    }
//    [self.fractalDocument updateChangeCount: UIDocumentChangeDone];

//    NSLog(@"Observed Change Type: %@", change[NSKeyValueChangeKindKey]);
    BOOL changeCount = ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeSetting
                        || [change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeInsertion
                        || [change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeRemoval
                        || [change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeReplacement);
    
//    if ([keyPath isEqualToString: @"fractal"])
//    {
//        // the document fractal changed
//        id oldFractalObject = change[NSKeyValueChangeOldKey];
//        if (oldFractalObject != [NSNull null])
//        {
//            [self removeObserversForFractal: oldFractalObject];
//        }
//        [self addObserversForFractal: self.fractalDocument.fractal];
//        [self regenerateLevels];
//        [self updateInterface];
//    }
//    else
    if ([[LSFractal redrawProperties] containsObject: keyPath])
    {
        if (changeCount)
        {
            self.hasBeenEdited = YES;
            [self queueFractalImageUpdates];
            [self updateInterface];
        }
    }
    else if ([[LSFractal appearanceProperties] containsObject: keyPath] ||
             [keyPath isEqualToString: @"lineColors.allObjects"] ||
             [keyPath isEqualToString: @"fillColors.allObjects"])
    {
        if (changeCount)
        {
            self.hasBeenEdited = YES;
            [self queueFractalImageUpdates];
            [self updateInterface];
        }
    }
    else if ([[LSFractal productionRuleProperties] containsObject: keyPath] ||
             [keyPath isEqualToString: @"startingRules.allObjects"] ||
             [keyPath isEqualToString: @"rules.allObjects"] ||
             [keyPath isEqualToString: [LSReplacementRule contextRuleKey]])
    {
        if (changeCount)
        {
#pragma message "TODO: fix for uidocument"
            self.fractalDocument.fractal.rulesUnchanged = NO;
            self.hasBeenEdited = YES;
            
            if ([keyPath isEqualToString:[LSFractal replacementRulesKey]])
            {
                [self updateObserversForReplacementRules: self.fractalDocument.fractal.replacementRules];
            }
            
            [self regenerateLevels];
            [self updateInterface];
        }
    }
    else if ([keyPath isEqualToString: @"name"])
    {
        self.hasBeenEdited = YES;
        [self updateNavButtons];
    }
    else if ([keyPath isEqualToString: @"category"])
    {
        self.hasBeenEdited = YES;
    }
    else if ([keyPath isEqualToString: @"descriptor"])
    {
        self.hasBeenEdited = YES;
    }
    else if ([keyPath isEqualToString: @"imageFilters.allObjects"])
    {
        self.hasBeenEdited = YES;
        [self.fractalDocument.fractal updateApplyFiltersWithoutNotificationForFiltersListChange];
        [self queueFractalImageUpdates];
        [self updateInterface];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    [self updateUndoRedoBarButtonState];
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
    UIDocumentState state = self.fractalDocument.documentState;
    
    if (state == UIDocumentStateNormal)
    {
        [self addObserversForCurrentFractal];
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
        [self removeObserversForCurrentFractal];
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
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Editing Conflict!"
                                                                   message: versionConflictMessage
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    
    UIAlertAction* pushOverwriteAction = [UIAlertAction actionWithTitle:@"Keep this device edits" style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action)
                                           {
                                               [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                               // Any automatic merging logic or presentation of conflict resolution UI should go here.
                                               // For this sample, just pick the current version and mark the conflict versions as resolved.
                                               [NSFileVersion removeOtherVersionsOfItemAtURL: self.fractalDocument.fileURL error:nil];
                                               
                                               NSArray *conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL: self.fractalDocument.fileURL];
                                               for (NSFileVersion *fileVersion in conflictVersions) {
                                                   fileVersion.resolved = YES;
                                               }
                                           }];
    [alert addAction: pushOverwriteAction];

    UIAlertAction* makeCopyAction = [UIAlertAction actionWithTitle:@"Make a new copy of this fractal" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                        [self copyFractal: nil];
                                    }];
    [alert addAction: makeCopyAction];

    [self presentViewController: alert animated: YES completion: nil];
}

#pragma mark - Getters & Setters

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

#pragma mark Fractal Property KVO
-(void)setFractalInfo:(MDBFractalInfo *)fractalInfo {
    
    if (_fractalInfo != fractalInfo) {
        
        if (_fractalInfo) {
            [self removeObserversForCurrentDocument];
        }
        
        _fractalInfo = fractalInfo;
        
        id<MDBTileObjectProtocol> tileObject = [_fractalInfo.document.fractal.startingRules firstObject];
        
        if (_fractalInfo.document.fractal && tileObject.isDefaultObject)
        {
            //default rules and settings
            LSFractal* newFractal = _fractalInfo.document.fractal;
            
            LSDrawingRuleType* rules = _fractalInfo.document.sourceDrawingRules;
            
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
        
        [self addObserverForFractalChangeInCurrentDocument];
    }
}

-(void) setFractalInfo: (MDBFractalInfo*)fractalInfo andShowEditor: (BOOL)update
{
    UIDocumentState docState = fractalInfo.document.documentState;
    
    if (docState != UIDocumentStateNormal)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            //
            [fractalInfo.document openWithCompletionHandler:^(BOOL success) {
                //detect if we have a new default fractal
                self.fractalInfo = fractalInfo;
                if (update) [self updateAndShowEditor];
            }];
        });
    }
    else
    {
        self.fractalInfo = fractalInfo;
        if (update) [self updateAndShowEditor];
    }
}

-(MDBFractalDocument*)fractalDocument
{
    return _fractalInfo.document;
}

#pragma message "TODO Use an alert here rather than just deleting. Should only happen if deleted on another device."
-(void)fractalDocumentWasDeleted: (MDBFractalDocument*)deletedDocument
{
    if (self.fractalInfo.document == deletedDocument) {
        self.fractalInfo = nil;
        [self popBackToLibrary: nil];
    }
}

-(LSFractalRenderer*) fractalRendererL0
{
    if (!_fractalRendererL0)
    {
        if (self.fractalDocument.fractal)
        {
            _fractalRendererL0 = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.fractalDocument.sourceDrawingRules];
            _fractalRendererL0.name = @"_fractalRendererL0";
            _fractalRendererL0.imageView = self.fractalViewLevel0;
            _fractalRendererL0.pixelScale = self.fractalViewLevel0.contentScaleFactor;
            _fractalRendererL0.flipY = YES;
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
            _fractalRendererL1 = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.fractalDocument.sourceDrawingRules];
            _fractalRendererL1.name = @"_fractalRendererL1";
            _fractalRendererL1.imageView = self.fractalViewLevel1;
            _fractalRendererL1.pixelScale = self.fractalViewLevel1.contentScaleFactor;
            _fractalRendererL1.flipY = YES;
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
            _fractalRendererL2 = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.fractalDocument.sourceDrawingRules];
            _fractalRendererL2.name = @"_fractalRendererL2";
            _fractalRendererL2.imageView = self.fractalViewLevel2;
            _fractalRendererL2.pixelScale = self.fractalViewLevel2.contentScaleFactor;
            _fractalRendererL2.flipY = YES;
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
            UIImageView* strongView = self.fractalView;
            _fractalRendererLN = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.fractalDocument.sourceDrawingRules];
            _fractalRendererLN.name = @"_fractalRendererLNS1";
            _fractalRendererLN.imageView = strongView;
            _fractalRendererLN.pixelScale = strongView.contentScaleFactor;
            _fractalRendererLN.flipY = YES;
            _fractalRendererLN.margin = kLevelNMargin;
            _fractalRendererLN.showOrigin = YES;
            _fractalRendererLN.autoscale = YES;
        }
    }
    return _fractalRendererLN;
}

-(void) addObserverForFractalChangeInCurrentDocument
{
    if (_fractalInfo.document) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentStateChangedNotification:) name:UIDocumentStateChangedNotification object: _fractalInfo.document];
//        [_fractalInfo.document addObserver: self forKeyPath: @"fractal" options: NSKeyValueObservingOptionOld context: NULL];
        _fractalInfo.document.delegate = self;
        if (_fractalInfo.document.fractal) {
            [self addObserversForCurrentFractal];
        }
    }
}

-(void) removeObserversForCurrentDocument
{
    if (_fractalInfo.document) {
        
        [[NSNotificationCenter defaultCenter] removeObserver: self name: UIDocumentStateChangedNotification object: _fractalInfo.document];

        if (_fractalInfo.document && _fractalInfo.document.fractal) {
            [self removeObserversForCurrentFractal];
        }

        [self updateLibraryRepresentationIfNeeded];
        
        [_privateImageGenerationQueue cancelAllOperations];
        
        _fractalInfo.document.delegate = nil;

        [_fractalInfo.document closeWithCompletionHandler:nil];
    }
}

-(void) updateLibraryRepresentationIfNeeded
{
    if (self.hasBeenEdited)
    {
        UIImage* fractalImage = [self snapshot: self.fractalView size: CGSizeMake(130.0, 130.0) withWatermark: NO];
        
        [_fractalInfo.document setThumbnail: fractalImage];
        _fractalInfo.changeDate = [NSDate date];
        
        [_fractalInfo.document updateChangeCount: UIDocumentChangeDone];
        
//        [self.appModel.documentController setFractalInfoHasNewContents: _fractalInfo];
        self.hasBeenEdited = NO;
    }
}

-(void) addObserversForCurrentFractal
{
    LSFractal* fractal = _fractalInfo.document.fractal;
    if (fractal)
    {
        [self.appModel setLastEditedURL: _fractalInfo.URL];
        
        [self setupSlidersForCurrentFractal];
        
        _lastImageUpdateTime = [NSDate date];

        NSMutableSet* propertiesToObserve = [NSMutableSet setWithSet: [LSFractal productionRuleProperties]];
        [propertiesToObserve unionSet: [LSFractal appearanceProperties]];
        [propertiesToObserve unionSet: [LSFractal redrawProperties]];
        [propertiesToObserve unionSet: [LSFractal labelProperties]];
        [propertiesToObserve addObject: @"startingRules.allObjects"];
        [propertiesToObserve addObject: @"lineColors.allObjects"];
        [propertiesToObserve addObject: @"fillColors.allObjects"];
        [propertiesToObserve addObject: @"imageFilters.allObjects"];
        
        for (NSString* keyPath in propertiesToObserve)
        {
            [fractal addObserver: self forKeyPath:keyPath options: 0 context: NULL];
        }
        for (LSReplacementRule* rRule in fractal.replacementRules)
        {
            [rRule addObserver: self forKeyPath: [LSReplacementRule contextRuleKey] options: 0 context: NULL];
            [rRule addObserver: self forKeyPath: @"rules.allObjects" options: 0 context: NULL];
            [self.observedReplacementRules addObject: rRule];
        }
    }
}

-(void) updateObserversForReplacementRules: (NSMutableArray*) newReplacementRules {
    // need to find rules missing from registered observers.
    
    NSMutableSet* copyOfCurrent = [NSMutableSet setWithArray: newReplacementRules];
    NSMutableSet* copyOfPrevious = [self.observedReplacementRules mutableCopy];
    
    NSMutableSet* repRulesToUnobserve = [copyOfPrevious mutableCopy];
    [repRulesToUnobserve minusSet: copyOfCurrent];
    
    
    for (LSReplacementRule* rule in repRulesToUnobserve)
    {
        [rule removeObserver: self forKeyPath: [LSReplacementRule contextRuleKey]];
        [rule removeObserver: self forKeyPath: @"rules.allObjects"];
        [self.observedReplacementRules removeObject: rule];
    }
    
    NSMutableSet* repRulesToAddObserver = [copyOfCurrent mutableCopy];
    [repRulesToAddObserver minusSet: self.observedReplacementRules];
    
    for (LSReplacementRule* rRule in repRulesToAddObserver)
    {
        [rRule addObserver: self forKeyPath: [LSReplacementRule contextRuleKey] options: 0 context: NULL];
        [rRule addObserver: self forKeyPath: @"rules.allObjects" options: 0 context: NULL];
        [self.observedReplacementRules addObject: rRule];
    }
}

-(void) removeObserversForCurrentFractal
{
    LSFractal* fractal = _fractalInfo.document.fractal;
    if (fractal)
    {
        NSMutableSet* propertiesToObserve = [NSMutableSet setWithSet: [LSFractal productionRuleProperties]];
        [propertiesToObserve unionSet: [LSFractal appearanceProperties]];
        [propertiesToObserve unionSet: [LSFractal redrawProperties]];
        [propertiesToObserve unionSet: [LSFractal labelProperties]];
        [propertiesToObserve addObject: @"startingRules.allObjects"];
        [propertiesToObserve addObject: @"lineColors.allObjects"];
        [propertiesToObserve addObject: @"fillColors.allObjects"];
        [propertiesToObserve addObject: @"imageFilters.allObjects"];
        
        @try {
            // Some properties may not being observed due to being nil initially?
            for (NSString* keyPath in propertiesToObserve)
            {
                [fractal removeObserver: self forKeyPath: keyPath];
            }
            for (LSReplacementRule* rule in fractal.replacementRules)
            {
                [rule removeObserver: self forKeyPath: [LSReplacementRule contextRuleKey]];
                [rule removeObserver: self forKeyPath: @"rules.allObjects"];
                [self.observedReplacementRules removeObject: rule];
            }
        }
        @catch (NSException *exception) {
            //
            NSLog(@"%@: KVO Error removing observers exception: %@",NSStringFromSelector(_cmd), exception);
        }
        @finally {
            //
        }
    }
}


-(void) setLowPerformanceDevice:(BOOL)lowPerformanceDevice {
    _lowPerformanceDevice = lowPerformanceDevice;
    
    if (_lowPerformanceDevice)
    {
        self.minImagePersistence = 1.0 / kLowPerformanceFrameRate;
    }
    else
    {
        self.minImagePersistence = 1.0 / kHighPerformanceFrameRate;
    }
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

-(CIContext*) filterContext
{
    if (!_filterContext) {
        _filterContext = [CIContext contextWithOptions: nil];
    }
    return _filterContext;
}

#pragma mark - view utility methods

-(void) updateInterface
{
    [self stopButtonPressed: nil];
    [self updateValueInputs];
    [self updateLabelsAndControls];
    [self updateNavButtons];
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
    
    self.baseAngleLabel.text = [self.twoPlaceFormatter stringFromNumber: [NSNumber numberWithDouble: degrees(self.fractalDocument.fractal.baseAngle)]];
    self.baseAngleSlider.value = degrees(self.fractalDocument.fractal.baseAngle);
    
    self.hudRandomnessLabel.text = [self.percentFormatter stringFromNumber: @(self.fractalDocument.fractal.randomness)];
    self.randomnessVerticalSlider.value = self.fractalDocument.fractal.randomness;
    
    self.hudLineAspectLabel.text = [NSString stringWithFormat: @"%@px by 10px long",[self.twoPlaceFormatter stringFromNumber: @(self.fractalDocument.fractal.lineWidth)]];
    self.lineWidthVerticalSlider.value = self.fractalDocument.fractal.lineWidth;
    
    self.turningAngleLabel.text = [self.twoPlaceFormatter stringFromNumber: @(degrees(self.fractalDocument.fractal.turningAngle))];
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
    
    dispatch_async(self.levelDataGenerationQueue, ^{
        //
        [strongFractal generateLevelData];
        NSArray* levelDataArray = @[strongFractal.level0RulesCache, strongFractal.level1RulesCache, strongFractal.level2RulesCache, strongFractal.levelNRulesCache, @(strongFractal.levelGrowthRate)];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateRendererLevels: levelDataArray];
        });
    });
    
    
//    NSManagedObjectID* fid;// = self.fractalID;
//    
//    [pc performBlock:^{
//        [pc reset];
//        LSFractal* fractal = (LSFractal*)[pc objectWithID: fid];
//        [fractal generateLevelData];
//        
//        NSArray* levelDataArray = @[fractal.level0RulesCache, fractal.level1RulesCache, fractal.level2RulesCache, fractal.levelNRulesCache, fractal.levelGrowthRate];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self updateRendererLevels: levelDataArray];
//        });
//    }];
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
        self.fractalRendererL0.levelData = self.levelDataArray[0];
        self.fractalRendererL1.levelData = self.levelDataArray[1];
        self.fractalRendererL2.levelData = self.levelDataArray[2];
        self.fractalRendererLN.levelData = self.levelDataArray[[self levelNIndex]];
        [self queueFractalImageUpdates];
        
        NSInteger nodeLimit = self.lowPerformanceDevice ? kLSMaxNodesLoPerf: kLSMaxNodesHiPerf;
        
        CGFloat currentNodeCount = (CGFloat)[(NSData*)self.levelDataArray[3] length];
        CGFloat estimatedNextNode = currentNodeCount * [self.levelDataArray[4] floatValue];
//        NSLog(@"growth rate %f",[self.fractalDocument.fractal.levelGrowthRate floatValue]);
        UIStepper* strongLevelStepper = self.hudLevelStepper;
        if (estimatedNextNode > nodeLimit)
        {
            strongLevelStepper.maximumValue = strongLevelStepper.value;
        } else if (strongLevelStepper.maximumValue == strongLevelStepper.value)
        {
            strongLevelStepper.maximumValue = strongLevelStepper.value + 1;
        }
    }
}
-(void) queueFractalImageUpdates
{
    if (!self.fractalDocument.fractal.isRenderable) {
        return;
    }
    
    if (self.fractalRendererLN.operation && !self.fractalRendererLN.operation.isFinished)
    {
        NSDate* now = [NSDate date];
        NSTimeInterval lastUpdated = [now timeIntervalSinceDate: self.lastImageUpdateTime];
        if (lastUpdated < self.minImagePersistence) {
            return;
        }
        
        [self.fractalRendererLN.operation cancel];
    }
    
    [self.privateImageGenerationQueue waitUntilAllOperationsAreFinished];
    
    [self queueHudImageUpdates];
    
    self.fractalRendererLN.autoscale = self.autoscaleN;
    self.fractalRendererLN.autoExpand = self.fractalDocument.fractal.autoExpand;
    self.fractalRendererLN.applyFilters = self.fractalDocument.fractal.applyFilters;
    self.fractalRendererLN.showOrigin = !self.fractalDocument.fractal.applyFilters;
    
#pragma message "TODO define a property for the default fractal background color. Currently manually spread throughout code."
    UIColor* backgroundColor = [self.fractalDocument.fractal.backgroundColor asUIColor];
    if (!backgroundColor) backgroundColor = [UIColor clearColor];
    self.fractalRendererLN.backgroundColor = backgroundColor;
    
    if (!self.lowPerformanceDevice || self.fractalRendererLN.levelData.length < 150000)
    {
        self.fractalRendererLN.pixelScale = self.fractalViewHolder.contentScaleFactor * 2.0;
    }
    else
    {
        self.fractalRendererLN.pixelScale = self.fractalViewHolder.contentScaleFactor;
    }
    NSBlockOperation* operationNN1 = [self operationForRenderer: self.fractalRendererLN];
    
    
    [self.privateImageGenerationQueue addOperation: operationNN1];
    self.lastImageUpdateTime = [NSDate date];
}
-(void) queueHudImageUpdates
{
    if (!self.fractalViewLevel0.superview.hidden)
    {
        NSBlockOperation* operation0 = [self operationForRenderer: self.fractalRendererL0];
        self.fractalRendererL0.backgroundColor = [UIColor clearColor];
        self.fractalRendererL0.applyFilters = NO;
        [self.privateImageGenerationQueue addOperation: operation0];
    }
    
    if (!self.fractalViewLevel1.superview.hidden)
    {
        NSBlockOperation* operation1 = [self operationForRenderer: self.fractalRendererL1];
        self.fractalRendererL1.backgroundColor = [UIColor clearColor];
        self.fractalRendererL1.applyFilters = NO;
        [self.privateImageGenerationQueue addOperation: operation1];
    }
    
    if (!self.fractalViewLevel2.superview.hidden)
    {
        NSBlockOperation* operation2 = [self operationForRenderer: self.fractalRendererL2];
        self.fractalRendererL2.backgroundColor = [UIColor clearColor];
        self.fractalRendererL2.applyFilters = NO;
        [self.privateImageGenerationQueue addOperation: operation2];
    }
}
-(NSBlockOperation*) operationForRenderer: (LSFractalRenderer*)renderer
{
    
    [renderer setValuesForFractal: self.fractalDocument.fractal];
    
    NSBlockOperation* operation = [NSBlockOperation new];
    renderer.operation = operation;
    
    [operation addExecutionBlock: ^{
        //code
        if (!renderer.operation.isCancelled)
        {
            [renderer generateImage];
            if (renderer.imageView && renderer.image)
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    BOOL applyFilters = YES;
                    
                    if (renderer.applyFilters)
                    {
                        renderer.imageView.image = [self applyFiltersToImage: renderer.image];
                    }
                    else
                    {
                        renderer.imageView.image = renderer.image;
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

//TODO: add Undo and Redo buttons for editing
- (void) updateNavButtons
{
    self.title = self.fractalDocument.fractal.name;
    UILabel* title = [[UILabel alloc]initWithFrame: CGRectZero];
    title.lineBreakMode = NSLineBreakByTruncatingMiddle;
    title.adjustsFontSizeToFitWidth = YES;
    title.minimumScaleFactor = 0.6;
    title.text = self.fractalDocument.fractal.name;
    [title sizeToFit];
    self.navigationItem.titleView = title;
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
/*!
 It took awhile to understand the undo mechanism but I think I finally have it.
 
 Undo undoes everything in the top level closed undo group.
 
 To have the ability to undo lists of operations, they need to be nested and undoNested needs to be used.
 
 undoNested adds the operation to the redo stack whereas undo puts what was undone on the undo stack so undoing again just redoes what was undone like a toggle.
 
 In this context, we want undo to perform undoNested and undo individual edit operations.
 
 Cancel will undo all changes since the edit session started by using core data rollback.
 */
// TODO: change all undos to [managedObjectContext undo] rather than undoManager
// need to make sure MOC undoManager exist like in setupUndoManager
// Don't need self.undoManager just model undoManager
- (IBAction)undoEdit:(id)sender
{
    [self logGroupingLevelFrom: NSStringFromSelector(_cmd)];
    if ([self.undoManager groupingLevel] > 0)
    {
        [self.undoManager endUndoGrouping];
        [self.undoManager undoNestedGroup];
    }
    //[self.undoManager disableUndoRegistration];
    //[self.undoManager undo];
    //[self.undoManager enableUndoRegistration];
    [self logGroupingLevelFrom: NSStringFromSelector(_cmd)];
}
- (IBAction)redoEdit:(id)sender
{
//    [self.fractalDocument.fractal.managedObjectContext redo];
}

/*
 since we are using core data, all we need to do to undo all changes and cancel the edit session is not save the core data and use rollback.
 */

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
    CGFloat verticalMargins = 80.0;
    
    
    
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
                                                          constant: -80.0]];
}

#pragma mark - Segues

/* close any existing popover before opening a new one.
 do not open a new one if the new popover is the same as the current */
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    BOOL should = YES;
    if ([identifier isEqualToString:@"EditSegue"] && [self.currentPresentedController isKindOfClass:[MBFractalAppearanceEditorViewController class]]) {
        should = NO;
        [self.currentPresentedController dismissViewControllerAnimated: YES completion:^{
            //
            [self appearanceControllerWasDismissed];
        }];
    } else if ([identifier isEqualToString:@"LibrarySegue"] && [self.currentPresentedController isKindOfClass:[MBFractalLibraryViewController class]]) {
        should = NO;
        [self.currentPresentedController dismissViewControllerAnimated: YES completion:^{
            //
            [self libraryControllerWasDismissed];
        }];
    }
    return should;
}
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self stopButtonPressed: nil];
    
    UIViewController<FractalControllerProtocol>* newController;
    
    if ([segue.identifier isEqualToString: @"EditSegue"])
    {
        newController = (UIViewController<FractalControllerProtocol>*)segue.destinationViewController;
        [self appearanceControllerIsPresenting: newController];
    }
}

- (IBAction)popBackToLibrary:(id)sender
{
    if (self.presentedViewController) {
        // dismiss any current popped or modal views
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }
    
    [self.navigationController popViewControllerAnimated: YES];
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
        
        UITraitCollection* traits = self.traitCollection;
        
        if (traits.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            CGFloat height;
            CGFloat width;
            
            if (isPortrait)
            {
                height = size.height / 2.0;
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
            popSize = isPortrait ? CGSizeMake(728.0,350.0) : CGSizeMake(400.0,650.0);
        }
        else
        {
            popSize = isPortrait ? CGSizeMake(728.0,350.0) : CGSizeMake(400.0,650.0);
        }
        
        viewController.preferredContentSize = popSize;
    }
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
//        self.navigationController.navigationBar.hidden = YES;
        [self.navigationController setNavigationBarHidden: YES animated: YES];
    }
    
    //    self.fractalScrollView.contentOffset = CGPointZero;
    self.fractalViewRootSingleTapRecognizer.enabled = NO;
    [self.view setNeedsLayout];
}
-(void) appearanceControllerWasDismissed
{
//    self.navigationController.navigationBar.hidden = self.previousNavBarState;
    [self.navigationController setNavigationBarHidden: self.previousNavBarState animated: YES];
    self.fractalViewRootSingleTapRecognizer.enabled = YES;
    self.currentPresentedController = nil;
    [self.view setNeedsLayout];
    [self updateLibraryRepresentationIfNeeded];
}

#pragma mark - Control Actions
/*!
 Obsoleted by UIActivityViewController code below.
 
 @param sender share button
 */
- (IBAction)shareButtonPressed:(id)sender
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }
    
    //    [self.shareActionsSheet showFromBarButtonItem: sender animated: YES];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Share"
                                                                   message: @"How would you like to share the image?"
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    
    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    
    if (cameraAuthStatus == ALAuthorizationStatusNotDetermined || cameraAuthStatus == ALAuthorizationStatusAuthorized)
    {
        UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:@"Export as Image" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
                                       {
                                           [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                           [self shareWithActivityController: sender];
                                       }];
        [alert addAction: cameraAction];
    }
    
    if (self.appModel.allowPremium) {
        UIAlertAction* vectorPDF = [UIAlertAction actionWithTitle:@"Export as Vector PDF" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                        [self sharePDFWithDocumentInteractionController: sender];
                                    }];
        [alert addAction: vectorPDF];
    }
    if (self.appModel.allowPremium) {
        UIAlertAction* documentShare = [UIAlertAction actionWithTitle:@"Export as Document" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                        [self shareWithDocumentInteractionController: sender];
                                    }];
        [alert addAction: documentShare];
    }
//    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Public Cloud" style:UIAlertActionStyleDefault
//                                                         handler:^(UIAlertAction * action)
//                                   {
//                                       [weakAlert dismissViewControllerAnimated:YES completion:nil];
//                                       [self shareFractalToPublicCloud];
//                                   }];
//    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                    }];
    [alert addAction: defaultAction];
    
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}
/*!
 See AirDropSample code for more UIActivityViewController  details.
 
 @param sender share button
 */
- (IBAction)shareButtonPressedObs:(id)sender
{
    [self sharePDFWithDocumentInteractionController: sender];
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

    UIImage* fractalImage = [self snapshot: self.fractalView size: CGSizeMake(1024.0, 1024.0) withWatermark: self.appModel.useWatermark];
    
    NSData* pngImage = UIImagePNGRepresentation(fractalImage);
    
    [exportItems addObject: pngImage];
    
    UIActivityViewController *activityViewController;
    
    if (self.appModel.allowPremium) {
        //        NSData* pdfData = [self createPDF];
        //        NSURL* fileUrl = [self savePDFData: pdfData];
        
        //        [exportItems addObject: pdfData];
    }
    
    activityViewController = [[UIActivityViewController alloc] initWithActivityItems: exportItems applicationActivities:nil];

    
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

-(NSBlockOperation*) operationForRenderer: (LSFractalRenderer*)renderer percent: (CGFloat)percent
{
    
    NSBlockOperation* operation = [NSBlockOperation new];
    renderer.operation = operation;
    
    [operation addExecutionBlock: ^{
        //code
        if (!renderer.operation.isCancelled)
        {
            [renderer generateImagePercent: percent];
            if (renderer.imageView && renderer.image)
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    renderer.imageView.image = renderer.image;
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
        NSInteger levelIndex = MIN(3, self.fractalDocument.fractal.level);
        newRenderer = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.fractalDocument.sourceDrawingRules];
        newRenderer.name = name;
        newRenderer.imageView = self.fractalView;
        newRenderer.pixelScale = self.fractalView.contentScaleFactor;
        newRenderer.flipY = YES;
        newRenderer.margin = kLevelNMargin;
        newRenderer.showOrigin = YES;
        newRenderer.autoscale = YES;
        newRenderer.autoExpand = self.fractalDocument.fractal.autoExpand;
        newRenderer.levelData = self.levelDataArray[levelIndex];
        UIColor* backgroundColor = [self.fractalDocument.fractal.backgroundColor asUIColor];
        if (!backgroundColor) backgroundColor = [UIColor clearColor];
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
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }
    
    if (!self.fractalDocument.fractal) {
        return;
    }
    
    [self.playbackTimer invalidate];
    for (UIBarButtonItem* button in self.disabledDuringPlaybackButtons)
    {
        button.enabled = NO;
    }

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
}

-(void) playNextFrame: (NSTimer*)timer
{
    NSMutableSet* finishedRenderers = [NSMutableSet new];
    /*!
     TODO: add a dependency here so operations don't finish out of order?
     */
    for (LSFractalRenderer*renderer in self.playbackRenderers) {
        if (renderer.operation == nil || renderer.operation.isFinished) {
            [finishedRenderers addObject: renderer];
        }
    }
    
    if (finishedRenderers.count > 0)
    {
        // queue up the next operation
        LSFractalRenderer* availableRender = [finishedRenderers anyObject];
        
        self.playIsPercentCompleted += self.playFrameIncrement;
        
        self.playbackSlider.value = self.playIsPercentCompleted;
        
        NSBlockOperation* operation = [self operationForRenderer: availableRender percent: self.playIsPercentCompleted];
        
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
    for (UIBarButtonItem* button in self.disabledDuringPlaybackButtons)
    {
        button.enabled = YES;
    }

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
}
-(IBAction) playSliderChangedValue: (UISlider*)slider
{
    self.playIsPercentCompleted = slider.value;
    [self playNextFrame: nil];
}
-(IBAction)toggleAutoExpandFractal:(id)sender
{
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
    LSFractal* newFractal = [self.fractalDocument.fractal copy];
    
    self.fractalInfo = nil;
    
    MDBFractalInfo* fractalInfo = [self.appModel.documentController createFractalInfoForFractal: newFractal withDocumentDelegate: self];
    
    [self setFractalInfo: fractalInfo andShowEditor: YES];
    self.hasBeenEdited = YES;
    
//    [self performSegueWithIdentifier: @"EditSegue" sender: self];
}

- (IBAction)levelInputChanged:(UIStepper*)sender
{
    double rawValue = sender.value;
    CGFloat roundedNumber = (CGFloat)lround(rawValue);
    self.fractalDocument.fractal.levelUnchanged = NO;
    self.fractalDocument.fractal.level = roundedNumber;
//    [self.activityIndicator startAnimating];
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
//-(void)changeAndApplyFilters
//{
//    MDBFractalObjectList* filters = self.fractalDocument.fractal.imageFilters;
//
//    if (!filters.isEmpty && !self.fractalDocument.fractal.applyFilters)
//    {
//        // if there are filters and the applyFilters was off, turn it on.
//        [self toggleApplyFilter: nil];
//    }
//    else if (filters.isEmpty && self.fractalDocument.fractal.applyFilters)
//    {
//        // filters are now empty and apply filters was on, turn it off
//        [self toggleApplyFilter: nil];
//    }
//    
//    UIImage* filteredUIImage = [self applyFiltersToImage: self.fractalRendererLN.image];
//    
//    if (filteredUIImage)
//    {
//        self.fractalView.image = filteredUIImage;
//    }
//}
//
-(UIImage*)applyFiltersToImage: (UIImage*)inputImage
{
    UIImage* filteredUIImage = inputImage;
    
    MDBFractalObjectList* filters = self.fractalDocument.fractal.imageFilters;
    
    if (filters && !filters.isEmpty) {
        [self.activityIndicator startAnimating];
        CGFloat scale = inputImage.scale;
        CGFloat imageWidth = scale*inputImage.size.width;
        CGFloat imageHeight = scale*inputImage.size.height;
        CGRect imageBounds = CGRectMake(0.0, 0.0, imageWidth, imageHeight);
        //    CGFloat midX = imageWidth/2.0;
        //    CGFloat midY = imageHeight/2.0;
        
        CIImage *ciiInputImage = [CIImage imageWithCGImage: inputImage.CGImage];
        
        CIImage* filteredImage = ciiInputImage;
        
        for (MBImageFilter* filter in self.fractalDocument.fractal.imageFilters) {
            [filter setGoodDefaultsOnCIFilter: filter.ciFilter forImage: filteredImage bounds: imageBounds];
            filteredImage = [filter.ciFilter valueForKey: kCIOutputImageKey];
        }
        
        CGImageRef cgImage = [self.filterContext createCGImage: filteredImage fromRect: imageBounds];
        
        filteredUIImage = [UIImage imageWithCGImage: cgImage scale: scale orientation: UIImageOrientationUp];
        
        CGImageRelease(cgImage);
        [self.activityIndicator stopAnimating];
    }
    
    return filteredUIImage;
}
//
- (IBAction)toggleApplyFilter:(id)sender
{
    MDBFractalObjectList* filters = self.fractalDocument.fractal.imageFilters;
    BOOL filtersOn = self.fractalDocument.fractal.applyFilters;
    
    if (filters.isEmpty && filtersOn)
    {
        self.fractalDocument.fractal.applyFilters = NO;
    }
    else if (!filters.isEmpty)
    {
        self.fractalDocument.fractal.applyFilters = !filtersOn;
    }
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

- (IBAction)moveTwoFingerPanToBaseRotation:(UIButton *)sender
{
    self.twoFingerPanProperties = @{@"imageView":self.fractalView,
                                    @"hPath":@"baseAngle",
                                    @"hScale":@5,
                                    @"hStep":@1,
                                    @"vPath":@"randomness",
                                    @"vScale":@-0.001};
    
    self.baseRotationButton.selected = YES;
    self.jointAngleButton.selected = NO;
    self.incrementsButton.selected = NO;
}

- (IBAction)moveTwoFingerPanToJointAngle:(UIButton *)sender
{
    self.twoFingerPanProperties = @{@"imageView":self.fractalView,
                                    @"hPath":@"turningAngle",
                                    @"hScale":@5,
                                    @"hStep":@1,
                                    @"vPath":@"lineWidth",
                                    @"vScale":@0.01};
    
    self.baseRotationButton.selected = NO;
    self.jointAngleButton.selected = YES;
    self.incrementsButton.selected = NO;
}

- (IBAction)moveTwoFingerPanToIncrements:(UIButton *)sender
{
    self.twoFingerPanProperties = @{@"imageView":self.fractalView,
                                    @"hPath":@"turningAngleIncrement",
                                    @"hScale":@0.001,
                                    @"hStep":@0.01,
                                    @"vPath":@"lineChangeFactor",
                                    @"vScale":@-0.001};
    
    self.baseRotationButton.selected = NO;
    self.jointAngleButton.selected = NO;
    self.incrementsButton.selected = YES;
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
verticalPropertyPath: panProps[@"vPath"]
              vScale: [(NSNumber*)panProps[@"vScale"] floatValue]];
}
- (IBAction)panLevel0:(UIPanGestureRecognizer *)sender
{
    [self convertPan: sender
         onImageView: self.fractalViewLevel0
horizontalPropertyPath: @"baseAngle"
              hScale: 5.0/1.0
               hStep:    1.0
verticalPropertyPath: @"randomness"
              vScale: -1.0/1000.0];
}
- (IBAction)panLevel1:(UIPanGestureRecognizer *)sender
{
    [self convertPan: sender
         onImageView: self.fractalViewLevel1
horizontalPropertyPath: @"turningAngle"
              hScale: 1.0/2.0
               hStep:    0.25
verticalPropertyPath:@"lineWidth"
              vScale: 5.0/50.0];
}
- (IBAction)panLevel2:(UIPanGestureRecognizer *)sender
{
    [self convertPan: sender
         onImageView: self.fractalViewLevel2
horizontalPropertyPath: @"turningAngleIncrement"
              hScale: 1.0/1000.0
               hStep: 0.01
verticalPropertyPath: @"lineChangeFactor"
              vScale: -1.0/1000.0];
}

-(void) convertPan: (UIPanGestureRecognizer*) gestureRecognizer
       onImageView: (UIImageView*) subLayer
                            horizontalPropertyPath: (NSString*) horizontalPath
                           hScale: (CGFloat) hScale
                            hStep: (CGFloat) hStepSize
                           verticalPropertyPath: (NSString*) verticalPath
                          vScale: (CGFloat) vScale
{
    
    static CGPoint initialPosition;
    static CGFloat  initialHValue;
    static CGFloat  initialVValue;
    static NSInteger determinedState;
    static BOOL     isIncreasing;
    static NSInteger axisState;
    
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
                CGFloat scaledWidth = floorf(translation.y * vScale * 1000.0)/1000.0;
                CGFloat newWidth = fminf(fmaxf(initialVValue + scaledWidth, vMin), vMax);
                [fractal setValue: @(newWidth) forKey: verticalPath];
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
                }
                else
                {
                    CGFloat scaled = floorf(translation.x * hScale * 1000.0)/1000.0;
                    CGFloat newValue = fminf(fmaxf(initialHValue + scaled, hMin), hMax);
                    [fractal setValue: @(newValue) forKey: horizontalPath];
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
        [self updateLibraryRepresentationIfNeeded];
    }
}

-(IBAction) autoScale:(id)sender
{
    //    CALayer* subLayer = nil; //[self fractalLevelNLayer];
    //    subLayer.transform = CATransform3DIdentity;
    //    subLayer.position = self.fractalView.center;
    // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
    [self.fractalScrollView setZoomScale: 1.0 animated: YES];
    self.fractalScrollView.contentOffset = CGPointZero;
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
    [UIView animateWithDuration: duration
                     animations:^{
                         self.fractalViewLevel0.superview.alpha = 0;
                         self.fractalViewLevel1.superview.alpha = 0;
                         self.fractalViewLevel2.superview.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         self.fractalViewLevel0.superview.hidden = YES;
                         self.fractalViewLevel1.superview.hidden = YES;
                         self.fractalViewLevel2.superview.hidden = YES;
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
                         self.fractalViewLevel0.superview.alpha = 0.75;
                         self.fractalViewLevel1.superview.alpha = 0.75;
                         self.fractalViewLevel2.superview.alpha = 0.75;
                     }];
}
- (UIImage *)snapshot:(UIView *)view size: (CGSize)imageSize withWatermark: (BOOL)useWatermark
{
    UIImage* imageExport;
    
    LSFractalRenderer* renderer = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.fractalDocument.sourceDrawingRules];
    NSInteger level = MIN(self.fractalDocument.fractal.level, 3) ;
    renderer.levelData = self.levelDataArray[level];
    renderer.name = @"Image renderer";
    renderer.margin = imageSize.width > 500.0 ? 24.0 : 8.0;
    renderer.autoscale = YES; // leave yes to fill thumbnail
    renderer.flipY = YES;
    renderer.showOrigin = NO;
    renderer.pixelScale = self.fractalView.contentScaleFactor;
    renderer.applyFilters = self.fractalDocument.fractal.applyFilters;
    
    UIColor* backgroundColor = [self.fractalDocument.fractal.backgroundColor asUIColor];
    if (!backgroundColor) backgroundColor = [UIColor clearColor];
    renderer.backgroundColor = backgroundColor;
    renderer.autoExpand = YES;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 2.0);
    {
        CGContextRef aCGontext = UIGraphicsGetCurrentContext();
        [renderer drawInContext: aCGontext size: imageSize];
        if (useWatermark && !renderer.applyFilters) [self drawWatermarkInContext: aCGontext size: imageSize];
        imageExport = UIGraphicsGetImageFromCurrentImageContext();
        if (renderer.applyFilters) {
            imageExport = [self applyFiltersToImage: imageExport];
        }
    }
    UIGraphicsEndImageContext();

    if (useWatermark && renderer.applyFilters) {
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

    CGRect textRect = CGRectMake(0, 0, 682, 167);
    NSString* watermark = @"FractalScapes";
    CGContextSaveGState(aCGContext);
    {
        CGContextSetShadowWithColor(aCGContext, FractalScapeIconSet.topShadow.shadowOffset, FractalScapeIconSet.topShadow.shadowBlurRadius, [FractalScapeIconSet.topShadow.shadowColor CGColor]);
        NSMutableParagraphStyle* textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
        textStyle.alignment = NSTextAlignmentCenter;
        
        NSDictionary* textFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"Papyrus" size: 96], NSForegroundColorAttributeName: FractalScapeIconSet.selectionBackgroundColor, NSParagraphStyleAttributeName: textStyle};
        
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
                
                NSDictionary* textFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"Papyrus" size: 96], NSForegroundColorAttributeName: opaqueShadow, NSParagraphStyleAttributeName: textStyle};
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
    
    LSFractalRenderer* renderer = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.fractalDocument.sourceDrawingRules];
    renderer.levelData = self.levelDataArray[3];
    renderer.name = @"PDF renderer";
    renderer.margin = 72.0;
    renderer.autoscale = YES;
    renderer.flipY = YES;
    renderer.showOrigin = NO;
    
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

-(void) shareFractalToPublicCloud
{
    NSLog(@"Unimplemented sharing to public cloud.");

}

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
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Share Status"
                                                                   message: successText
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
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
    /*
     If the book's managed object context doesn't already have an undo manager, then create one and set it for the context and self.
     The view controller needs to keep a reference to the undo manager it creates so that it can determine whether to remove the undo manager when editing finishes.
     */
//    if (self.fractalDocument.fractal.managedObjectContext.undoManager == nil)
//    {
//        
//        NSUndoManager *anUndoManager = [[NSUndoManager alloc] init];
//        [anUndoManager setLevelsOfUndo:50];
//        [anUndoManager setGroupsByEvent: NO];
//        _undoManager = anUndoManager;
//        
//        self.fractalDocument.fractal.managedObjectContext.undoManager = _undoManager;
//    }
//    
//    // Register as an observer of the book's context's undo manager.
//    NSUndoManager *fractalUndoManager = self.fractalDocument.fractal.managedObjectContext.undoManager;
//    
//    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
//    [dnc addObserver:self selector:@selector(undoManagerDidUndo:) name:NSUndoManagerDidUndoChangeNotification object:fractalUndoManager];
//    [dnc addObserver:self selector:@selector(undoManagerDidRedo:) name:NSUndoManagerDidRedoChangeNotification object:fractalUndoManager];
}


- (void)cleanUpUndoManager
{
    
    // Remove self as an observer.
#pragma message "TODO: fix for uidocument"
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

@end
