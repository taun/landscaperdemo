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

#import "MBAppDelegate.h"
#import "MBLSFractalEditViewController.h"
#import "FractalControllerProtocol.h"
#import "MBFractalLibraryViewController.h"
#import "MBFractalAppearanceEditorViewController.h"
#import "MBFractalRulesEditorViewController.h"
#import "MDBFractalFiltersControllerViewController.h"
#import "LSReplacementRule.h"
#import "LSFractal.h"
#import "MBColor.h"
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
@property (nonatomic, assign) BOOL                  startedInLandscape;

//@property (nonatomic, strong) NSSet*                editControls;
//@property (nonatomic, strong) NSMutableArray*       cachedEditViews;
//@property (nonatomic, assign) NSInteger             cachedEditorsHeight;

@property (nonatomic, assign) double                viewNRotationFromStart;

@property (nonatomic, strong) UIBarButtonItem*      cancelButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      undoButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      redoButtonItem;
#pragma message "TODO Add autoExpand as LSFractal model property."
@property (nonatomic, strong) NSArray*              disabledDuringPlaybackButtons;
@property (nonatomic, strong) NSArray*              editPassThroughViews;

@property (nonatomic,weak) UIViewController*        currentPresentedController;
@property (nonatomic,assign) CGSize                 popoverPortraitSize;
@property (nonatomic,assign) CGSize                 popoverLandscapeSize;
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

@property (nonatomic,strong) UIDocumentInteractionController *documentShareController;

-(void) saveToUserPreferencesAsLastEditedFractal: (MDBFractalInfo*) fractalInfo;

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
}

- (void)configureWithNewBlankDocument
{   
    LSFractal* newFractal = [LSFractal new];
    
    MDBFractalInfo* fractalInfo = [self.documentController createFractalInfoForFractal: newFractal withDocumentDelegate: self];
    
    self.fractalInfo = fractalInfo;
}

#pragma mark - UIViewController Methods
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}
-(IBAction) backToLibrary:(id)sender
{
    [self.fractalDocument updateChangeCount: UIDocumentChangeDone];
    [self.presentingViewController dismissViewControllerAnimated: YES completion:^{
        //
    }];
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
    
    [self.navigationItem setHidesBackButton: NO animated: NO];
    self.navigationItem.leftItemsSupplementBackButton = YES;
//    self.navigationItem.backBarButtonItem = backButton;
    
    NSMutableArray* items = [self.navigationItem.leftBarButtonItems mutableCopy];
    if (!items) {
        items = [NSMutableArray new];
    }
//    [items addObject: backButton];
    [items addObject: copyButton];
    [items addObject: shareButton];
    [self.navigationItem setLeftBarButtonItems: items];
    
    
//    items = [self.navigationItem.rightBarButtonItems mutableCopy];
//    [items addObject: self.autoExpandOn];
//    [items addObject: self.playButton];
//    [self.navigationItem setRightBarButtonItems: items];
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
    _observedReplacementRules = [NSMutableSet new];
    
    [self configureNavBarButtons];

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL showPerformanceDataSetting = [defaults boolForKey: kPrefShowPerformanceData];
    self.showPerformanceData = showPerformanceDataSetting;

    BOOL fullScreenState = [defaults boolForKey: kPrefFullScreenState];
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

    _popoverPortraitSize = CGSizeMake(748.0,350.0);
    _popoverLandscapeSize = CGSizeMake(400.0,650.0);
    
    // Setup the scrollView to allow the fractal image to float.
    // This is to allow the user to move the fractal out from under the HUD display.
    UIEdgeInsets scrollInsets = UIEdgeInsetsMake(300.0, 300.0, 300.0, 300.0);
    self.fractalScrollView.contentInset = scrollInsets;
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

    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    
    self.navigationItem.title = self.fractalDocument.fractal.name;
    [self setupSlidersForCurrentFractal];
    [self saveToUserPreferencesAsLastEditedFractal: self.fractalInfo];
}

- (void)handleDocumentStateChangedNotification:(NSNotification *)notification
{
    UIDocumentState state = self.fractalDocument.documentState;
    
    if (state & UIDocumentStateInConflict) {
        [self resolveConflicts];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.tableView reloadData];
        [self queueFractalImageUpdates];
        [self updateInterface];
    });
}

- (void)resolveConflicts
{
    // Any automatic merging logic or presentation of conflict resolution UI should go here.
    // For this sample, just pick the current version and mark the conflict versions as resolved.
    [NSFileVersion removeOtherVersionsOfItemAtURL: self.fractalDocument.fileURL error:nil];
    
    NSArray *conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL: self.fractalDocument.fileURL];
    for (NSFileVersion *fileVersion in conflictVersions) {
        fileVersion.resolved = YES;
    }
}

/* on staartup, fractal should not be set until just before view didAppear */
-(void) viewDidAppear:(BOOL)animated
{
    if (_fractalInfo.document.fractal) {
        [super viewDidAppear:animated];
        [self regenerateLevels];
        [self updateInterface];
        [self autoScale: nil];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeObserversForCurrentDocument];
    [self saveToUserPreferencesAsLastEditedFractal: nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        [self queueFractalImageUpdates];
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
        [self updateNavButtons];
        
    }
    else if ([keyPath isEqualToString: @"category"])
    {
        
    }
    else if ([keyPath isEqualToString: @"descriptor"])
    {
        
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    [self updateUndoRedoBarButtonState];
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
    UIDocumentState docState = fractalInfo.document.documentState;
    
    if (docState != UIDocumentStateNormal)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            //
            [fractalInfo.document openWithCompletionHandler:^(BOOL success) {
                //detect if we have a new default fractal
                id<MDBTileObjectProtocol> tileObject = [fractalInfo.document.fractal.startingRules firstObject];
                
                if (fractalInfo.document.fractal && tileObject.isDefaultObject)
                {
                    //default rules and settings
                    LSFractal* newFractal = fractalInfo.document.fractal;
                    
                    LSDrawingRuleType* rules = fractalInfo.document.sourceDrawingRules;
                    
                    [newFractal.startingRules addObjectsFromArray: [rules rulesArrayFromRuleString: @"F!"]];
                    
                    MBColor* defaultLine = [MBColor newMBColorWithUIColor: [UIColor blueColor]];
                    defaultLine.identifier = @"blue";
                    defaultLine.name = @"Blue";
                    [newFractal.lineColors addObject: defaultLine];
                    
                    MBColor* defaultFill = [MBColor newMBColorWithUIColor: [UIColor greenColor]];
                    defaultFill.identifier = @"green";
                    defaultFill.name = @"Green";
                    [newFractal.fillColors addObject: defaultFill];
                    
                    [fractalInfo.document updateChangeCount: UIDocumentChangeDone];
                }
                
                self.fractalInfo = fractalInfo;
            }];
        });
        return;
    }
    
    if (_fractalInfo != fractalInfo) {
        
        if (fractalInfo) {
            [self removeObserversForCurrentDocument];
        }
        
        _fractalInfo = fractalInfo;
        
        self.autoscaleN = YES;
        self.hudLevelStepper.maximumValue = kHudLevelStepperDefaultMax;
        
        [self addObserverForFractalChangeInCurrentDocument];
        
        
        if (_fractalInfo.document != nil && _fractalInfo.document.fractal && self.fractalView)
        {
            [self regenerateLevels];
            [self updateInterface];
            [self autoScale: nil];
        }
    }
}

-(MDBFractalDocument*)fractalDocument
{
    return _fractalInfo.document;
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

        UIImage* fractalImage = [self snapshot: self.fractalView size: CGSizeMake(390.0, 390.0)];
        _fractalInfo.document.thumbnail = fractalImage;
        _fractalInfo.changeDate = [NSDate date];
        [_fractalInfo.document updateChangeCount: UIDocumentChangeDone];
        
        [self.documentController setFractalInfoHasNewContents: _fractalInfo];
        
        [_privateImageGenerationQueue cancelAllOperations];
        
        _fractalInfo.document.delegate = nil;

        [_fractalInfo.document closeWithCompletionHandler:nil];
    }
}

-(void) addObserversForCurrentFractal
{
    LSFractal* fractal = _fractalInfo.document.fractal;
    if (fractal)
    {
        [self saveToUserPreferencesAsLastEditedFractal: _fractalInfo];
        
        [self setupSlidersForCurrentFractal];
        
        _lastImageUpdateTime = [NSDate date];

        NSMutableSet* propertiesToObserve = [NSMutableSet setWithSet: [LSFractal productionRuleProperties]];
        [propertiesToObserve unionSet: [LSFractal appearanceProperties]];
        [propertiesToObserve unionSet: [LSFractal redrawProperties]];
        [propertiesToObserve unionSet: [LSFractal labelProperties]];
        [propertiesToObserve addObject: @"startingRules.allObjects"];
        [propertiesToObserve addObject: @"lineColors.allObjects"];
        [propertiesToObserve addObject: @"fillColors.allObjects"];
        
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

-(void) saveToUserPreferencesAsLastEditedFractal: (MDBFractalInfo*) aFractalInfo
{
    NSURL* selectedFractalURL = aFractalInfo.URL;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setURL: selectedFractalURL forKey: kPrefLastEditedFractalURI];
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

-(CIContext*) filterContext {
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
    self.hudText1.text = [NSString stringWithFormat: @"%li", self.fractalDocument.fractal.level];
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
        [self.privateImageGenerationQueue addOperation: operation0];
    }
    
    if (!self.fractalViewLevel1.superview.hidden)
    {
        NSBlockOperation* operation1 = [self operationForRenderer: self.fractalRendererL1];
        self.fractalRendererL1.backgroundColor = [UIColor clearColor];
        [self.privateImageGenerationQueue addOperation: operation1];
    }
    
    if (!self.fractalViewLevel2.superview.hidden)
    {
        NSBlockOperation* operation2 = [self operationForRenderer: self.fractalRendererL2];
        self.fractalRendererL2.backgroundColor = [UIColor clearColor];
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
                    renderer.imageView.image = renderer.image;
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
    self.navigationItem.title = self.fractalDocument.fractal.name;
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
    else if ([segue.identifier isEqualToString: @"LibrarySegue"])
    {
        UINavigationController* navCon = segue.destinationViewController;
        newController = (UIViewController<FractalControllerProtocol>*)navCon.topViewController;
        [self libraryControllerIsPresenting: newController];
    }
}
- (IBAction)unwindToEditorFromAppearanceEditor:(UIStoryboardSegue *)segue
{
    [segue.sourceViewController dismissViewControllerAnimated: YES completion:^{
        //
        [self appearanceControllerWasDismissed];
    }];
}
/*!
 This gets called when cancelled.
 
 @param segue 
 */
- (IBAction)unwindToEditorFromLibrary:(UIStoryboardSegue *)segue
{
    [segue.sourceViewController dismissViewControllerAnimated: YES completion:^{
        //
        [self libraryControllerWasDismissed];
    }];
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
    else if ([popoverPresentationController.presentedViewController isKindOfClass: [MBFractalLibraryViewController class]])
    {
        [self libraryControllerWasDismissed];
    }
}
-(void) libraryControllerIsPresenting: (UIViewController<FractalControllerProtocol>*) controller
{
    controller.fractalControllerDelegate = self;
    controller.fractalDocument = self.fractalDocument;
    controller.fractalUndoManager = self.undoManager;
    controller.landscapeSize = self.popoverLandscapeSize;
    controller.portraitSize = self.popoverPortraitSize;
    CGSize viewSize = self.view.bounds.size;
    controller.preferredContentSize = viewSize.height > viewSize.width ? self.popoverPortraitSize : self.popoverLandscapeSize;
    controller.popoverPresentationController.delegate = self;
    
    self.currentPresentedController = controller;
    self.previousNavBarState = self.navigationController.navigationBar.hidden;
    self.navigationController.navigationBar.hidden = YES;
}
-(BOOL) wasLibraryPopoverPresentedAndNowDismissed
{
    BOOL wasPresented = NO;
    
    if ([self.currentPresentedController isKindOfClass: [MBFractalLibraryViewController class]]) {
        wasPresented = YES;
        [self.currentPresentedController dismissViewControllerAnimated: YES completion:^{
            //
            [self libraryControllerWasDismissed];
        }];
    }
    
    return wasPresented;
}
-(void) libraryControllerWasDismissed
{
    self.navigationController.navigationBar.hidden = self.previousNavBarState;
    [self.view setNeedsLayout];
    self.currentPresentedController = nil;
}
-(void) appearanceControllerIsPresenting: (UIViewController<FractalControllerProtocol>*) controller
{
    if (self.fractalDocument.fractal.isImmutable) self.fractalDocument.fractal = [self.fractalDocument.fractal mutableCopy];
    
    controller.fractalControllerDelegate = self;
    controller.fractalDocument = self.fractalDocument;
    controller.fractalUndoManager = self.undoManager;
    controller.landscapeSize = self.popoverLandscapeSize;
    controller.portraitSize = self.popoverPortraitSize;
    CGSize viewSize = self.view.bounds.size;
    controller.preferredContentSize = viewSize.height > viewSize.width ? self.popoverPortraitSize : self.popoverLandscapeSize;
    controller.popoverPresentationController.delegate = self;
    controller.popoverPresentationController.passthroughViews = @[self.fractalViewRoot];
    
    self.currentPresentedController = controller;
    self.previousNavBarState = self.navigationController.navigationBar.hidden;
    self.navigationController.navigationBar.hidden = YES;
    self.fractalViewRootSingleTapRecognizer.enabled = NO;
    [self.view setNeedsLayout];
}
-(void) appearanceControllerWasDismissed
{
    self.navigationController.navigationBar.hidden = self.previousNavBarState;
    self.fractalViewRootSingleTapRecognizer.enabled = YES;
    self.currentPresentedController = nil;
    [self.view setNeedsLayout];
}

#pragma mark - Control Actions
/*!
 Obsoleted by UIActivityViewController code below.
 
 @param sender share button
 */
- (IBAction)shareButtonPressed:(id)sender
{
    if ([self wasLibraryPopoverPresentedAndNowDismissed]) {
        return;
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
                                           [self shareWithActivityControler: sender];
                                       }];
        [alert addAction: cameraAction];
    }
    UIAlertAction* vectorPDF = [UIAlertAction actionWithTitle:@"Export as Vector PDF" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                       [self shareWithDocumentInteractionController: sender];
                                   }];
    [alert addAction: vectorPDF];
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Public Cloud" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                       [self shareFractalToPublicCloud];
                                   }];
    [alert addAction: fractalCloud];
    
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
    [self shareWithDocumentInteractionController: sender];
}

- (IBAction)shareWithDocumentInteractionController:(id)sender
{
    
    NSData* pdfData = [self createPDF];
    
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    // The file extension is important so that some mime magic happens!
    NSString* fileName = [NSString stringWithFormat: @"%@.pdf",self.fractalDocument.fractal.name];
    NSString *filePath = [docsPath stringByAppendingPathComponent: fileName];
    NSURL *fileUrl     = [NSURL fileURLWithPath:filePath];
    
    [pdfData writeToURL:fileUrl atomically:YES]; // save the file
    
    
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
- (IBAction)shareWithActivityControler:(id)sender
{
    
    UIImage* fractalImage = [self snapshot: self.fractalView size: CGSizeMake(1024.0, 1024.0)];
    NSData* pngImage = UIImagePNGRepresentation(fractalImage);
    
    NSData* pdfData = [self createPDF];
    
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    // The file extension is important so that some mime magic happens!
    NSString* fileName = [NSString stringWithFormat: @"%@.pdf",self.fractalDocument.fractal.name];
    NSString *filePath = [docsPath stringByAppendingPathComponent: fileName];
    NSURL *fileUrl     = [NSURL fileURLWithPath:filePath];
    
    [pdfData writeToURL:fileUrl atomically:YES]; // save the file
    
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[pngImage, pdfData] applicationActivities:nil];
    
    
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
    if ([self wasLibraryPopoverPresentedAndNowDismissed]) {
        return;
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

    [UIView animateWithDuration: 0.25
                          delay: 0.0
                        options: UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         //
                         [self.navigationController setNavigationBarHidden: !self.navigationController.navigationBar.isHidden animated: NO];
//                         self.navigationController.navigationBar.hidden = !self.navigationController.navigationBar.isHidden;
                         self.previousNavBarState = self.navigationController.navigationBar.hidden;
                         self.fractalScrollView.contentOffset = CGPointZero;
//                         [self.view setNeedsLayout];

                     } completion:^(BOOL finished) {
                         //
                     }];
}

- (IBAction)copyFractal:(id)sender
{
    LSFractal* newFractal = [self.fractalDocument.fractal copy];
    
    MDBFractalInfo* fractalInfo = [self.documentController createFractalInfoForFractal: newFractal withDocumentDelegate: self];
    
    self.fractalInfo = fractalInfo;
    
    [self performSegueWithIdentifier: @"EditSegue" sender: self];
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
- (IBAction)baseAngleSliderChanged:(UISlider*)sender
{
    CGFloat newAngleDegrees = sender.value;
    self.fractalDocument.fractal.baseAngle = radians(newAngleDegrees);
}

- (IBAction)turnAngleSliderChanged:(UISlider*)sender
{
    CGFloat newAngleDegrees = sender.value;
    self.fractalDocument.fractal.turningAngle = radians(newAngleDegrees);
}

- (IBAction)turningAngleIncrementSliderChanged:(UISlider*)sender
{
    CGFloat percent = sender.value;
    self.fractalDocument.fractal.turningAngleIncrement = percent;
}

- (IBAction)randomnessSliderChanged:(UISlider*)sender
{
    CGFloat percent = sender.value;
    self.fractalDocument.fractal.randomness = percent;
}

- (IBAction)lineWidthSliderChanged:(UISlider*)sender
{
    CGFloat percent = sender.value;
    self.fractalDocument.fractal.lineWidth = percent;
}

- (IBAction)lineLengthIncrementSliderChanged:(UISlider*)sender
{
    CGFloat percent = sender.value;
    self.fractalDocument.fractal.lineChangeFactor = percent;
}

#pragma mark - Filter Actions
- (IBAction)applyFilter:(CIFilter*)filter
{
    CGFloat scale = self.fractalRendererLN.image.scale;
    CGSize imageSize = self.fractalRendererLN.image.size;
    CGRect imageBounds = CGRectMake(0.0, 0.0, imageSize.width*scale, imageSize.height*scale);
    CGFloat midX = scale*imageSize.width/2.0;
    CGFloat midY = scale*imageSize.height/2.0;
    CIVector* filterCenter = [CIVector vectorWithX: midX Y: midY];
    CIImage *image = [CIImage imageWithCGImage: self.fractalRendererLN.image.CGImage];

    [filter setDefaults];
    NSDictionary* filterAttributes = [filter attributes];
    if (filterAttributes[kCIInputCenterKey]) {
        [filter setValue: filterCenter forKey: kCIInputCenterKey];
    }
    if (filterAttributes[@"inputPoint"]) {
        [filter setValue: filterCenter forKey: @"inputPoint"];
    }
    
    if (filterAttributes[kCIInputWidthKey]) {
        CGFloat width = self.fractalRendererLN.rawFractalPathBounds.size.width/2.0;
        [filter setValue: @(width) forKey: kCIInputWidthKey];
    }
    [filter setValue:image forKey:kCIInputImageKey];

    CIImage *filteredImage = [filter valueForKey:kCIOutputImageKey];
    
    CGImageRef cgImage = [self.filterContext createCGImage: filteredImage fromRect: imageBounds];
    
    UIImage* filteredUIImage = [UIImage imageWithCGImage: cgImage scale: scale orientation: UIImageOrientationUp];
    
    self.fractalView.image = filteredUIImage;
    CGImageRelease(cgImage);
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
/* want to use 2 finger pans for changing rotation and line thickness in place of swiping
 need to lock in either horizontal or vertical panning view a state and state change */
-(IBAction)twoFingerPanFractal:(UIPanGestureRecognizer *)gestureRecognizer
{
    [self convertPanToAngleAspectChange: gestureRecognizer
                              imageView: self.fractalView
                              anglePath: @"turningAngle"
                             angleScale: 5.0/1.0
                               minAngle: [self.fractalDocument.fractal minValueForProperty: @"turningAngle"]
                               maxAngle: [self.fractalDocument.fractal maxValueForProperty: @"turningAngle"]
                              angleStep:    3.0
                             aspectPath: @"lineWidth"
                            aspectScale: 1.0/100.0
                              minAspect: [self.fractalDocument.fractal minValueForProperty: @"lineWidth"]
                              maxAspect: [self.fractalDocument.fractal maxValueForProperty: @"lineWidth"]];
}
- (IBAction)panLevel0:(UIPanGestureRecognizer *)sender
{
    [self convertPanToAngleAspectChange: sender
                              imageView: self.fractalViewLevel0
                              anglePath: @"baseAngle"
                             angleScale: 5.0/1.0
                               minAngle: [self.fractalDocument.fractal minValueForProperty: @"baseAngle"]
                               maxAngle: [self.fractalDocument.fractal maxValueForProperty: @"baseAngle"]
                              angleStep:    5.0
                             aspectPath: @"randomness"
                            aspectScale: -1.0/1000.0
                              minAspect: [self.fractalDocument.fractal minValueForProperty: @"randomness"]
                              maxAspect: [self.fractalDocument.fractal maxValueForProperty: @"randomness"]];
}
- (IBAction)panLevel1:(UIPanGestureRecognizer *)sender
{
    [self convertPanToAngleAspectChange: sender
                              imageView: self.fractalViewLevel1
                              anglePath: @"turningAngle"
                             angleScale: 1.0/10.0
                               minAngle: [self.fractalDocument.fractal minValueForProperty: @"turningAngle"]
                               maxAngle: [self.fractalDocument.fractal maxValueForProperty: @"turningAngle"]
                              angleStep:    0.25
                             aspectPath:@"lineWidth"
                            aspectScale: 5.0/50.0
                              minAspect: [self.fractalDocument.fractal minValueForProperty: @"lineWidth"]
                              maxAspect: [self.fractalDocument.fractal maxValueForProperty: @"lineWidth"]];
}
#pragma message "TODO: need to add a step size and change turningAngleIncrement from degrees to percent"
- (IBAction)panLevel2:(UIPanGestureRecognizer *)sender
{
    [self convertPanToAngleAspectChange: sender
                              imageView: self.fractalViewLevel2
                              anglePath: @"turningAngleIncrement"
                             angleScale: 1.0/1.0
                               minAngle: 0.0
                               maxAngle: 57.295779513
                              angleStep: 0.0
                             aspectPath: @"lineChangeFactor"
                            aspectScale: -1.0/1000.0
                              minAspect: 0.0
                              maxAspect: 1.0];
}

-(void) convertPanToAngleAspectChange: (UIPanGestureRecognizer*) gestureRecognizer
                            imageView: (UIImageView*) subLayer
                            anglePath: (NSString*) anglePath
                           angleScale: (CGFloat) angleScale
                             minAngle: (CGFloat) minAngle
                             maxAngle: (CGFloat) maxAngle
                            angleStep: (CGFloat) stepAngle
                           aspectPath: (NSString*) aspectPath
                          aspectScale: (CGFloat) aspectScale
                            minAspect: (CGFloat) minAspect
                            maxAspect: (CGFloat) maxAspect
{
    
    static CGPoint initialPosition;
    static CGFloat  initialAngleDegrees;
    static CGFloat  initialWidth;
    static NSInteger determinedState;
    static BOOL     isIncreasing;
    static NSInteger axisState;
    
    UIView *fractalView = [gestureRecognizer view];
    UIGestureRecognizerState state = gestureRecognizer.state;
    
    if (state == UIGestureRecognizerStateBegan)
    {
        self.autoscaleN = NO;
        
//        [self.undoManager beginUndoGrouping];
//        [self.fractalDocument.fractal.managedObjectContext processPendingChanges];
        
        initialPosition = CGPointZero;//subLayer.position;
        
        if (anglePath)
        {
            initialAngleDegrees =  floorf(100.0 * degrees([[self.fractalDocument.fractal valueForKey: anglePath] doubleValue])) / 100.0;
        }
        if (aspectPath)
        {
            initialWidth = floorf(100.0 * [[self.fractalDocument.fractal valueForKey: aspectPath] doubleValue]) / 100.0;
        }
        
        determinedState = 0;
        isIncreasing = NO;
        
    } else if (state == UIGestureRecognizerStateChanged)
    {
        
        CGPoint translation = [gestureRecognizer translationInView: fractalView];
        CGPoint velocity = [gestureRecognizer velocityInView: fractalView];
        
        if (determinedState==0)
        {
            if (fabsf(translation.x) >= fabsf(translation.y))
            {
                axisState = 0;
            } else
            {
                axisState = 1;
            }
            determinedState = 1;
        } else
        {
            if (axisState && aspectPath)
            {
                // vertical, change aspect
                CGFloat scaledWidth = floorf(translation.y * aspectScale * 1000.0)/1000.0;
                CGFloat newWidth = fminf(fmaxf(initialWidth + scaledWidth, minAspect), maxAspect);
                [self.fractalDocument.fractal setValue: @(newWidth) forKey: aspectPath];
                //self.fractalDocument.fractal.lineWidth = @(newidth);
                
            } else if (!axisState && anglePath)
            {
                // hosrizontal
                CGFloat closeEnough = stepAngle/5.0;
                
                CGFloat scaledStepAngle = floorf(translation.x * angleScale)/100;
                CGFloat newAngleDegrees = fminf(fmaxf(initialAngleDegrees + scaledStepAngle, minAngle), maxAngle);
                if (stepAngle > 0)
                {
                    CGFloat proximity = fmodf(newAngleDegrees, stepAngle);
                    if (fabsf(proximity) < closeEnough)
                    {
                        newAngleDegrees = floorf(newAngleDegrees/stepAngle)*stepAngle;
                    } else if (velocity.x > 0.0)
                    {
                        newAngleDegrees -= closeEnough;
                    }
                }
                [self.fractalDocument.fractal setValue: @(radians(newAngleDegrees)) forKey: anglePath];
                
            }
        }
        
    } else if (state == UIGestureRecognizerStateCancelled)
    {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
        
        [self.fractalDocument.fractal setValue:  @(radians(initialAngleDegrees)) forKey: anglePath];
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
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: fullScreenState forKey: kPrefFullScreenState];
    [defaults synchronize];
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
- (UIImage *)snapshot:(UIView *)view size: (CGSize)imageSize
{
    UIImage* imageExport;
    
    LSFractalRenderer* renderer = [LSFractalRenderer newRendererForFractal: self.fractalDocument.fractal withSourceRules: self.fractalDocument.sourceDrawingRules];
    renderer.levelData = self.levelDataArray[3];
    renderer.name = @"Image renderer";
    renderer.margin = 36.0;
    renderer.autoscale = YES; // leave yes to fill thumbnail
    renderer.flipY = YES;
    renderer.showOrigin = NO;
    renderer.pixelScale = self.fractalView.contentScaleFactor;
    
    UIColor* backgroundColor = [self.fractalDocument.fractal.backgroundColor asUIColor];
    if (!backgroundColor) backgroundColor = [UIColor clearColor];
    renderer.backgroundColor = backgroundColor;
    renderer.autoExpand = YES;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 2.0);
    {
        CGContextRef aCGontext = UIGraphicsGetCurrentContext();
        [renderer drawInContext: aCGontext size: imageSize];
        imageExport = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return imageExport;
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
    NSDictionary* pdfMetaData = @{(NSString*)kCGPDFContextCreator:@"FractalScape", (NSString*)kCGPDFContextTitle:self.fractalDocument.fractal.name, (NSString*)kCGPDFContextKeywords:self.fractalDocument.fractal.category};
    
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
-(void) shareFractalToCameraRoll
{
    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    
    if (cameraAuthStatus == ALAuthorizationStatusNotDetermined || cameraAuthStatus == ALAuthorizationStatusAuthorized)
    {
        ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
        
        UIImage* fractalImage = [self snapshot: self.fractalView size: CGSizeMake(1024.0, 1024.0)];
        NSData* pngImage = UIImagePNGRepresentation(fractalImage);
        
        // Format the current date and time
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
        NSString *now = [formatter stringFromDate:[NSDate date]];
        
        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        // Exif metadata dictionary
        // Includes date and time as well as image dimensions
        NSDictionary *exifDictionary = @{(NSString *)kCGImagePropertyExifDateTimeOriginal:now,
                                         (NSString *)kCGImagePropertyExifDateTimeDigitized:now,
                                         (NSString *)kCGImagePropertyExifPixelXDimension:@(fractalImage.size.width),
                                         (NSString *)kCGImagePropertyExifPixelYDimension:@(fractalImage.size.height),
                                         (NSString *)kCGImagePropertyExifUserComment:self.fractalDocument.fractal.name,
                                         (NSString *)kCGImagePropertyExifLensMake:@"FractalScape",
                                         (NSString *)kCGImagePropertyExifLensModel:version};
        
        // Tiff metadata dictionary
        // Includes information about the application used to create the image
        // "Make" is the name of the app, "Model" is the version of the app
        NSMutableDictionary *tiffDictionary = [NSMutableDictionary dictionary];
        [tiffDictionary setValue:now forKey:(NSString *)kCGImagePropertyTIFFDateTime];
        [tiffDictionary setValue:@"FractalScape" forKey:(NSString *)kCGImagePropertyTIFFMake];
        [tiffDictionary setValue:self.fractalDocument.fractal.name forKey:(NSString *)kCGImagePropertyTIFFDocumentName];
        [tiffDictionary setValue:self.fractalDocument.fractal.descriptor forKey:(NSString *)kCGImagePropertyTIFFImageDescription];
        
        [tiffDictionary setValue:[NSString stringWithFormat:@"%@ (%@)", version, build] forKey:(NSString *)kCGImagePropertyTIFFModel];
        
        NSDictionary* pngDictionary = @{(NSString *)kCGImagePropertyPNGDescription:self.fractalDocument.fractal.descriptor,
                                        (NSString *)kCGImagePropertyPNGTitle:self.fractalDocument.fractal.name,
                                        (NSString *)kCGImagePropertyPNGSoftware:@"FractalScape",
                                        (NSString *)kCGImagePropertyPNGAuthor:@"FractalScape"};
        
        // Image metadata dictionary
        // Includes image dimensions, as well as the EXIF and TIFF metadata
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:[NSNumber numberWithFloat:fractalImage.size.width] forKey:(NSString *)kCGImagePropertyPixelWidth];
        [dict setValue:[NSNumber numberWithFloat:fractalImage.size.height] forKey:(NSString *)kCGImagePropertyPixelHeight];
        [dict setValue:exifDictionary forKey:(NSString *)kCGImagePropertyExifDictionary];
        [dict setValue:tiffDictionary forKey:(NSString *)kCGImagePropertyTIFFDictionary];
        [dict setValue:pngDictionary forKey:(NSString *)kCGImagePropertyPNGDictionary];
        
        
        [library writeImageDataToSavedPhotosAlbum: pngImage metadata: dict completionBlock:^(NSURL *assetURL, NSError *error){
            // call method for UIAlert about successful save with save text
            [self showSharedCompletionAlertWithText: @"your camera roll." error: error];
            
//            NSLog(@"Sharing to camera status %@.", error);
        }];
        
        //        [library writeImageToSavedPhotosAlbum: [fractalImage CGImage] orientation: ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error){
        //            // call method for UIAlert about successful save with save text
        //            [self showSharedCompletionAlertWithText: @"your camera roll." error: error];
        //
        //            NSLog(@"Sharing to camera status %@.", error);
        //        }];
    }
    
//    NSLog(@"Sharing to camera called.");
}
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
