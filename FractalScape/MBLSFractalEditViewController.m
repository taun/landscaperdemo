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
#import "MBFractalAxiomEditViewController.h"
#import "MBFractalAppearanceEditorViewController.h"
#import "MBFractalLineSegmentsEditorViewController.h"
#import "FractalControllerProtocol.h"
#import "LSReplacementRule.h"
//#import "MBLSFractalLevelNView.h"
#import "LSFractal+addons.h"
#import "LSFractalGenerator.h"
#import "MBColor+addons.h"

#import "MBPortalStyleView.h"


#import <QuartzCore/QuartzCore.h>

#include <math.h>
//
//static inline double radians (double degrees) {return degrees * M_PI/180.0;}
//static inline double degrees (double radians) {return radians * 180.0/M_PI;}
#define LOGBOUNDS 0

static NSString* kLibrarySelectionKeypath = @"selectedFractal";
static BOOL SIMULTOUCH = NO;

@interface MBLSFractalEditViewController ()

@property (nonatomic, assign) BOOL                  startedInLandscape;

//@property (nonatomic, strong) NSSet*                editControls;
//@property (nonatomic, strong) NSMutableArray*       cachedEditViews;
//@property (nonatomic, assign) NSInteger             cachedEditorsHeight;

@property (nonatomic, assign) double                viewNRotationFromStart;

@property (nonatomic, strong) UIBarButtonItem*      cancelButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      undoButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      redoButtonItem;

@property (nonatomic,weak) UIViewController*        currentPresentedController;

@property (nonatomic,assign,getter=isCancelled) BOOL cancelled;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) CALayer *fractalLevel0Layer;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) CALayer *fractalLevel1Layer;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) CALayer *fractalLevel2Layer;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) CALayer *fractalLevelNLayer;

-(void) saveToUserPreferencesAsLastEditedFractal: (LSFractal*) fractal;
-(void) updateGeneratorsForFractal: (LSFractal*) fractal;
-(void) addObserversForFractal: (LSFractal*) fractal;
-(void) removeObserversForFractal: (LSFractal*) fractal;

//-(void) setEditMode: (BOOL) editing;
-(void) updateViewsForEditMode: (BOOL) editing;
-(void) moveEditorHeightTo: (NSInteger) height;
-(void) fullScreenOn;
-(void) fullScreenOff;

-(void) useFractalDefinitionRulesView;
-(void) useFractalDefinitionAppearanceView;
//-(void) loadDefinitionViews;

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
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void) awakeFromNib {
    [super awakeFromNib];
}

#pragma mark - UIViewController Methods
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
//    [self setPopover: nil];
//    [self setLibraryViewController: nil];
//    [self setPropertiesViewController: nil];
//    [self setAppearanceViewController: nil];
}

/*
 should only be called by viewDidLoad
 */
//-(void) __savePortraitViewFrames {
//    // This is only called when the nib is first loaded and the views have not been resized.
//    double barHeight = self.navigationController.navigationBar.frame.size.height;
//    
//    double topMargin = 0;
//    
//    if (UIDeviceOrientationIsLandscape(self.interfaceOrientation)) {
//        self.startedInLandscape = YES;
//        // remove extra 20 pixels added when started in landscape but getting nib dimensions before autolayout.
//        topMargin = 20.0;
//    } else {
//        self.startedInLandscape = NO;
//    }
//    
//    CGRect frame = self.fractalView.superview.frame;
//    //        CGRect frameNLessNav = CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height-barHeight-MBPORTALMARGIN);
//    CGRect frameNLessNav = CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height-barHeight-MBPORTALMARGIN-topMargin);
//    NSDictionary* frame0 = (__bridge_transfer NSDictionary*) CGRectCreateDictionaryRepresentation(self.fractalViewLevel0.superview.frame);
//    NSDictionary* frame1 = (__bridge_transfer NSDictionary*) CGRectCreateDictionaryRepresentation(self.fractalViewLevel1.superview.frame);
//    NSDictionary* frameN = (__bridge_transfer NSDictionary*) CGRectCreateDictionaryRepresentation(frameNLessNav);
//    
//    self.portraitViewFrames = @{@"frame0": frame0, @"frame1": frame1, @"frameN": frameN};
//    NSLog(@"%@ setPortraitViewFrames frame0 = %@; frame1 = %@; frameN = %@;", NSStringFromSelector(_cmd), frame0, frame1, frameN);
//    
//}

-(void)viewDidLoad {
    
    [super viewDidLoad];
        
    UIImage* patternImage = [UIImage imageNamed: @"linen-fine.jpg"];
    UIColor* newColor = [UIColor colorWithPatternImage: patternImage];
    self.fractalViewRoot.backgroundColor = newColor;
        
//    if (self.portraitViewFrames == nil) {
//        // we want to save the frames as layed out in the nib.
//        [self __savePortraitViewFrames];
//    }

//    [self.fractalPanGR requireGestureRecognizerToFail: self.fractalRightSwipeGR];//obsolete replace with 2 finger pan
//    [self.fractalPanGR requireGestureRecognizerToFail: self.fractalLeftSwipeGR];
//    [self.fractalPanGR requireGestureRecognizerToFail: self.fractalUpSwipeGR];
//    [self.fractalPanGR requireGestureRecognizerToFail: self.fractalDownSwipeGR];
//    [self.fractal2PanGR requireGestureRecognizerToFail: self.fractalPinchGR];
//    [self.fractal2PanGR requireGestureRecognizerToFail: self.fractalRotationGR];
}

/*!
 Initial view autolayout of the nib is done between viewDidLoad and viewWillAppear.
 viewDiDLoad has the nib view size without a toolbar
 viewWillAppear has the nib view after being resized.
 
 viewDidLoad is portrait but 20 pixels taller when started in landscape orientation.
 Does not become landscape until viewWillAppear.
 */
//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//
//    [self setEditMode: YES];
//}

/*
 
 */
-(void) viewWillLayoutSubviews {
    //    [self updateViewsForEditMode: self.editing];
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
-(void) viewDidLayoutSubviews {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    [self autoScale: nil];
        
    if (!self.editing) {
        [self fitLayer: [self fractalLevel0Layer] inLayer: self.fractalViewLevel0.superview.layer margin: 5];
        [self fitLayer: [self fractalLevel1Layer] inLayer: self.fractalViewLevel1.superview.layer margin: 5];
        [self fitLayer: [self fractalLevel2Layer] inLayer: self.fractalViewLevel2.superview.layer margin: 5];
    }
}

-(void) viewWillAppear:(BOOL)animated {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    //    self.editing = NO;
    [super viewWillAppear:animated];
    
}

/* on staartup, fractal should not be set until just before view didAppear */
-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self refreshContents];

    self.editing = YES;
}

-(void)viewWillDisappear:(BOOL)animated {
    
    if (self.editing) {
        [self.fractal.managedObjectContext save: nil];
        [self setUndoManager: nil];
    } else {
        // undo all non-saved changes
        [self.fractal.managedObjectContext rollback];
    }
    //	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


// TODO: generate a thumbnail whenever saving. add thumbnails to coreData
-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [UIView transitionWithView: self.view
                      duration:0.5
                       options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{ [self updateViewsForEditMode: editing]; }
                    completion:^(BOOL finished){ [self autoScale:nil]; }];
    
    //    [self updateViewsForEditMode: editing];
    
    [super setEditing:editing animated:animated];
    
    /*
     When editing starts, create and set an undo manager to track edits. Then register as an observer of undo manager change notifications, so that if an undo or redo operation is performed, the table view can be reloaded.
     When editing ends, de-register from the notification center and remove the undo manager, and save the changes.
     */
    if (editing) {
        // reset cancelled status
        self.cancelled = NO;
        
        [self.undoManager beginUndoGrouping];
        
        
    } else {
        
        //[self.undoManager endUndoGrouping];
        
        if (self.isCancelled) {
            //            NSManagedObjectID* objectID = self.currentFractal.objectID;
            //            NSManagedObjectContext* moc = self.currentFractal.managedObjectContext;
            
            [self.fractal.managedObjectContext rollback];
            self.cancelled = NO;
            // reload fractal from store.
            //            self.currentFractal = (LSFractal*)[moc objectRegisteredForID: objectID];
        } else {
            // Save the changes.
            NSError *error;
            if (![self.fractal.managedObjectContext save:&error]) {
                // Update to handle the error appropriately.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                // exit(-1);  // Fail
                // TODO: alert here?
                
            }
        }
        [self.undoManager removeAllActions];
        [self setUndoManager: nil];
        [self becomeFirstResponder];
    }
    
    [self refreshContents];
    // Hide the back button when editing starts, and show it again when editing finishes.
    [self.navigationItem setHidesBackButton:editing animated:animated];
    
//    [self setEditMode: editing];
//    [self.fractalPropertiesTableView setEditing: editing animated: animated];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    // Return YES for supported orientations
	return YES;
}
-(void) refreshInterface {
    [self refreshValueInputs];
    [self refreshLayers];
}
// TODO: Check for fractal name change to update window title
/* observer fractal.replacementRules */
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: kLibrarySelectionKeypath] && object == self.libraryViewController) {
        
        self.fractal = self.libraryViewController.selectedFractal;
        
    } else if ([[LSFractal productionRuleProperties] containsObject: keyPath]) {
        
        [self refreshInterface];
        
    } else if ([[LSFractal appearanceProperties] containsObject: keyPath]) {
        
        [self refreshInterface];
        
//    } else if ([[LSFractal labelProperties] containsObject: keyPath]) {
//        [self reloadLabels];
    } else if ([keyPath isEqualToString: @"name"]) {
        [self configureNavButtons];
                
    } else if ([keyPath isEqualToString: @"category"]) {
        
    } else if ([keyPath isEqualToString: @"descriptor"]) {
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    [self updateUndoRedoBarButtonState];
}

#pragma mark - Getters & Setters

-(void) setLibraryViewController:(MBFractalLibraryViewController *)libraryViewController {
    if (_libraryViewController!=libraryViewController) {
        if (_libraryViewController!=nil) {
            [_libraryViewController removeObserver: self forKeyPath: kLibrarySelectionKeypath];
        }
        _libraryViewController = libraryViewController;
        if (_libraryViewController != nil) {
            [_libraryViewController addObserver: self forKeyPath: kLibrarySelectionKeypath options: 0 context: NULL];
        }
    }
}
-(UIViewController*) libraryViewController {
    if (_libraryViewController==nil) {
        [self setLibraryViewController: [self.storyboard instantiateViewControllerWithIdentifier:@"LibraryPopover"]];
        [_libraryViewController setPreferredContentSize: CGSizeMake(510, 600)];
        _libraryViewController.modalPresentationStyle = UIModalPresentationPopover;
        _libraryViewController.popoverPresentationController.delegate = self;
    }
    return _libraryViewController;
}
-(UIViewController*) appearanceViewController {
    if (_appearanceViewController==nil) {
        _appearanceViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AppearancePopover"];
        [_appearanceViewController setPreferredContentSize: CGSizeMake(400, 408)];
        _appearanceViewController.modalPresentationStyle = UIModalPresentationPopover;
        _appearanceViewController.popoverPresentationController.passthroughViews = @[self.fractalViewLevel0,
                                                                                     self.fractalViewLevel1,
                                                                                     self.fractalViewLevel2];
        _appearanceViewController.popoverPresentationController.delegate = self;
    }
    return _appearanceViewController;
}

//-(UIActionSheet*) shareActionsSheet {
//    if (_shareActionsSheet==nil) {
//        _shareActionsSheet = [[UIActionSheet alloc] initWithTitle: nil
//                                                         delegate: self
//                                                cancelButtonTitle: nil
//                                           destructiveButtonTitle: nil
//                                                otherButtonTitles: @"Save to camera roll", @"Share to public Cloud",nil];
//    }
//    return _shareActionsSheet;
//}
//enum AppearanceIndex {
//    TurningAngle=0,
//    TurningAngleIncrement,
//    LineWidth,
//    LineWidthIncrement,
//    LineLengthScaleFactor
//};
-(NSMutableArray*) generatorsArray {
    if (_generatorsArray == nil) {
        _generatorsArray = [[NSMutableArray alloc] initWithCapacity: 3];
    }
    return _generatorsArray;
}

-(NSMutableArray*) fractalDisplayLayersArray {
    if (_fractalDisplayLayersArray == nil) {
        _fractalDisplayLayersArray = [[NSMutableArray alloc] initWithCapacity: 3];
    }
    return _fractalDisplayLayersArray;
}

//-(NSMutableArray*) cachedEditViews {
//    if (_cachedEditViews==nil) {
//        _cachedEditViews = [[NSMutableArray alloc] initWithCapacity: 3];
//    }
//    return _cachedEditViews;
//}


#pragma message "Unused"
-(UIBarButtonItem*) cancelButtonItem {
    if (_cancelButtonItem == nil) {
        _cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel 
                                                                          target:self 
                                                                          action:@selector(cancelEdit:)];
        
    }
    return _cancelButtonItem;
}
#pragma message "Unused"
-(UIBarButtonItem*) undoButtonItem {
    if (_undoButtonItem == nil) {
        _undoButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemUndo 
                                                                        target:self 
                                                                        action:@selector(undoEdit:)];
    }
    return _undoButtonItem;
}

#pragma message "Unused"
-(UIBarButtonItem*) redoButtonItem {
    if (_redoButtonItem == nil) {
        _redoButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRedo 
                                                                        target:self 
                                                                        action:@selector(redoEdit:)];
    }
    return _redoButtonItem;
}

#pragma message "Unused"
-(UIBarButtonItem*) spaceButtonItem {
    if (_spaceButtonItem == nil) {
        _spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace
                                                                         target:self
                                                                         action:nil];
        _spaceButtonItem.width = 10.0;
    }
    return _spaceButtonItem;
}

//-(UIPopoverController*) colorPopover {
//    if (_colorPopover == nil) {
//        UIColor* color = [self.currentFractal lineColorAsUI];
//        ColorPickerController* colorPicker = [[ColorPickerController alloc] initWithColor: color andTitle: @"Pick a Fill Color"];
//        colorPicker.delegate = self;
//        colorPicker.contentSizeForViewInPopover = CGSizeMake(400, 300);
//
//        UINavigationController* navCon = [[UINavigationController alloc] initWithRootViewController: colorPicker];
//        
//        navCon.contentSizeForViewInPopover = CGSizeMake(400, 300);
//        navCon.modalInPopover = YES;
//        
//        _colorPopover = [[UIPopoverController alloc] initWithContentViewController: navCon];
//        _colorPopover.delegate = (id<UIPopoverControllerDelegate>)self;
//        _colorPopover.popoverContentSize = CGSizeMake(400, 300);
//    }
//    return _colorPopover;
//}

//-(NSSet*) editControls {
//    if (_editControls == nil) {
//        _editControls = [[NSSet alloc] initWithObjects: 
//                         self.fractalName,
//                         self.fractalCategory,
//                         self.fractalDescriptor,
//                         nil];
////                         self.levelSlider,
////                         self.lineLengthStepper,
////                         self.turnAngleStepper,
////                         self.widthStepper,
////                         self.widthSlider,
////                         self.strokeSwitch,
////                         self.strokeColorButton,
////                         self.fillSwitch,
////                         self.fillColorButton,
////                         self.fractalAxiom,
////                         self.levelStepper,
//    }
//    return _editControls;
//}

-(void) setHudViewBackground: (UIView*) hudViewBackground {
    if (_hudViewBackground != hudViewBackground) {
        _hudViewBackground = hudViewBackground;
        
        CALayer* background = _hudViewBackground.layer;
        
        background.cornerRadius = HUD_CORNER_RADIUS;
        background.borderWidth = 1.6;
        background.borderColor = [UIColor grayColor].CGColor;
        
        background.shadowOffset = CGSizeMake(0, 3.0);
        background.shadowOpacity = 0.6;
    }
}

//-(void) setSliderContainerView:(UIView *)sliderContainerView {
//    if (_sliderContainerView != sliderContainerView) {
//        _sliderContainerView = sliderContainerView;
//        //        CGAffineTransform rotateCC = CGAffineTransformMakeRotation(-M_PI_2);
//        //        [_sliderContainerView setTransform: rotateCC];
//    }
//}

//-(void) setFractalView:(UIView *)fractalView {
//    if (_fractalView != fractalView) {
//        _fractalView = fractalView;
//        
//        UIRotationGestureRecognizer* rgr = [[UIRotationGestureRecognizer alloc]
//                                            initWithTarget: self
//                                            action: @selector(rotateFractal:)];
//        
//        [_fractalView addGestureRecognizer: rgr];
//        
//        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]
//                                                  initWithTarget:self
//                                                  action:@selector(scaleFractal:)];
//        
//        [pinchGesture setDelegate:self];
//        [_fractalView addGestureRecognizer: pinchGesture];
//        
//        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
//                                              initWithTarget:self
//                                              action:@selector(panFractal:)];
//        
//        panGesture.maximumNumberOfTouches = 1;
//        [panGesture setDelegate:self];
//        
//        [_fractalView addGestureRecognizer: panGesture];
//        
//        UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc]
//                                                       initWithTarget:self
//                                                       action:@selector(swipeFractal:)];
//        
//        rightSwipeGesture.numberOfTouchesRequired = 2;
//        rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
//        [rightSwipeGesture setDelegate:self];
//        
//        [_fractalView addGestureRecognizer: rightSwipeGesture];
//        
//        UISwipeGestureRecognizer *leftSwipeGesture = [[UISwipeGestureRecognizer alloc]
//                                                      initWithTarget:self
//                                                      action:@selector(swipeFractal:)];
//        
//        leftSwipeGesture.numberOfTouchesRequired = 2;
//        leftSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
//        [leftSwipeGesture setDelegate:self];
//        
//        [_fractalView addGestureRecognizer: leftSwipeGesture];
//        
//        [self setupLevelGeneratorForView: _fractalView name: @"fractalLevelN" forceLevel: -1];
//    }
//}

-(CALayer*) fractalLevel0Layer {
    CALayer* subLayer;
    for (CALayer* layer in self.fractalView.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevel0"]) {
            subLayer = layer;
        }
    }
    return subLayer;
}
-(CALayer*) fractalLevel1Layer {
    CALayer* subLayer;
    for (CALayer* layer in self.fractalView.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevel1"]) {
            subLayer = layer;
        }
    }
    return subLayer;
}
-(CALayer*) fractalLevel2Layer {
    CALayer* subLayer;
    for (CALayer* layer in self.fractalView.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevel2"]) {
            subLayer = layer;
        }
    }
    return subLayer;
}
-(CALayer*) fractalLevelNLayer {
    CALayer* subLayer;
    for (CALayer* layer in self.fractalView.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevelN"]) {
            subLayer = layer;
        }
    }
    return subLayer;
}


#pragma mark Fractal Property KVO
//TODO: change so replacementRulesArray is cached and updated when rules are updated.
/*
 If the passed fractal a read-only instance,
 create a read-write copy of the passed fractal.
 
 Id there  method for copying a fractal? Should be just [fractal mutableCopy]
 */
-(void) setFractal:(LSFractal *)fractal {
    if (_fractal != fractal) {
//        if ([fractal.isImmutable boolValue]) {
//            fractal = [fractal mutableCopy];
//        }

        [self removeObserversForFractal: _fractal];
        _fractal = fractal;
        [self addObserversForFractal: _fractal];

        [self updateGeneratorsForFractal: _fractal];
        
        if (_fractal != nil) {
            [self saveToUserPreferencesAsLastEditedFractal: fractal];
        }
        [self refreshContents];
    }
}
-(LSFractal*) fractal {
    return _fractal;
}
-(void) addObserversForFractal:(LSFractal *)fractal {
    if (fractal) {
        NSSet* propertiesToObserve = [[LSFractal productionRuleProperties] setByAddingObjectsFromSet:[LSFractal appearanceProperties]];
        propertiesToObserve = [propertiesToObserve setByAddingObjectsFromSet: [LSFractal labelProperties]];
        for (NSString* keyPath in propertiesToObserve) {
            [fractal addObserver: self forKeyPath:keyPath options: 0 context: NULL];
        }
        for (LSReplacementRule* rule in fractal.replacementRules) {
            NSString* keyPath = [NSString stringWithFormat: @"replacementString"];
            [rule addObserver: self forKeyPath: keyPath options: 0 context: NULL];
        }
    }
}
-(void) removeObserversForFractal:(LSFractal *)fractal {
    if (fractal) {
        NSSet* propertiesToObserve = [[LSFractal productionRuleProperties] setByAddingObjectsFromSet:[LSFractal appearanceProperties]];
        propertiesToObserve = [propertiesToObserve setByAddingObjectsFromSet: [LSFractal labelProperties]];
        for (NSString* keyPath in propertiesToObserve) {
            [fractal removeObserver: self forKeyPath: keyPath];
        }
        for (LSReplacementRule* rule in fractal.replacementRules) {
            NSString* keyPath = [NSString stringWithFormat: @"replacementString"];
            [rule removeObserver: self forKeyPath: keyPath];
        }
    }
}
-(void) updateGeneratorsForFractal:(LSFractal *)fractal {
    if (fractal) {
        // If the generators have been created, the fractal needs to be replaced.
        if ([self.generatorsArray count] > 0) {
            for (LSFractalGenerator* generator in self.generatorsArray) {
                generator.fractal = fractal;
            }
        } else {
            [self setupLevelGeneratorForFractal: fractal View: self.fractalView name: @"fractalLevelN" forceLevel: -1];
            [self setupLevelGeneratorForFractal: fractal View: self.fractalViewLevel0 name: @"fractalLevel0" forceLevel: 0];
            [self setupLevelGeneratorForFractal: fractal View: self.fractalViewLevel1 name: @"fractalLevel1" forceLevel: 1];
            [self setupLevelGeneratorForFractal: fractal View: self.fractalViewLevel2 name: @"fractalLevel2" forceLevel: 2];
        }
    }
}
-(void) saveToUserPreferencesAsLastEditedFractal: (LSFractal*) fractal {
    // If the new fractal was just copied, then it has a temporary objectID and needs to be save first
    NSManagedObjectID* fractalID = fractal.objectID;
    if (fractalID.isTemporaryID) {
        [fractal.managedObjectContext save: nil];
    }
    NSURL* selectedFractalURL = [fractal.objectID URIRepresentation];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setURL: selectedFractalURL forKey: kLastEditedFractalURI];
}
-(void) fitLayer: (CALayer*) layerInner inLayer: (CALayer*) layerOuter margin: (double) margin {
    
    CGRect boundsOuter = layerOuter.bounds;
    
    CGRect boundsInner = CGRectInset(boundsOuter, margin, margin);
    
    layerInner.bounds = boundsInner;
    layerInner.position = CGPointMake(boundsOuter.size.width/2, boundsOuter.size.height/2);
}

-(void) setupLevelGeneratorForFractal: (LSFractal*) fractal View: (UIView*) aView name: (NSString*) name forceLevel: (NSInteger) aLevel {
    CALayer* aLayer = [[CALayer alloc] init];
    aLayer.name = name;
    aLayer.needsDisplayOnBoundsChange = YES;
    aLayer.speed = 1.0;
    aLayer.drawsAsynchronously = YES;
    aLayer.contentsScale = 2.0 * aView.layer.contentsScale;
    
    [self fitLayer: aLayer inLayer: aView.layer margin: 10];
    [aView.layer addSublayer: aLayer];
    
    
    LSFractalGenerator* generator = [[LSFractalGenerator alloc] init];
    
    if (generator) {
        NSUInteger arrayCount = [self.generatorsArray count];
        
        generator.fractal = fractal;
        generator.forceLevel = aLevel;
        
        aLayer.delegate = generator;
        [aLayer setValue: [NSNumber numberWithInteger: arrayCount] forKey: @"arrayCount"];
        
        [self.fractalDisplayLayersArray addObject: aLayer];
        [self.generatorsArray addObject: generator];
    }
}

#pragma mark - view utility methods

//-(void) reloadLabels {
//    self.fractalName.text = self.fractal.name;
//    self.fractalCategory.text = self.fractal.category;
//    self.fractalDescriptor.text = self.fractal.descriptor;
//}

-(void) refreshValueInputs {    
    //    self.fractalAxiom.text = self.currentFractal.axiom;
    //    
    //    self.fractalLineLength.text =  [self.currentFractal.lineLength stringValue];
    //    self.lineLengthStepper.value = [self.currentFractal.lineLength doubleValue];
    //    
    //    self.fractalWidth.text =  [self.currentFractal.lineWidth stringValue];
    //    self.widthStepper.value = [self.currentFractal.lineWidth doubleValue];
    //    self.widthSlider.value = [self.currentFractal.lineWidth doubleValue];
    //    
    //    self.fractalTurningAngle.text = [self.twoPlaceFormatter stringFromNumber: [self.currentFractal turningAngleAsDegree]];
    
    //    
    //    self.fractalLevel.text = [self.currentFractal.level stringValue];
    //    self.levelStepper.value = [self.currentFractal.level doubleValue];
    self.hudLevelStepper.value = [self.fractal.level integerValue];
    //    
    //    self.strokeSwitch.on = [self.currentFractal.stroke boolValue];
    //    self.fillSwitch.on = [self.currentFractal.fill boolValue];
    self.hudText2.text =[self.twoPlaceFormatter stringFromNumber: [self.fractal turningAngleAsDegree]];
}

-(void) refreshLayers {
    self.hudText1.text = [self.fractal.level stringValue];
    self.hudText2.text = [self.twoPlaceFormatter stringFromNumber: [self.fractal turningAngleAsDegree]];
    
    //    [self logBounds: self.fractalViewLevelN.bounds info: @"fractalViewN Bounds"];
    //    [self logBounds: self.fractalViewLevelN.layer.bounds info: @"fractalViewN Layer Bounds"];
    
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.contents = nil;
        //        [self logBounds: layer.bounds info: @"newLayer Bounds"];
        [layer setNeedsLayout];
        [layer layoutIfNeeded];
        //        [self logBounds: layer.bounds info: @"newLayer Bounds"];
        [layer setNeedsDisplay];
    }
}

-(void) refreshContents {
//    [self reloadLabels];
    [self refreshValueInputs];
    [self refreshLayers];
    [self configureNavButtons];
}

//-(void) loadDefinitionViews {
//    [[NSBundle mainBundle] loadNibNamed: @"FractalDefinitionRulesView" owner: self options: nil];
//    [[NSBundle mainBundle] loadNibNamed: @"FractalDefinitionAppearanceView" owner: self options: nil];
//}

-(void) useFractalDefinitionRulesView {
    
    if (self.fractalDefinitionAppearanceView.superview == nil) {
        [self.fractalDefinitionPlaceholderView addSubview: self.fractalDefinitionRulesView];
    } else {
        [UIView transitionFromView: self.fractalDefinitionAppearanceView 
                            toView: self.fractalDefinitionRulesView 
                          duration: 0.3 
                           options: UIViewAnimationOptionTransitionFlipFromLeft 
                        completion: NULL];
    }
    //    self.fractalDefinitionRulesView.center = self.placeHolderCenter;
    //    self.fractalDefinitionRulesView.bounds = self.placeHolderBounds;
    
}

-(void) useFractalDefinitionAppearanceView {
    
    if (self.fractalDefinitionRulesView.superview == nil) {
        [self.fractalDefinitionPlaceholderView addSubview: self.fractalDefinitionAppearanceView];
    } else {
        [UIView transitionFromView: self.fractalDefinitionRulesView 
                            toView: self.fractalDefinitionAppearanceView 
                          duration: 0.3 
                           options: UIViewAnimationOptionTransitionFlipFromRight 
                        completion: NULL];
    }
    //    self.fractalDefinitionAppearanceView.center = self.placeHolderCenter;
    //    self.fractalDefinitionAppearanceView.bounds = self.placeHolderBounds;
}

/*
 not sure this is needed?
 copied but no longer relevant?
 */
- (void)updateUndoRedoBarButtonState {
    if (self.editing) {
        NSInteger level = [self.undoManager groupingLevel] > 0;
        
        if (level && [self.undoManager canRedo]) {
            self.redoButtonItem.enabled = YES;
        } else {
            self.redoButtonItem.enabled = NO;
        }
        
        [self logGroupingLevelFrom: NSStringFromSelector(_cmd)];
        if (level && [self.undoManager canUndo]) {
            self.undoButtonItem.enabled = YES;
        } else {
            self.undoButtonItem.enabled = NO;
        }
    }
}

//TODO: add Undo and Redo buttons for editing
- (void) configureNavButtons {
    self.title = _fractal.name;
    self.toolbarTitle.text = _fractal.name;
}

-(void)configureLandscapeViewFrames {
    
    // Temporarily disable
//    if (nil && self.portraitViewFrames) {
//    if (self.portraitViewFrames != nil && self.editing) {
        // should always not be nil
//        CGRect portrait0 = self.fractalViewLevel0.superview.frame;
//        CGRect portrait1 = self.fractalViewLevel1.superview.frame;
//        CGRect portraitN = self.fractalView.frame;
//        
//        CGRect new0;
//        CGRect new1;
//        CGRect newN;
//        
//        
//        newN = CGRectUnion(portrait0, portrait1);
//        
//        // Portrait
//        // Swap position of N with 0 & 1
//        CGRectDivide(portraitN, &new0, &new1, portraitN.size.width/2.0, CGRectMinXEdge);        
//        [UIView animateWithDuration:1.0 animations:^{
//            // move N to empty spot
//            self.fractalView.superview.frame = newN;
//            
//            // move 0 & 1 to empty N spot
//            self.fractalViewLevel0.superview.frame = new0;
//            self.fractalViewLevel1.superview.frame = new1;
//        }];
//        
//    }
}

-(void) restorePortraitViewFrames {
//    if (self.portraitViewFrames != nil) {
//        // should always not be nil
//        CGRect portrait0;
//        CGRect portrait1;
//        CGRect portraitN;
//        
//        CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)(self.portraitViewFrames)[@"frame0"], &portrait0);
//        CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)(self.portraitViewFrames)[@"frame1"], &portrait1);
//        CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)(self.portraitViewFrames)[@"frameN"], &portraitN);
//        
//        [UIView animateWithDuration:1.0 animations:^{
//            // move N to empty spot
//            self.fractalView.superview.frame = portraitN;
//            
//            // move 0 & 1 to empty N spot
//            self.fractalViewLevel0.superview.frame = portrait0;
//            self.fractalViewLevel1.superview.frame = portrait1;
//        }];
//        
//    }
}

#pragma mark - action utility methods
-(double) convertAndQuantizeRotationFrom: (UIRotationGestureRecognizer*)sender quanta: (double) stepRadians ratio: (double) deltaAngleToDeltaGestureRatio {
    
    double deltaAngle = 0.0;
    
    // conver the gesture rotation to a range between +180 & -180
    double deltaGestureRotation =  remainder(sender.rotation, 2*M_PI);
    
    double deltaAngleSteps = nearbyint(deltaAngleToDeltaGestureRatio*deltaGestureRotation/stepRadians);
    double newRotation = 0;
    
    if (deltaAngleSteps != 0.0) {
        deltaAngle = deltaAngleSteps*stepRadians;
        
        newRotation = deltaGestureRotation - deltaAngle/deltaAngleToDeltaGestureRatio;
        sender.rotation = newRotation;
    }
    //    NSLog(@"rotation: %g; sign: %g; rotated: %g; remainder: %g; deltaGestureRotation: %g; velocity: %g; newRotation: %g",
    //          degrees(sender.rotation),
    //          copysign(1.0, sender.rotation),
    //          degrees(sender.rotation + copysign(M_PI, sender.rotation)),
    //          degrees(remainder(sender.rotation + copysign(M_PI, sender.rotation), 2*M_PI)),
    //          degrees(deltaGestureRotation),
    //          sender.velocity,
    //          newRotation);
    
    //    NSLog(@"deltaAngleSteps = %g; deltaAngle = %g;", deltaAngleSteps, degrees(deltaAngle));
    return deltaAngle;
}
- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *fractalView = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView: fractalView];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:fractalView.superview];
        
        fractalView.layer.anchorPoint = CGPointMake(locationInView.x / fractalView.bounds.size.width, locationInView.y / fractalView.bounds.size.height);
        fractalView.center = locationInSuperview;
    }
}



-(IBAction) info:(id)sender {
    
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
- (IBAction)undoEdit:(id)sender {
    [self logGroupingLevelFrom: NSStringFromSelector(_cmd)];
    if ([self.undoManager groupingLevel] > 0) {
        [self.undoManager endUndoGrouping];
        [self.undoManager undoNestedGroup];
    }
    //[self.undoManager disableUndoRegistration];
    //[self.undoManager undo];
    //[self.undoManager enableUndoRegistration];
    [self logGroupingLevelFrom: NSStringFromSelector(_cmd)];
}
- (IBAction)redoEdit:(id)sender {
    [self.fractal.managedObjectContext redo];
}

/*
 since we are using core data, all we need to do to undo all changes and cancel the edit session is not save the core data and use rollback.
 */
- (IBAction)cancelEdit:(id)sender {
    self.cancelled = YES;
    [self setEditing: NO animated: YES];
}

//-(void) setEditMode: (BOOL) editing {
//    UIColor* white = [UIColor colorWithWhite: 1.0 alpha: 1.0];
//    for (UIControl* control in self.editControls) {
//        control.enabled = editing;
//        
//        if ([control isKindOfClass:[UITextField class]]) {
//            UITextField* tf = (UITextField*) control;
//            tf.backgroundColor = editing ? white : nil;
//            tf.opaque = editing;
//            tf.borderStyle = editing ? UITextBorderStyleRoundedRect : UITextBorderStyleNone;
//            
//        } else if ([control isKindOfClass:[UITextView class]]) {
//            UITextView* tf = (UITextView*) control;
//            tf.editable = editing;
//            tf.backgroundColor = editing ? white : nil;
//            tf.opaque = editing;
//            if (editing) {
//                tf.layer.borderColor = [[UIColor colorWithWhite: 0.75 alpha: 1.0] CGColor];
//                tf.layer.borderWidth = 1.0;
//                tf.layer.cornerRadius = 8.0;
//                // Would need to add another layer to have a shadow.
//                //tf.layer.shadowOpacity = 0.5;
//                //tf.layer.shadowOffset = CGSizeMake(5.0, 5.0);
//                //tf.layer.masksToBounds = NO;
//            } else {
//                tf.layer.borderColor = [[UIColor colorWithWhite: 1.0 alpha: 1.0] CGColor];
//                //tf.layer.shadowOpacity = 0.0;
//            }
//            
//        } else  if ([control isKindOfClass:[UIStepper class]]) {
//            UIStepper* tf = (UIStepper*) control;
//            tf.hidden = !editing;
//        } else if ([control isKindOfClass:[UISwitch class]]) {
//            UISwitch* tf = (UISwitch*) control;
//            tf.hidden = !editing;
//        } else if ([control isKindOfClass:[UIButton class]]) {
//            //            UIButton* tf = (UIButton*) control;
//        }
//    }
//}


-(void) updateViewsForEditMode:(BOOL)editing {
    
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];

    if (!editing) {
        [self fullScreenOn];
        
    } else {
        [self fullScreenOff];
    }
}

-(void) moveEditorHeightTo:(NSInteger)height {
//    UIView* editorHolderView = self.fractalEditorsHolder;
//    [editorHolderView removeConstraint: self.fractalEditorsHolderHeightConstraint];
//    
//    NSDictionary *views = NSDictionaryOfVariableBindings(editorHolderView);
//    NSString* formatString = [NSString stringWithFormat:@"V:[editorHolderView(%u)]",height];
//    NSArray* newConstraints = [NSLayoutConstraint constraintsWithVisualFormat:formatString options:0 metrics:nil views:views];
//    
//    self.fractalEditorsHolderHeightConstraint = newConstraints.count > 0 ? [newConstraints objectAtIndex: 0] : nil;
//    
//    [editorHolderView addConstraint: self.fractalEditorsHolderHeightConstraint];
}

-(void) fullScreenOn {
//    [self moveEditorHeightTo: 0];
}

-(void) fullScreenOff {
//    [self moveEditorHeightTo: self.cachedEditorsHeight];
}

-(void) toggleFullScreen:(id)sender {
//    if (self.fractalEditorsHolder.frame.size.height == self.cachedEditorsHeight) {
//        [self fullScreenOn];
//    } else {
//        [self fullScreenOff];
//    }
}
-(void) updateViewConstraints {
    [super updateViewConstraints];
}
/* 
 For portrait to landscape, move the views before the rotation.
 
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //NSLog(@"%@", NSStringFromSelector(_cmd));

}

/*
 from landscape to portrait, move the views after the rotation
 */
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //NSLog(@"%@", NSStringFromSelector(_cmd));
        
    if (UIDeviceOrientationIsPortrait(self.interfaceOrientation) && UIDeviceOrientationIsLandscape(fromInterfaceOrientation)) {
        
        [self restorePortraitViewFrames];
    } else {
        
        [self configureLandscapeViewFrames];
        
    }
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
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL should = YES;
    return should;
}
/* The popover controller does not call this method in response to programmatic calls to the
 dismissPopoverAnimated: method. If you dismiss the popover programmatically, you should perform
 any cleanup actions immediately after calling the dismissPopoverAnimated: method. */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    NSLog(@"%@ Popover dismissed", popoverController.description);
}
-(void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
//    NSLog(@"%@ Popover dismissed", popoverPresentationController.description);
    self.currentPresentedController = nil;
}
-(void) handleNewPopoverRequest:(UIViewController<FractalControllerProtocol>*)newController
                         sender: (id) sender
                   otherPopover: (UIViewController<FractalControllerProtocol>*) otherController {
    
    if (self.currentPresentedController != nil) {
        [self.currentPresentedController dismissViewControllerAnimated: YES completion:^{
            self.currentPresentedController = nil;
        }];
    }
    
    newController.fractal = self.fractal;
    newController.fractalUndoManager = self.undoManager;
    
    UIPopoverPresentationController* ppc = newController.popoverPresentationController;
    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController: newController animated: YES completion: ^{
        //
        self.currentPresentedController = newController;
    }];

}
-(IBAction)libraryButtonPressed:(id)sender {
    [self handleNewPopoverRequest: self.libraryViewController sender: sender otherPopover: self.appearanceViewController];
}
-(IBAction)appearanceButtonPressed:(id)sender {
    if ([self.fractal.isImmutable boolValue]) {
        self.fractal = [self.fractal mutableCopy];
    }
    [self handleNewPopoverRequest: self.appearanceViewController sender: sender otherPopover: self.libraryViewController];
}

- (IBAction)shareButtonPressed:(id)sender {
//    [self.shareActionsSheet showFromBarButtonItem: sender animated: YES];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Share"
                                                                   message: @"How would you like to share the image?"
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:@"Camera Roll" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                              [self shareFractalToCameraRoll];
                                                          }];
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Public Cloud" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                              [self shareFractalToPublicCloud];
                                                          }];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alert addAction: cameraAction];
    [alert addAction: fractalCloud];
    [alert addAction: defaultAction];
    
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)copyFractal:(id)sender {    
    // copy
    self.fractal = [self.fractal mutableCopy];
    
    [self appearanceButtonPressed: self.appearanceButton];
}

- (IBAction)levelInputChanged:(UIControl*)sender {
    double rawValue = [[sender valueForKey: @"value"] doubleValue];
    NSNumber* roundedNumber = @(lround(rawValue));
    self.fractal.level = roundedNumber;
}

-(IBAction) rotateTurningAngle:(UIRotationGestureRecognizer*)sender {
    if (self.editing) {
        
//        NSIndexPath* turnAngleIndex = (self.appearanceCellIndexPaths)[@"turningAngle"];
//        
//        if (turnAngleIndex) {
//            [self.fractalPropertiesTableView scrollToRowAtIndexPath: turnAngleIndex
//                                                   atScrollPosition: UITableViewScrollPositionMiddle
//                                                           animated: YES];
//            
//        }
//        
        
        //        double stepRadians = radians(self.turnAngleStepper.stepValue);
        double stepRadians = radians(2.5);
        // 2.5 degrees -> radians
        
        double deltaTurnToDeltaGestureRatio = 1.0/6.0;
        // reduce the sensitivity to make it easier to rotate small degrees
        
        double deltaTurnAngle = [self convertAndQuantizeRotationFrom: sender
                                                              quanta: stepRadians
                                                               ratio: deltaTurnToDeltaGestureRatio];
        
        if (deltaTurnAngle != 0.0 ) {
            double newAngle = remainder([self.fractal.turningAngle doubleValue]-deltaTurnAngle, M_PI*2);
            self.fractal.turningAngle = @(newAngle);
        }
    }
}

-(IBAction) rotateFractal:(UIRotationGestureRecognizer*)sender {
    if (self.editing) {
        
        double stepRadians = radians(15.0);
        
        double deltaTurnToDeltaGestureRatio = 1.0;
        
        double deltaTurnAngle = [self convertAndQuantizeRotationFrom: sender quanta: stepRadians ratio: deltaTurnToDeltaGestureRatio];
        
        if (deltaTurnAngle != 0) {
            double newAngle = remainder([self.fractal.baseAngle doubleValue]-deltaTurnAngle, M_PI*2);
            self.fractal.baseAngle = @(newAngle);
        }
    }
}

- (IBAction)panFractal:(UIPanGestureRecognizer *)gestureRecognizer {
//    CGPoint locationInView = [gestureRecognizer locationInView: fractalView];
//    subLayer.anchorPoint = CGPointMake(locationInView.x / fractalView.bounds.size.width, locationInView.y / fractalView.bounds.size.height);
//    
//    UIGestureRecognizerState state = gestureRecognizer.state;
//    
//    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
//        CGPoint translation = [gestureRecognizer translationInView:fractalView];
//        
//        CATransform3D newTrans = CATransform3DTranslate(subLayer.transform, translation.x, translation.y, 0);
//        subLayer.transform = newTrans;
//        
//        [gestureRecognizer setTranslation:CGPointZero inView: fractalView];
//    }
//    
    static CGPoint initialPosition;

    UIView *fractalView = [gestureRecognizer view];
    CALayer* subLayer = [self fractalLevelNLayer];
    UIGestureRecognizerState state = gestureRecognizer.state;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    if (state == UIGestureRecognizerStateBegan) {
        
        initialPosition = subLayer.position;
        
    } else if (state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gestureRecognizer translationInView: fractalView];
        subLayer.position = CGPointMake(initialPosition.x+translation.x,initialPosition.y+translation.y);
        
    } else if (state == UIGestureRecognizerStateCancelled) {
        
        subLayer.position = initialPosition;
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];        
        
    } else if (state == UIGestureRecognizerStateEnded) {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
    }

    [CATransaction commit];
}
/* want to use 2 finger pans for changing rotation and line thickness in place of swiping 
  need to lock in either horizontal or vertical panning view a state and state change */
-(IBAction)twoFingerPanFractal:(UIPanGestureRecognizer *)gestureRecognizer {
    static CGPoint initialPosition;
    static double  initialAngleDegrees;
    static double  initialWidth;
    static NSInteger determinedState;
    static NSInteger axisState;
    
    UIView *fractalView = [gestureRecognizer view];
    CALayer* subLayer = [self fractalLevelNLayer];
    UIGestureRecognizerState state = gestureRecognizer.state;
    
    if (state == UIGestureRecognizerStateBegan) {
        
        [self.undoManager beginUndoGrouping];
        [self.fractal.managedObjectContext processPendingChanges];

        initialPosition = subLayer.position;
        initialAngleDegrees = [self.fractal.turningAngleAsDegree doubleValue];
        initialWidth = [self.fractal.lineWidth doubleValue];
    
        
        determinedState = 0;
        
    } else if (state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gestureRecognizer translationInView: fractalView];
        if (determinedState==0) {
            if (fabsf(translation.x) >= fabsf(translation.y)) {
                axisState = 0;
            } else {
                axisState = 1;
            }
            determinedState = 1;
        } else {
            if (axisState) {
                // vertical, change angle
                double scaledStepAngle = floorf(translation.y/20.0)/2.0;
                double newAngleDegrees = initialAngleDegrees + scaledStepAngle;
                [self.fractal setTurningAngleAsDegrees:  @(newAngleDegrees)];

            } else {
                // hosrizontal
                double scaledWidth = floorf(translation.x/100);
                double newidth = fmax(initialWidth + scaledWidth, 1.0);
                self.fractal.lineWidth = @(newidth);

            }
        }
        
    } else if (state == UIGestureRecognizerStateCancelled) {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
        [self.fractal setTurningAngleAsDegrees:  @(initialAngleDegrees)];
        determinedState = 0;
        if ([self.undoManager groupingLevel] > 0) {
            [self.undoManager endUndoGrouping];
            [self.undoManager undoNestedGroup];
        }
    } else if (state == UIGestureRecognizerStateEnded) {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
        determinedState = 0;
        [self.fractal.managedObjectContext processPendingChanges];
    }
}

- (IBAction)panLevel0:(UIPanGestureRecognizer *)sender {
}
/* obsolete */
- (IBAction)swipeFractal:(UISwipeGestureRecognizer *)gestureRecognizer {
    
    if (self.editing) {
        UIGestureRecognizerState state = gestureRecognizer.state;
        
        if (state == UIGestureRecognizerStatePossible) {
            
        } else if (state == UIGestureRecognizerStateRecognized) {
            
//            if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
//                [self decrementLineWidth: nil];
//            } else if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
//                [self incrementLineWidth: nil];
//            } else if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionUp) {
//                [self incrementTurnAngle: nil];
//            } else if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionDown) {
//                [self decrementTurnAngle: nil];
//            }
        } else if (state == UIGestureRecognizerStateCancelled) {
            
        } 
        
    }
}

- (IBAction)magnifyFractal:(UILongPressGestureRecognizer*)sender {
    
}

- (IBAction)toggleAutoScale:(id)sender {
    for (id object in self.generatorsArray) {
        if ([object isKindOfClass: [LSFractalGenerator class]]) {
            LSFractalGenerator* generator = (LSFractalGenerator*) object;
            generator.autoscale = !generator.autoscale;
            NSLog(@"autoscale: %u;", generator.autoscale);
            if (generator.autoscale) {
                // refit view frame and refresh layer
                self.fractalView.transform = CGAffineTransformIdentity;
                self.fractalView.frame = self.fractalViewParent.bounds;
            }
        }
    }
}

- (IBAction)scaleFractal:(UIPinchGestureRecognizer *)gestureRecognizer {
    
    static CATransform3D initialTransform;

    CALayer* subLayer = [self fractalLevelNLayer];
    UIGestureRecognizerState state = gestureRecognizer.state;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    if (state == UIGestureRecognizerStateBegan) {
        
        initialTransform = subLayer.transform;
        
    } else if (state == UIGestureRecognizerStateChanged) {

        CATransform3D newTrans = CATransform3DScale(initialTransform, [gestureRecognizer scale], [gestureRecognizer scale], 1);
        subLayer.transform = newTrans;

    } else if (state == UIGestureRecognizerStateCancelled) {
        
        subLayer.transform = initialTransform;
        [gestureRecognizer setScale:1];
        
    } else if (state == UIGestureRecognizerStateEnded) {
    
        [gestureRecognizer setScale:1];

    }
    [CATransaction commit];
}

-(IBAction) autoScale:(id)sender {
    CALayer* subLayer = [self fractalLevelNLayer];
    subLayer.transform = CATransform3DIdentity;
    subLayer.position = self.fractalView.center;
    // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
}

-(void) shareFractalToCameraRoll {
    NSLog(@"Unimplemented sharing to camera.");
}
-(void) shareFractalToPublicCloud {
    NSLog(@"Unimplemented sharing to public cloud.");
}

#pragma mark - control actions
//- (IBAction)nameInputDidEnd:(UITextField*)sender {
//    self.fractal.name = sender.text;
//}

//- (IBAction)selectStrokeColor:(UIButton*)sender {
//    self.coloringKey = @"lineColor";
//        
//    ColorPickerController* colorPicker = (ColorPickerController*) self.colorPopover.contentViewController.navigationController.visibleViewController;
//    colorPicker.selectedColor = [self.currentFractal lineColorAsUI];
//    
//    [self.colorPopover presentPopoverFromRect: sender.frame 
//                                       inView: sender.superview 
//                     permittedArrowDirections:UIPopoverArrowDirectionAny 
//                                     animated: YES];
//
//}

//- (IBAction)selectFillColor:(UIButton*)sender {
//    self.coloringKey = @"fillColor";
//    
//    ColorPickerController* colorPicker = (ColorPickerController*) self.colorPopover.contentViewController.navigationController.visibleViewController;
//    colorPicker.selectedColor = [self.currentFractal fillColorAsUI];
//        
//    [self.colorPopover presentPopoverFromRect: sender.frame 
//                                       inView: sender.superview 
//                     permittedArrowDirections:UIPopoverArrowDirectionAny 
//                                     animated: YES];
//
//    [self performSegueWithIdentifier: @"ColorPickerPopoverSeque" sender: self];
//
//
//}
- (IBAction)incrementLineWidth:(id)sender {
    if ([self.fractal.isImmutable boolValue]) {
        self.fractal = [self.fractal mutableCopy];
    }
    double width = [self.fractal.lineWidth doubleValue];
    double increment = [self.fractal.lineWidthIncrement doubleValue];
    
    [self.undoManager beginUndoGrouping];
    self.fractal.lineWidth = @(fmax(width+increment, 1.0));
}

- (IBAction)decrementLineWidth:(id)sender {
    double width = [self.fractal.lineWidth doubleValue];
    double increment = [self.fractal.lineWidthIncrement doubleValue];
    
    [self.undoManager beginUndoGrouping];
    self.fractal.lineWidth = @(fmax(width-increment, 1.0));
}

//TODO: User preference for turnAngle swipe increment
//Obsolete replaced with 2 finger pan
- (IBAction)incrementTurnAngle:(id)sender {
    [self.undoManager beginUndoGrouping];
    [self.fractal.managedObjectContext processPendingChanges];
    [self.fractal setTurningAngleAsDegrees:  @([self.fractal.turningAngleAsDegree doubleValue] + 0.5)];
}
- (IBAction)decrementTurnAngle:(id)sender {
    [self.undoManager beginUndoGrouping];
    [self.fractal.managedObjectContext processPendingChanges];
    [self.fractal setTurningAngleAsDegrees:  @([self.fractal.turningAngleAsDegree doubleValue] - 0.5)];
}



//- (IBAction)switchFractalDefinitionView:(UISegmentedControl*)sender {
//    if (sender.selectedSegmentIndex == 0) {
//        [self useFractalDefinitionRulesView];
//        
//    } else if(sender.selectedSegmentIndex == 1) {
//        [self useFractalDefinitionAppearanceView];
//    }
//}


// TODO: copy app delegate saveContext method

#pragma  mark - ActionSheetDelegate Methods

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
}

#pragma mark - core data 
-(void) setUndoManager:(NSUndoManager *)undoManager {
    if (undoManager != _undoManager) {
        if (undoManager == nil) {
            [self cleanUpUndoManager];
        }
        _undoManager = undoManager;
    }
}

-(NSUndoManager*) undoManager {
    if (_undoManager == nil) {
        [self setUpUndoManager];
    }
    return _undoManager;
}

- (void)setUpUndoManager {
    /*
     If the book's managed object context doesn't already have an undo manager, then create one and set it for the context and self.
     The view controller needs to keep a reference to the undo manager it creates so that it can determine whether to remove the undo manager when editing finishes.
     */
    if (self.fractal.managedObjectContext.undoManager == nil) {
        
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


- (void)cleanUpUndoManager {
    
    // Remove self as an observer.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.fractal.managedObjectContext.undoManager == _undoManager) {
        self.fractal.managedObjectContext.undoManager = nil;
        _undoManager = nil;
    }       
}


//- (NSUndoManager *)undoManager {
//    return self.currentFractal.managedObjectContext.undoManager;
//}


- (void)undoManagerDidUndo:(NSNotification *)notification {
    [self refreshContents];
}


- (void)undoManagerDidRedo:(NSNotification *)notification {
    [self refreshContents];
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

-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo {
    if (LOGBOUNDS) {
        CFDictionaryRef boundsDict = CGRectCreateDictionaryRepresentation(bounds);
        NSString* boundsDescription = [(__bridge NSDictionary*)boundsDict description];
        CFRelease(boundsDict);
        
        NSLog(@"%@ = %@", boundsInfo,boundsDescription);
    }
}
-(void) logGroupingLevelFrom:  (NSString*) cmd {
    if (/* DISABLES CODE */ (NO)) {
        NSLog(@"%@: Undo group levels = %ld", cmd, (long)[self.undoManager groupingLevel]);
    }
}
-(NSNumberFormatter*) twoPlaceFormatter {
    if (_twoPlaceFormatter == nil) {
        _twoPlaceFormatter = [[NSNumberFormatter alloc] init];
        [_twoPlaceFormatter setAllowsFloats: YES];
        [_twoPlaceFormatter setMaximumFractionDigits: 2];
        [_twoPlaceFormatter setMaximumIntegerDigits: 3];
        [_twoPlaceFormatter setPositiveFormat: @"##0.00"];
        [_twoPlaceFormatter setNegativeFormat: @"-##0.00"];
    }
    return _twoPlaceFormatter;
}

-(void) dealloc {
    self.fractal = nil; // removes observers via custom setter call
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }
}

@end
