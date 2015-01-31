//
//  MBLSFractalEditViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBAppDelegate.h"
#import "MBLSFractalEditViewController.h"
#import "MBFractalLibraryViewController.h"
#import "MBFractalAppearanceEditorViewController.h"
#import "MBFractalRulesEditorViewController.h"
#import "FractalControllerProtocol.h"
#import "LSReplacementRule.h"
//#import "MBLSFractalLevelNView.h"
#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "MBPlacedEntity+addons.h"
#import "MBScapeBackground+addons.h"
#import "MBFractalScape+addons.h"
#import "NSManagedObject+Shortcuts.h"

#import "LSFractalRenderer.h"

#import <QuartzCore/QuartzCore.h>
#include <ImageIO/CGImageProperties.h>
#import <AssetsLibrary/AssetsLibrary.h>

#include <math.h>

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

@interface MBLSFractalEditViewController ()

@property (nonatomic, assign) BOOL                  startedInLandscape;

//@property (nonatomic, strong) NSSet*                editControls;
//@property (nonatomic, strong) NSMutableArray*       cachedEditViews;
//@property (nonatomic, assign) NSInteger             cachedEditorsHeight;

@property (nonatomic, assign) double                viewNRotationFromStart;

@property (nonatomic, strong) UIBarButtonItem*      cancelButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      undoButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      redoButtonItem;
#pragma message "TODO Add autoExpand as LSFractal model property."
@property (nonatomic, strong) UIBarButtonItem*      autoExpandOn;
@property (nonatomic, strong) UIBarButtonItem*      autoExpandOff;
@property (nonatomic, strong) NSArray*              disabledDuringPlaybackButtons;

@property (nonatomic,weak) UIViewController*        currentPresentedController;
@property (nonatomic,assign) CGSize                 popoverPortraitSize;
@property (nonatomic,assign) CGSize                 popoverLandscapeSize;

@property (nonatomic,strong) NSManagedObjectContext        *privateFractalContext;
@property (nonatomic,strong) LSFractal                     *privateQueueFractal;
@property (nonatomic,strong) NSManagedObjectID             *fractalID;
@property (nonatomic,strong) NSArray                       *levelDataArray;
/*!
 Fractal background image generation queue.
 */
@property (nonatomic,strong) NSOperationQueue              *privateImageGenerationQueue;
@property (nonatomic,strong) LSFractalRenderer             *fractalRendererL0;
@property (nonatomic,strong) LSFractalRenderer             *fractalRendererL1;
@property (nonatomic,strong) LSFractalRenderer             *fractalRendererL2;
@property (nonatomic,strong) LSFractalRenderer             *fractalRendererLN;
@property (nonatomic,assign) BOOL                          autoscaleN;
@property (nonatomic,assign) BOOL                          autoExpandFractal;
@property (nonatomic,strong) NSDate                        *lastImageUpdateTime;

@property (nonatomic,strong) NSTimer                       *playbackTimer;
@property (nonatomic,assign) CGFloat                       playFrameIncrement;
@property (nonatomic,assign) CGFloat                       playIsPercentCompleted;
@property (nonatomic,strong) NSArray                       *playbackRenderers;

@property (nonatomic,strong) UIDocumentInteractionController *documentShareController;

-(void) saveToUserPreferencesAsLastEditedFractal: (LSFractal*) fractal;
-(void) addObserversForFractal: (LSFractal*) fractal;
-(void) removeObserversForFractal: (LSFractal*) fractal;

//-(void) setEditMode: (BOOL) editing;
-(void) fullScreenOn;
-(void) fullScreenOff;

-(void) playNextFrame: (NSTimer*)timer;

- (void)updateUndoRedoBarButtonState;
- (void)setUpUndoManager;
- (void)cleanUpUndoManager;
- (void) saveContext;

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
@synthesize fractal = _fractal;
@synthesize libraryViewController = _libraryViewController;

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

#pragma mark - UIViewController Methods
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}
-(void) configureNavBarButtons
{
    
    self.autoExpandOn = [[UIBarButtonItem alloc]initWithImage: [UIImage imageNamed: @"toolBarFullScreenIcon"]
                                                                  style: UIBarButtonItemStylePlain
                                                                 target: self
                                                                 action: @selector(toggleAutoExpandFractal:)];

    self.autoExpandOff = [[UIBarButtonItem alloc]initWithImage: [UIImage imageNamed: @"toolBarFullScreenIconOff"]
                                                                        style: UIBarButtonItemStylePlain
                                                                       target: self
                                                                       action: @selector(toggleAutoExpandFractal:)];
    
   self.playButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem: UIBarButtonSystemItemPlay
                                                                   target: self
                                                                   action: @selector(playButtonPressed:)];
    
    self.stopButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem: UIBarButtonSystemItemStop
                                                                   target: self
                                                                   action: @selector(stopButtonPressed:)];
    
    UIBarButtonItem* copyButton = [[UIBarButtonItem alloc]initWithImage: [UIImage imageNamed: @"toolBarCopyIcon"]
                                                                  style: UIBarButtonItemStylePlain
                                                                 target: self
                                                                 action: @selector(copyFractal:)];
    
    UIBarButtonItem* shareButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem: UIBarButtonSystemItemAction
                                                                 target: self
                                                                 action: @selector(shareButtonPressed:)];
    
    _disabledDuringPlaybackButtons = @[self.autoExpandOff, self.autoExpandOn, copyButton, shareButton];
    
    NSMutableArray* items = [self.navigationItem.leftBarButtonItems mutableCopy];
    [items addObject: copyButton];
    [items addObject: shareButton];
    [self.navigationItem setLeftBarButtonItems: items];
    
    items = [self.navigationItem.rightBarButtonItems mutableCopy];
    [items addObject: self.autoExpandOn];
    [items addObject: self.playButton];
    [self.navigationItem setRightBarButtonItems: items];
}
#pragma message "TODO: add variables for max,min values for angles, widths, .... Add to model, class fractal category???"
-(void)viewDidLoad
{
    [self configureNavBarButtons];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL showPerformanceDataSetting = [defaults boolForKey: kPrefShowPerformanceData];
    self.showPerformanceData = showPerformanceDataSetting;

    BOOL fullScreenState = [defaults boolForKey: kPrefFullScreenState];
    if (fullScreenState)
    {
        [self fullScreenOn];
    }

    _playbackSlider.hidden = YES;
    _playbackSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [_playbackSlider setThumbImage: [UIImage imageNamed: @"controlDragCircle"] forState: UIControlStateNormal];

    _popoverPortraitSize = CGSizeMake(748.0,350.0);
    _popoverLandscapeSize = CGSizeMake(400.0,650.0);
    
    _randomnessVerticalSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [_randomnessVerticalSlider setThumbImage: [UIImage imageNamed: @"controlDragCircle16px"] forState: UIControlStateNormal];
    _randomnessVerticalSlider.minimumValue = 0.0;
    _randomnessVerticalSlider.maximumValue = 0.2;
    _randomnessVerticalSlider.value = 0.0;
    
    _widthDecrementVerticalSlider.transform = CGAffineTransformMakeRotation(M_PI_2);
    [_widthDecrementVerticalSlider setThumbImage: [UIImage imageNamed: @"controlDragCircle16px"] forState: UIControlStateNormal];
    _widthDecrementVerticalSlider.minimumValue = 0.0;
    _widthDecrementVerticalSlider.maximumValue = 6.0;
    _widthDecrementVerticalSlider.value = 0.0;
    
    _lengthIncrementVerticalSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [_lengthIncrementVerticalSlider setThumbImage: [UIImage imageNamed: @"controlDragCircle16px"] forState: UIControlStateNormal];
    _lengthIncrementVerticalSlider.minimumValue = 0.0;
    _lengthIncrementVerticalSlider.maximumValue = 1.0;
    _lengthIncrementVerticalSlider.value = 0.0;
    
    [_baseAngleSlider setThumbImage: [UIImage imageNamed: @"controlDragCircle16px"] forState: UIControlStateNormal];
    _baseAngleSlider.minimumValue = -180.0;
    _baseAngleSlider.maximumValue = 180.0;
    _baseAngleSlider.value = 0.0;
    
    [_turnAngleSlider setThumbImage: [UIImage imageNamed: @"controlDragCircle16px"] forState: UIControlStateNormal];
    _turnAngleSlider.minimumValue = 0.0;
    _turnAngleSlider.maximumValue = 180.0;
    _turnAngleSlider.value = 0.0;
    
    [_turnIncrementSlider setThumbImage: [UIImage imageNamed: @"controlDragCircle16px"] forState: UIControlStateNormal];
    _turnIncrementSlider.minimumValue = 0.0;
    _turnIncrementSlider.maximumValue = 1.0;
    _turnIncrementSlider.value = 0.0;
    
    _lastImageUpdateTime = [NSDate date];
    
    // Setup the scrollView to allow the fractal image to float.
    // This is to allow the user to move the fractal out from under the HUD display.
    UIEdgeInsets scrollInsets = UIEdgeInsetsMake(300.0, 300.0, 300.0, 300.0);
    self.fractalScrollView.contentInset = scrollInsets;
    UIView* fractalCanvas = self.fractalView.superview;
    fractalCanvas.layer.shadowColor = [[UIColor blackColor] CGColor];
    fractalCanvas.layer.shadowOffset = CGSizeMake(5.0, 5.0);
    fractalCanvas.layer.shadowOpacity = 0.3;
    fractalCanvas.layer.shadowRadius = 3.0;
    
    self.fractal = [self getUsersLastFractal];
    
    [super viewDidLoad];
}

-(LSFractal*) getUsersLastFractal
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSURL* selectedFractalURL = [userDefaults URLForKey: kPrefLastEditedFractalURI];
    LSFractal* defaultFractal;
    
    MBAppDelegate* appDelegate = (MBAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext*context = [appDelegate managedObjectContext];

    if (selectedFractalURL == nil) {
        // use a default
        NSArray* allFractals = [LSFractal allFractalsInContext: context];
        if (allFractals.count > 0) {
            defaultFractal = allFractals[0];
        }
    } else {
        // instantiate the saved default URI
        NSPersistentStoreCoordinator* store = context.persistentStoreCoordinator;
        NSManagedObjectID* objectID = [store managedObjectIDForURIRepresentation: selectedFractalURL];
        if (objectID != nil) {
            defaultFractal = (LSFractal*)[context objectWithID: objectID];
        }
    }
    return defaultFractal;
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
    
    [self autoScale: nil];
}

-(void) viewWillAppear:(BOOL)animated
{
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    //    self.editing = NO;
    [super viewWillAppear:animated];
    
}

/* on staartup, fractal should not be set until just before view didAppear */
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //    [self refreshContents];
    
    //    self.editing = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    
    [_privateImageGenerationQueue cancelAllOperations];
    
    if (self.editing)
    {
        [self.fractal.managedObjectContext save: nil];
        [self setUndoManager: nil];
    } else
    {
        // undo all non-saved changes
        [self.fractal.managedObjectContext rollback];
    }
    
    [super viewWillDisappear:animated];
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
    
    NSUInteger changeCount = 0;
    if ([object isKindOfClass:[NSManagedObject class]])
    {
        NSDictionary* changes = [object changedValuesForCurrentEvent];
        changeCount = changes.count;
    }
    if ([keyPath isEqualToString: kLibrarySelectionKeypath] && object == self.libraryViewController)
    {
        
        self.fractal = self.libraryViewController.selectedFractal;
        
    }
    else if ([[LSFractal redrawProperties] containsObject: keyPath])
    {
        
        if (changeCount)
        {
            [self queueFractalImageUpdates];
            [self updateInterface];
        }
        
    }
    else if ([[LSFractal appearanceProperties] containsObject: keyPath])
    {
        
        if (changeCount)
        {
            [self queueFractalImageUpdates];
            [self updateInterface];
        }
        
    }
    else if ([[LSFractal productionRuleProperties] containsObject: keyPath] ||
             [keyPath isEqualToString: [LSReplacementRule rulesKey]] ||
             [keyPath isEqualToString: [LSReplacementRule contextRuleKey]])
    {
        
        if (changeCount)
        {
            [self regenerateLevels];
            [self updateInterface];
        }
        
        //    } else if ([[LSFractal labelProperties] containsObject: keyPath]){
        //        [self reloadLabels];
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

-(void) setLibraryViewController:(MBFractalLibraryViewController *)libraryViewController
{
    if (_libraryViewController!=libraryViewController)
    {
        if (_libraryViewController!=nil)
        {
            [_libraryViewController removeObserver: self forKeyPath: kLibrarySelectionKeypath];
        }
        _libraryViewController = libraryViewController;
        if (_libraryViewController != nil)
        {
            [_libraryViewController addObserver: self forKeyPath: kLibrarySelectionKeypath options: 0 context: NULL];
        }
    }
}
-(UIViewController*) libraryViewController
{
    if (_libraryViewController==nil)
    {
        [self setLibraryViewController: [self.storyboard instantiateViewControllerWithIdentifier:@"LibraryPopover"]];
        [_libraryViewController setPreferredContentSize: CGSizeMake(510, 600)];
        _libraryViewController.modalPresentationStyle = UIModalPresentationPopover;
        _libraryViewController.popoverPresentationController.delegate = self;
    }
    return _libraryViewController;
}
-(UIViewController*) appearanceViewController
{
    if (_appearanceViewController==nil)
    {
        MBFractalAppearanceEditorViewController* viewController = (MBFractalAppearanceEditorViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"AppearancePopover"];
        viewController.portraitSize = self.popoverPortraitSize;
        viewController.landscapeSize = self.popoverLandscapeSize;
        
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.popoverPresentationController.passthroughViews = @[ self.fractalViewRoot,
                                                                           self.fractalViewHolder,
                                                                           self.hudViewBackground,
                                                                           self.hudLevelStepper,
                                                                           self.fractalViewLevel0,
                                                                           self.fractalViewLevel1,
                                                                           self.fractalViewLevel2];
#pragma message "TODO missing self.fractalView as a passthrough above?"
        viewController.popoverPresentationController.delegate = self;
        _appearanceViewController = viewController;
    }
    
    CGSize viewSize = self.view.bounds.size;
    if (viewSize.height > viewSize.width)
    {
        // portrait
        _appearanceViewController.preferredContentSize = _appearanceViewController.portraitSize;
    } else
    {
        // landscape
        _appearanceViewController.preferredContentSize = _appearanceViewController.landscapeSize;
    }
    
    return _appearanceViewController;
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
//TODO: change so replacementRulesArray is cached and updated when rules are updated.
/*
 If the passed fractal a read-only instance,
 create a read-write copy of the passed fractal.
 
 Id there  method for copying a fractal? Should be just [fractal mutableCopy]
 */
-(void) setFractal:(LSFractal *)fractal
{
    if (_fractal != fractal)
    {
        //        if ([fractal.isImmutable boolValue]){
        //            fractal = [fractal mutableCopy];
        //        }
        
        [self.privateImageGenerationQueue cancelAllOperations];
        
        [self removeObserversForFractal: _fractal];
        
        self.autoscaleN = YES;
        self.hudLevelStepper.maximumValue = kHudLevelStepperDefaultMax;
        
        _fractal = fractal;
        
        _privateFractalContext = [[NSManagedObjectContext alloc]initWithConcurrencyType: NSPrivateQueueConcurrencyType];
        _privateFractalContext.parentContext = _fractal.managedObjectContext;
        _fractalID = _fractal.objectID;
        
        [_privateFractalContext performBlockAndWait:^{
            self->_privateQueueFractal = (LSFractal*)[self->_privateFractalContext objectWithID: self->_fractalID];
        }];
        
        [self addObserversForFractal: _fractal];
        
        
        if (_fractal != nil)
        {
            [self regenerateLevels];
            [self saveToUserPreferencesAsLastEditedFractal: fractal];
        }
        [self updateInterface];
    }
}
-(LSFractalRenderer*) fractalRendererL0
{
    if (!_fractalRendererL0)
    {
        if (self.fractal)
        {
            _fractalRendererL0 = [LSFractalRenderer newRendererForFractal: self.fractal];
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
        if (self.fractal)
        {
            _fractalRendererL1 = [LSFractalRenderer newRendererForFractal: self.fractal];
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
        if (self.fractal)
        {
            _fractalRendererL2 = [LSFractalRenderer newRendererForFractal: self.fractal];
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
        if (self.fractal)
        {
            _fractalRendererLN = [LSFractalRenderer newRendererForFractal: self.fractal];
            _fractalRendererLN.name = @"_fractalRendererLNS1";
            _fractalRendererLN.imageView = self.fractalView;
            _fractalRendererLN.pixelScale = self.fractalView.contentScaleFactor;
            _fractalRendererLN.flipY = YES;
            _fractalRendererLN.margin = 50.0;
            _fractalRendererLN.showOrigin = YES;
            _fractalRendererLN.autoscale = YES;
        }
    }
    return _fractalRendererLN;
}
-(void) addObserversForFractal:(LSFractal *)fractal
{
    if (fractal)
    {
        NSMutableSet* propertiesToObserve = [NSMutableSet setWithSet: [LSFractal productionRuleProperties]];
        [propertiesToObserve unionSet: [LSFractal appearanceProperties]];
        [propertiesToObserve unionSet: [LSFractal redrawProperties]];
        [propertiesToObserve unionSet: [LSFractal labelProperties]];
        
        for (NSString* keyPath in propertiesToObserve)
        {
            [fractal addObserver: self forKeyPath:keyPath options: 0 context: NULL];
        }
        for (LSReplacementRule* rRule in fractal.replacementRules)
        {
            [rRule addObserver: self forKeyPath: [LSReplacementRule contextRuleKey] options: 0 context: NULL];
            [rRule addObserver: self forKeyPath: [LSReplacementRule rulesKey] options: 0 context: NULL];
        }
    }
}
-(void) removeObserversForFractal:(LSFractal *)fractal
{
    if (fractal)
    {
        NSMutableSet* propertiesToObserve = [NSMutableSet setWithSet: [LSFractal productionRuleProperties]];
        [propertiesToObserve unionSet: [LSFractal appearanceProperties]];
        [propertiesToObserve unionSet: [LSFractal redrawProperties]];
        [propertiesToObserve unionSet: [LSFractal labelProperties]];
        
        for (NSString* keyPath in propertiesToObserve)
        {
            [fractal removeObserver: self forKeyPath: keyPath];
        }
        for (LSReplacementRule* rule in fractal.replacementRules)
        {
            [rule removeObserver: self forKeyPath: [LSReplacementRule contextRuleKey]];
            [rule removeObserver: self forKeyPath: [LSReplacementRule rulesKey]];
        }
    }
}
-(void) saveToUserPreferencesAsLastEditedFractal: (LSFractal*) aFractal
{
    // If the new fractal was just copied, then it has a temporary objectID and needs to be save first
    NSManagedObjectID* fractalID = aFractal.objectID;
    if (fractalID.isTemporaryID)
    {
        [aFractal.managedObjectContext save: nil];
    }
    NSURL* selectedFractalURL = [aFractal.objectID URIRepresentation];
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
    
    if (_showPerformanceData)
    {
        _renderTimeLabel.hidden = NO;
    } else
    {
        _renderTimeLabel.hidden = YES;
    }
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
    self.hudLevelStepper.value = [self.fractal.level integerValue];
    //
    self.hudText2.text =[self.twoPlaceFormatter stringFromNumber: @(degrees([self.fractal.turningAngle doubleValue]))];
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
    self.hudText1.text = [self.fractal.level stringValue];
    self.hudText2.text = [self.twoPlaceFormatter stringFromNumber: [self.fractal turningAngleAsDegrees]];
    self.turnAngleSlider.value = [[self.fractal turningAngleAsDegrees] floatValue];
    
    self.baseAngleLabel.text = [self.twoPlaceFormatter stringFromNumber: [NSNumber numberWithDouble: degrees([self.fractal.baseAngle doubleValue])]];
    self.baseAngleSlider.value = degrees([self.fractal.baseAngle doubleValue]);
    
    self.hudRandomnessLabel.text = [self.percentFormatter stringFromNumber: self.fractal.randomness];
    self.randomnessVerticalSlider.value = self.fractal.randomness.floatValue;
    
    self.hudLineAspectLabel.text = [self.twoPlaceFormatter stringFromNumber: @([self.fractal.lineWidth floatValue]/[self.fractal.lineLength floatValue])];
    self.widthDecrementVerticalSlider.value = [self.fractal.lineWidth floatValue]/[self.fractal.lineLength floatValue];
    
    self.turningAngleLabel.text = [self.twoPlaceFormatter stringFromNumber: [NSNumber numberWithDouble: degrees([self.fractal.turningAngle doubleValue])]];
    self.turnAngleSlider.value =  degrees([self.fractal.turningAngle doubleValue]);
    
    double turnAngleChangeInDegrees = degrees([self.fractal.turningAngleIncrement doubleValue] * [self.fractal.turningAngle doubleValue]);
    self.turnAngleIncrementLabel.text = [self.twoPlaceFormatter stringFromNumber: [NSNumber numberWithDouble: turnAngleChangeInDegrees]];
    
    self.hudLineIncrementLabel.text = [self.percentFormatter stringFromNumber: self.fractal.lineChangeFactor];
    self.lengthIncrementVerticalSlider.value = self.fractal.lineChangeFactor.floatValue;
    
}
-(void) regenerateLevels
{
    NSManagedObjectContext* pc = self.privateFractalContext;
    NSManagedObjectID* fid = self.fractalID;
    
    [pc performBlock:^{
        [pc reset];
        LSFractal* fractal = (LSFractal*)[pc objectWithID: fid];
        fractal.rulesUnchanged = NO;
        [fractal generateLevelData];
        
        NSArray* levelDataArray = @[fractal.level0RulesCache, fractal.level1RulesCache, fractal.level2RulesCache, fractal.levelNRulesCache, fractal.levelGrowthRate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateRendererLevels: levelDataArray];
        });
    }];
}
-(NSUInteger) levelNIndex
{
    NSUInteger levelNIndex = [self.fractal.level integerValue] > 3 ? 3 : [self.fractal.level integerValue];
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
        
        NSUInteger nodeLimit = self.lowPerformanceDevice ? kLSMaxNodesLoPerf: kLSMaxNodesHiPerf;
        
        CGFloat currentNodeCount = (CGFloat)[(NSData*)self.levelDataArray[3] length];
        CGFloat estimatedNextNode = currentNodeCount * [self.levelDataArray[4] floatValue];
//        NSLog(@"growth rate %f",[self.fractal.levelGrowthRate floatValue]);
        if (estimatedNextNode > nodeLimit)
        {
            self.hudLevelStepper.maximumValue = self.hudLevelStepper.value;
        } else if (self.hudLevelStepper.maximumValue == self.hudLevelStepper.value)
        {
            self.hudLevelStepper.maximumValue = self.hudLevelStepper.value + 1;
        }
    }
}
-(void) queueFractalImageUpdates
{
    
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
    self.fractalRendererLN.autoExpand = self.autoExpandFractal;
    
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
    
    [renderer setValuesForFractal: self.fractal];
    
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
                        self.renderTimeLabel.text = [NSString localizedStringWithFormat: @"Device: %@, \tRender Time: %0.0fms, \tNodes: %lu",
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
    self.title = _fractal.name;
    self.navigationItem.title = _fractal.name;
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
    [self.fractal.managedObjectContext redo];
}

/*
 since we are using core data, all we need to do to undo all changes and cancel the edit session is not save the core data and use rollback.
 */

-(void) updateViewConstraints
{
    [super updateViewConstraints];
}

#pragma mark - Gesture & Button Actions
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
/* close any existing popover before opening a new one.
 do not open a new one if the new popover is the same as the current */
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    BOOL should = YES;
    return should;
}
/* The popover controller does not call this method in response to programmatic calls to the
 dismissPopoverAnimated: method. If you dismiss the popover programmatically, you should perform
 any cleanup actions immediately after calling the dismissPopoverAnimated: method. */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    NSLog(@"%@ Popover dismissed", popoverController.description);
}
-(void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    //    NSLog(@"%@ Popover dismissed", popoverPresentationController.description);
    self.currentPresentedController = nil;
}
-(void) handleNewPopoverRequest:(UIViewController<FractalControllerProtocol>*)newController
                         sender: (id) sender
                   otherPopover: (UIViewController<FractalControllerProtocol>*) otherController
{
    [self stopButtonPressed: nil];

    if (self.currentPresentedController != nil)
    {
        [self.currentPresentedController dismissViewControllerAnimated: YES completion:^{
            self.currentPresentedController = nil;
        }];
    }
    
    newController.fractal = self.fractal;
    newController.fractalUndoManager = self.undoManager;
    
    UIPopoverPresentationController* ppc = newController.popoverPresentationController;
    
    if ([sender isKindOfClass: [UIBarButtonItem class]])
    {
        ppc.barButtonItem = sender;
    } else
    {
        
        // imaginary button at bottom of screen/view
        //        CGRect viewBounds = self.fractalViewRoot.bounds;
        //        CGFloat bottomY = viewBounds.origin.y + viewBounds.size.height;
        //        CGFloat centerX = viewBounds.origin.x + (viewBounds.size.width / 2.0);
        //        CGFloat halfWidth = 44.0;
        //        CGFloat height = 0.0;
        //        CGRect sourceRect = CGRectMake(centerX - halfWidth, bottomY - height, 2*halfWidth, height);
        
        ppc.sourceView = sender;
        ppc.sourceRect = [sender bounds];
    }
    
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController: newController animated: YES completion: ^{
        //
        self.currentPresentedController = newController;
    }];
    
}
-(IBAction)libraryButtonPressed:(id)sender
{
    [self handleNewPopoverRequest: self.libraryViewController sender: sender otherPopover: self.appearanceViewController];
}
-(IBAction)appearanceButtonPressed:(id)sender
{
    if (self.presentedViewController == self.appearanceViewController)
    {
        [self dismissViewControllerAnimated: YES completion:^{
            self.currentPresentedController = nil;
        }];
        return;
    }
    
    if ([self.fractal.isImmutable boolValue])
    {
        self.fractal = [self.fractal mutableCopy];
    }
    
    self.appearanceViewController.popoverPresentationController.passthroughViews = @[self.fractalViewRoot,
                                                                                     self.fractalViewHolder,
                                                                                     self.hudViewBackground,
                                                                                     self.hudLevelStepper,
                                                                                     self.fractalViewLevel0,
                                                                                     self.fractalViewLevel1,
                                                                                     self.fractalViewLevel2];
    
    [self handleNewPopoverRequest: self.appearanceViewController sender: sender otherPopover: self.libraryViewController];
}
/*!
 Obsoleted by UIActivityViewController code below.
 
 @param sender share button
 */
- (IBAction)shareButtonPressed:(id)sender
{
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
    NSString* fileName = [NSString stringWithFormat: @"%@.pdf",self.fractal.name];
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
    
    UIImage* fractalImage = [self snapshot: self.fractalView];
    NSData* pngImage = UIImagePNGRepresentation(fractalImage);
    
    NSData* pdfData = [self createPDF];
    
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    // The file extension is important so that some mime magic happens!
    NSString* fileName = [NSString stringWithFormat: @"%@.pdf",self.fractal.name];
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
    
    if (self.fractal)
    {
        NSUInteger levelIndex = MIN(3, [self.fractal.level unsignedIntegerValue]);
        newRenderer = [LSFractalRenderer newRendererForFractal: self.fractal];
        newRenderer.name = name;
        newRenderer.imageView = self.fractalView;
        newRenderer.pixelScale = self.fractalView.contentScaleFactor;
        newRenderer.flipY = YES;
        newRenderer.margin = 50.0;
        newRenderer.showOrigin = YES;
        newRenderer.autoscale = YES;
        newRenderer.autoExpand = self.autoExpandFractal;
        newRenderer.levelData = self.levelDataArray[levelIndex];
    }
    return newRenderer;
}
-(void) swapOldButton: (UIBarButtonItem*)oldButton withNewButton: (UIBarButtonItem*)newButton
{
    NSArray* barItemsArray = self.navigationItem.rightBarButtonItems;
    NSUInteger buttonIndex = 0;
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
    if (!self.fractal) {
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
        
        self.playFrameIncrement = 0.5;
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
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1
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

    if (!self.playbackSlider.hidden) {
        if (self.playbackTimer)
        {
            //pause
            [self.playbackTimer invalidate];
            self.playbackTimer = nil;
        }
        
        [self queueFractalImageUpdates];
        self.playbackRenderers = nil;
        
        [self swapOldButton: self.stopButton withNewButton: self.playButton];
        self.playbackSlider.hidden = YES;
    }
}
-(IBAction) playSliderChangedValue: (UISlider*)slider
{
    self.playIsPercentCompleted = slider.value;
    [self playNextFrame: nil];
}
-(IBAction)toggleAutoExpandFractal:(id)sender
{
    self.autoExpandFractal = !self.autoExpandFractal;
    if (self.autoExpandFractal) {
        [self swapOldButton: self.autoExpandOn withNewButton: self.autoExpandOff];
    }
    else
    {
        [self swapOldButton: self.autoExpandOff withNewButton: self.autoExpandOn];
    }
    [self queueFractalImageUpdates];
}
- (IBAction)copyFractal:(id)sender
{
    // copy
    self.fractal = [self.fractal mutableCopy];
    
    [self appearanceButtonPressed: self.editButton];
}

- (IBAction)levelInputChanged:(UIControl*)sender
{
    double rawValue = [[sender valueForKey: @"value"] doubleValue];
    NSNumber* roundedNumber = @(lround(rawValue));
    self.fractal.level = roundedNumber;
    [self.activityIndicator startAnimating];
}


/* want to use 2 finger pans for changing rotation and line thickness in place of swiping
 need to lock in either horizontal or vertical panning view a state and state change */
-(IBAction)twoFingerPanFractal:(UIPanGestureRecognizer *)gestureRecognizer
{
    [self convertPanToAngleAspectChange: gestureRecognizer
                              imageView: self.fractalView
                              anglePath: @"turningAngle"
                             angleScale: 5.0/1.0
                               minAngle: -180.0
                               maxAngle:  180.0
                              angleStep:    3.0
                             aspectPath: @"lineWidth"
                            aspectScale: 1.0/100.0
                              minAspect: 0.5
                              maxAspect: 20.0];
}
- (IBAction)panLevel0:(UIPanGestureRecognizer *)sender
{
    [self convertPanToAngleAspectChange: sender
                              imageView: self.fractalViewLevel0
                              anglePath: @"baseAngle"
                             angleScale: 5.0/1.0
                               minAngle: -180.0
                               maxAngle:  180.0
                              angleStep:    5.0
                             aspectPath: @"randomness"
                            aspectScale: -1.0/1000.0
                              minAspect: 0.0
                              maxAspect: 0.20];
}
- (IBAction)panLevel1:(UIPanGestureRecognizer *)sender
{
    [self convertPanToAngleAspectChange: sender
                              imageView: self.fractalViewLevel1
                              anglePath: @"turningAngle"
                             angleScale: 1.0/10.0
                               minAngle: -180.0
                               maxAngle:  180.0
                              angleStep:    0.25
                             aspectPath:@"lineWidth"
                            aspectScale: 5.0/50.0
                              minAspect: 0.5
                              maxAspect: 60.0];
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
        
        [self.undoManager beginUndoGrouping];
        [self.fractal.managedObjectContext processPendingChanges];
        
        initialPosition = CGPointZero;//subLayer.position;
        
        if (anglePath)
        {
            initialAngleDegrees =  floorf(100.0 * degrees([[self.fractal valueForKey: anglePath] doubleValue])) / 100.0;
        }
        if (aspectPath)
        {
            initialWidth = floorf(100.0 * [[self.fractal valueForKey: aspectPath] doubleValue]) / 100.0;
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
                [self.fractal setValue: @(newWidth) forKey: aspectPath];
                //self.fractal.lineWidth = @(newidth);
                
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
                [self.fractal setValue: @(radians(newAngleDegrees)) forKey: anglePath];
                
            }
        }
        
    } else if (state == UIGestureRecognizerStateCancelled)
    {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
        
        [self.fractal setValue:  @(radians(initialAngleDegrees)) forKey: anglePath];
        //[self.fractal setTurningAngleAsDegrees:  @(initialAngleDegrees)];
        determinedState = 0;
        if ([self.undoManager groupingLevel] > 0)
        {
            [self.undoManager endUndoGrouping];
            [self.undoManager undoNestedGroup];
        }
    } else if (state == UIGestureRecognizerStateEnded)
    {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
        determinedState = 0;
        [self saveContext];
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
-(void) fullScreenOn
{
    //    [self moveEditorHeightTo: 0];
    [UIView animateWithDuration:0.5
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
- (UIImage *)snapshot:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    [view drawViewHierarchyInRect: view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
-(NSData*) createPDF
{
    CGRect imageBounds = CGRectMake(0, 0, 1024, 1024);
    
    LSFractalRenderer* renderer = [LSFractalRenderer newRendererForFractal: self.fractal];
    renderer.levelData = self.levelDataArray[3];
    renderer.name = @"PDF renderer";
    renderer.margin = 72.0;
    renderer.autoscale = YES;
    renderer.flipY = YES;
    
    NSMutableData* pdfData = [NSMutableData data];
    NSDictionary* pdfMetaData = @{(NSString*)kCGPDFContextCreator:@"FractalScape", (NSString*)kCGPDFContextTitle:self.fractal.name, (NSString*)kCGPDFContextKeywords:self.fractal.category};
    
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
        
        UIImage* fractalImage = [self snapshot: self.fractalView];
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
                                         (NSString *)kCGImagePropertyExifUserComment:self.fractal.name,
                                         (NSString *)kCGImagePropertyExifLensMake:@"FractalScape",
                                         (NSString *)kCGImagePropertyExifLensModel:version};
        
        // Tiff metadata dictionary
        // Includes information about the application used to create the image
        // "Make" is the name of the app, "Model" is the version of the app
        NSMutableDictionary *tiffDictionary = [NSMutableDictionary dictionary];
        [tiffDictionary setValue:now forKey:(NSString *)kCGImagePropertyTIFFDateTime];
        [tiffDictionary setValue:@"FractalScape" forKey:(NSString *)kCGImagePropertyTIFFMake];
        [tiffDictionary setValue:self.fractal.name forKey:(NSString *)kCGImagePropertyTIFFDocumentName];
        [tiffDictionary setValue:self.fractal.descriptor forKey:(NSString *)kCGImagePropertyTIFFImageDescription];
        
        [tiffDictionary setValue:[NSString stringWithFormat:@"%@ (%@)", version, build] forKey:(NSString *)kCGImagePropertyTIFFModel];
        
        NSDictionary* pngDictionary = @{(NSString *)kCGImagePropertyPNGDescription:self.fractal.descriptor,
                                        (NSString *)kCGImagePropertyPNGTitle:self.fractal.name,
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
            
            NSLog(@"Sharing to camera status %@.", error);
        }];
        
        //        [library writeImageToSavedPhotosAlbum: [fractalImage CGImage] orientation: ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error){
        //            // call method for UIAlert about successful save with save text
        //            [self showSharedCompletionAlertWithText: @"your camera roll." error: error];
        //
        //            NSLog(@"Sharing to camera status %@.", error);
        //        }];
    }
    
    NSLog(@"Sharing to camera called.");
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
#pragma mark - control actions
- (IBAction)incrementLineWidth:(id)sender
{
    if ([self.fractal.isImmutable boolValue])
    {
        self.fractal = [self.fractal mutableCopy];
    }
    double width = [self.fractal.lineWidth doubleValue];
    double increment = [self.fractal.lineWidthIncrement doubleValue];
    
    [self.undoManager beginUndoGrouping];
    self.fractal.lineWidth = @(fmax(width+increment, 1.0));
}

- (IBAction)decrementLineWidth:(id)sender
{
    double width = [self.fractal.lineWidth doubleValue];
    double increment = [self.fractal.lineWidthIncrement doubleValue];
    
    [self.undoManager beginUndoGrouping];
    self.fractal.lineWidth = @(fmax(width-increment, 1.0));
}

//TODO: User preference for turnAngle swipe increment
//Obsolete replaced with 2 finger pan
- (IBAction)incrementTurnAngle:(id)sender
{
    [self.undoManager beginUndoGrouping];
    [self.fractal.managedObjectContext processPendingChanges];
    [self.fractal setTurningAngleAsDegrees:  @([self.fractal.turningAngleAsDegrees doubleValue] + 0.5)];
}
- (IBAction)decrementTurnAngle:(id)sender
{
    [self.undoManager beginUndoGrouping];
    [self.fractal.managedObjectContext processPendingChanges];
    [self.fractal setTurningAngleAsDegrees:  @([self.fractal.turningAngleAsDegrees doubleValue] - 0.5)];
}

// TODO: copy app delegate saveContext method

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
    if (self.fractal.managedObjectContext.undoManager == nil)
    {
        
        NSUndoManager *anUndoManager = [[NSUndoManager alloc] init];
        [anUndoManager setLevelsOfUndo:50];
        [anUndoManager setGroupsByEvent: NO];
        _undoManager = anUndoManager;
        
        self.fractal.managedObjectContext.undoManager = _undoManager;
    }
    
    // Register as an observer of the book's context's undo manager.
    NSUndoManager *fractalUndoManager = self.fractal.managedObjectContext.undoManager;
    
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(undoManagerDidUndo:) name:NSUndoManagerDidUndoChangeNotification object:fractalUndoManager];
    [dnc addObserver:self selector:@selector(undoManagerDidRedo:) name:NSUndoManagerDidRedoChangeNotification object:fractalUndoManager];
}


- (void)cleanUpUndoManager
{
    
    // Remove self as an observer.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.fractal.managedObjectContext.undoManager == _undoManager)
    {
        self.fractal.managedObjectContext.undoManager = nil;
        _undoManager = nil;
    }
}


- (void)undoManagerDidUndo:(NSNotification *)notification
{
    [self updateInterface];
}


- (void)undoManagerDidRedo:(NSNotification *)notification
{
    [self updateInterface];
}
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.fractal.managedObjectContext;
    if (managedObjectContext != nil)
        
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
            
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma Utilities

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

-(void) dealloc
{
    self.fractal = nil; // removes observers via custom setter call
}

@end
