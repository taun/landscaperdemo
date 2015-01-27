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
@property (nonatomic,strong) UIImage                       *fractalGeneratorL0Image;
@property (nonatomic,strong) LSFractalRenderer   *fractalGeneratorL0;
@property (nonatomic,strong) UIImage                       *fractalGeneratorL1Image;
@property (nonatomic,strong) LSFractalRenderer   *fractalGeneratorL1;
@property (nonatomic,strong) UIImage                       *fractalGeneratorL2Image;
@property (nonatomic,strong) LSFractalRenderer   *fractalGeneratorL2;
@property (nonatomic,strong) UIImage                       *fractalGeneratorLN2S1Image;
@property (nonatomic,strong) LSFractalRenderer   *fractalGeneratorLN2S1;
@property (nonatomic,strong) UIImage                       *fractalGeneratorLNS1Image;
@property (nonatomic,strong) LSFractalRenderer   *fractalGeneratorLNS1;
@property (nonatomic,strong) UIImage                       *fractalGeneratorLNS4Image;
@property (nonatomic,strong) LSFractalRenderer   *fractalGeneratorLNS4;
@property (nonatomic,assign) BOOL                          autoscaleN;

@property (nonatomic,strong) UIDocumentInteractionController *documentShareController;

-(void) saveToUserPreferencesAsLastEditedFractal: (LSFractal*) fractal;
-(void) addObserversForFractal: (LSFractal*) fractal;
-(void) removeObserversForFractal: (LSFractal*) fractal;

//-(void) setEditMode: (BOOL) editing;
-(void) fullScreenOn;
-(void) fullScreenOff;

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
    
}

#pragma message "TODO: add variables for max,min values for angles, widths, .... Add to model, class fractal category???"
-(void)viewDidLoad {
    
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

    UIEdgeInsets scrollInsets = UIEdgeInsetsMake(300.0, 300.0, 300.0, 300.0);
    self.fractalScrollView.contentInset = scrollInsets;
    UIView* fractalCanvas = self.fractalView.superview;
    fractalCanvas.layer.shadowColor = [[UIColor blackColor] CGColor];
    fractalCanvas.layer.shadowOffset = CGSizeMake(5.0, 5.0);
    fractalCanvas.layer.shadowOpacity = 0.3;
    fractalCanvas.layer.shadowRadius = 3.0;
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL fullScreenState = [defaults boolForKey: kPrefFullScreenState];
    if (fullScreenState) {
        [self fullScreenOn];
    }

    [super viewDidLoad];
        
}

-(void) viewWillLayoutSubviews {
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
    
//    [self refreshContents];

//    self.editing = YES;
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [_privateImageGenerationQueue cancelAllOperations];

    if (self.editing) {
        [self.fractal.managedObjectContext save: nil];
        [self setUndoManager: nil];
    } else {
        // undo all non-saved changes
        [self.fractal.managedObjectContext rollback];
    }
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //
        [self queueFractalImageUpdates];
//        self.fractalView.position = fractalNewPosition;
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //
    }];
//    subLayer.position = self.fractalView.center;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    // Return YES for supported orientations
	return YES;
}
#pragma message  "TODO: Check for fractal name change to update window title"
/* observer fractal.replacementRules */
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    NSUInteger changeCount = 0;
    if ([object isKindOfClass:[NSManagedObject class]]) {
        NSDictionary* changes = [object changedValuesForCurrentEvent];
        changeCount = changes.count;
    }
    if ([keyPath isEqualToString: kLibrarySelectionKeypath] && object == self.libraryViewController) {
        
        self.fractal = self.libraryViewController.selectedFractal;
//        if (!self.fractal.placements || self.fractal.placements.count == 0) {
//            // currentl only on e default placement for each fractal, on scape and one background
//            NSManagedObjectContext* fractalContext = self.fractal.managedObjectContext;
//            
//            MBFractalScape* defaultScape = [MBFractalScape insertNewObjectIntoContext: fractalContext];
//            defaultScape.name = [NSString stringWithFormat: @"Default Scape for %@", self.fractal.name];
//            
//            MBScapeBackground* defaultBackground = [MBScapeBackground insertNewObjectIntoContext: fractalContext];
//            defaultBackground.name = @"Default background";
//            
//            MBColor* clearColor = [MBColor newMBColorWithUIColor: [UIColor clearColor] inContext: fractalContext];
//            clearColor.name = @"Clear";
//            
//            defaultBackground.color = clearColor;
//            
//            defaultScape.background = defaultBackground;
//            
//            
//            MBPlacedEntity* placement = [MBPlacedEntity insertNewObjectIntoContext: fractalContext];
//            placement.lsFractal = self.fractal;
//            placement.fractalScape = defaultScape;
//            
//        }
        
    } else if ([[LSFractal redrawProperties] containsObject: keyPath]) {
        
        if (changeCount) {
            [self queueFractalImageUpdates];
            [self updateInterface];
        }
        
    } else if ([[LSFractal appearanceProperties] containsObject: keyPath]) {
        
        if (changeCount) {
            [self queueFractalImageUpdates];
            [self updateInterface];
        }
        
    } else if ([[LSFractal productionRuleProperties] containsObject: keyPath] ||
               [keyPath isEqualToString: [LSReplacementRule rulesKey]] ||
               [keyPath isEqualToString: [LSReplacementRule contextRuleKey]]) {
        
        if (changeCount) {
            [self regenerateLevels];
            [self updateInterface];
        }
        
//    } else if ([[LSFractal labelProperties] containsObject: keyPath]) {
//        [self reloadLabels];
    } else if ([keyPath isEqualToString: @"name"]) {
        [self updateNavButtons];
                
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
    if (viewSize.height > viewSize.width) {
        // portrait
        _appearanceViewController.preferredContentSize = _appearanceViewController.portraitSize;
    } else {
        // landscape
        _appearanceViewController.preferredContentSize = _appearanceViewController.landscapeSize;
    }

    return _appearanceViewController;
}
-(NSOperationQueue*) privateImageGenerationQueue {
    if (!_privateImageGenerationQueue) {
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
-(void) setFractal:(LSFractal *)fractal {
    if (_fractal != fractal) {
//        if ([fractal.isImmutable boolValue]) {
//            fractal = [fractal mutableCopy];
//        }

        [_privateImageGenerationQueue cancelAllOperations];
        
        [self removeObserversForFractal: _fractal];
        
        _autoscaleN = YES;
        
        _fractal = fractal;
        
        _privateFractalContext = [[NSManagedObjectContext alloc]initWithConcurrencyType: NSPrivateQueueConcurrencyType];
        _privateFractalContext.parentContext = _fractal.managedObjectContext;
        _fractalID = _fractal.objectID;
        
        [_privateFractalContext performBlockAndWait:^{
            self->_privateQueueFractal = (LSFractal*)[self->_privateFractalContext objectWithID: self->_fractalID];
        }];
        
        [self addObserversForFractal: _fractal];

        
        if (_fractal != nil) {
            [self regenerateLevels];
            [self saveToUserPreferencesAsLastEditedFractal: fractal];
        }
        [self updateInterface];
    }
}
-(LSFractalRenderer*) fractalGeneratorL0 {
    if (!_fractalGeneratorL0) {
        if (self.fractal) {
            _fractalGeneratorL0 = [LSFractalRenderer newRendererForFractal: self.fractal];
            _fractalGeneratorL0.name = @"_fractalGeneratorL0";
            _fractalGeneratorL0.imageView = self.fractalViewLevel0;
            _fractalGeneratorL0.pixelScale = self.fractalViewLevel0.contentScaleFactor;
            _fractalGeneratorL0.flipY = YES;
            _fractalGeneratorL0.margin = 30.0;
            _fractalGeneratorL0.showOrigin = NO;
            _fractalGeneratorL0.autoscale = YES;
        }
    }
    return _fractalGeneratorL0;
}
-(LSFractalRenderer*) fractalGeneratorL1 {
    if (!_fractalGeneratorL1) {
        if (self.fractal) {
            _fractalGeneratorL1 = [LSFractalRenderer newRendererForFractal: self.fractal];
            _fractalGeneratorL1.name = @"_fractalGeneratorL1";
            _fractalGeneratorL1.imageView = self.fractalViewLevel1;
            _fractalGeneratorL1.pixelScale = self.fractalViewLevel1.contentScaleFactor;
            _fractalGeneratorL1.flipY = YES;
            _fractalGeneratorL1.margin = 30.0;
            _fractalGeneratorL1.showOrigin = NO;
            _fractalGeneratorL1.autoscale = YES;
        }
    }
    return _fractalGeneratorL1;
}
-(LSFractalRenderer*) fractalGeneratorL2 {
    if (!_fractalGeneratorL2) {
        if (self.fractal) {
            _fractalGeneratorL2 = [LSFractalRenderer newRendererForFractal: self.fractal];
            _fractalGeneratorL2.name = @"_fractalGeneratorL2";
            _fractalGeneratorL2.imageView = self.fractalViewLevel2;
            _fractalGeneratorL2.pixelScale = self.fractalViewLevel2.contentScaleFactor;
            _fractalGeneratorL2.flipY = YES;
            _fractalGeneratorL2.margin = 30.0;
            _fractalGeneratorL2.showOrigin = NO;
            _fractalGeneratorL2.autoscale = YES;
        }
    }
    return _fractalGeneratorL2;
}
-(LSFractalRenderer*) fractalGeneratorLN2S1 {
    if (!_fractalGeneratorLN2S1) {
        if (self.fractal) {
            _fractalGeneratorLN2S1 = [LSFractalRenderer newRendererForFractal: self.fractal];
            _fractalGeneratorLN2S1.name = @"_fractalGeneratorLN2S1";
            _fractalGeneratorLN2S1.imageView = self.fractalView;
            _fractalGeneratorLN2S1.pixelScale = self.fractalView.contentScaleFactor;
            _fractalGeneratorLN2S1.flipY = YES;
            _fractalGeneratorLN2S1.margin = 50.0;
            _fractalGeneratorLN2S1.showOrigin = NO;
            _fractalGeneratorLN2S1.autoscale = YES;
        }
    }
    return _fractalGeneratorLN2S1;
}
-(LSFractalRenderer*) fractalGeneratorLNS1 {
    if (!_fractalGeneratorLNS1) {
        if (self.fractal) {
            _fractalGeneratorLNS1 = [LSFractalRenderer newRendererForFractal: self.fractal];
            _fractalGeneratorLNS1.name = @"_fractalGeneratorLNS1";
            _fractalGeneratorLNS1.imageView = self.fractalView;
            _fractalGeneratorLNS1.pixelScale = self.fractalView.contentScaleFactor;
            _fractalGeneratorLNS1.flipY = YES;
            _fractalGeneratorLNS1.margin = 50.0;
            _fractalGeneratorLNS1.showOrigin = NO;
            _fractalGeneratorLNS1.autoscale = YES;
        }
    }
    return _fractalGeneratorLNS1;
}
-(LSFractalRenderer*) fractalGeneratorLNS4 {
    if (!_fractalGeneratorLNS4) {
        if (self.fractal) {
            _fractalGeneratorLNS4 = [LSFractalRenderer newRendererForFractal: self.fractal];
            _fractalGeneratorLNS4.name = @"_fractalGeneratorLNS4";
            _fractalGeneratorLNS4.imageView = self.fractalView;
            _fractalGeneratorLNS4.pixelScale = self.fractalView.contentScaleFactor*2.0;
            _fractalGeneratorLNS4.flipY = YES;
            _fractalGeneratorLNS4.margin = 50.0;
            _fractalGeneratorLNS4.showOrigin = YES;
            _fractalGeneratorLNS4.autoscale = YES;
        }
    }
    return _fractalGeneratorLNS4;
}
-(void) addObserversForFractal:(LSFractal *)fractal {
    if (fractal) {
        NSMutableSet* propertiesToObserve = [NSMutableSet setWithSet: [LSFractal productionRuleProperties]];
        [propertiesToObserve unionSet: [LSFractal appearanceProperties]];
        [propertiesToObserve unionSet: [LSFractal redrawProperties]];
        [propertiesToObserve unionSet: [LSFractal labelProperties]];
        
        for (NSString* keyPath in propertiesToObserve) {
            [fractal addObserver: self forKeyPath:keyPath options: 0 context: NULL];
        }
        for (LSReplacementRule* rRule in fractal.replacementRules) {
            [rRule addObserver: self forKeyPath: [LSReplacementRule contextRuleKey] options: 0 context: NULL];
            [rRule addObserver: self forKeyPath: [LSReplacementRule rulesKey] options: 0 context: NULL];
        }
    }
}
-(void) removeObserversForFractal:(LSFractal *)fractal {
    if (fractal) {
        NSMutableSet* propertiesToObserve = [NSMutableSet setWithSet: [LSFractal productionRuleProperties]];
        [propertiesToObserve unionSet: [LSFractal appearanceProperties]];
        [propertiesToObserve unionSet: [LSFractal redrawProperties]];
        [propertiesToObserve unionSet: [LSFractal labelProperties]];

        for (NSString* keyPath in propertiesToObserve) {
            [fractal removeObserver: self forKeyPath: keyPath];
        }
        for (LSReplacementRule* rule in fractal.replacementRules) {
            [rule removeObserver: self forKeyPath: [LSReplacementRule contextRuleKey]];
            [rule removeObserver: self forKeyPath: [LSReplacementRule rulesKey]];
        }
    }
}
-(void) saveToUserPreferencesAsLastEditedFractal: (LSFractal*) aFractal {
    // If the new fractal was just copied, then it has a temporary objectID and needs to be save first
    NSManagedObjectID* fractalID = aFractal.objectID;
    if (fractalID.isTemporaryID) {
        [aFractal.managedObjectContext save: nil];
    }
    NSURL* selectedFractalURL = [aFractal.objectID URIRepresentation];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setURL: selectedFractalURL forKey: kPrefLastEditedFractalURI];
}

#pragma mark - view utility methods

//-(void) reloadLabels {
//    self.fractalName.text = self.fractal.name;
//    self.fractalCategory.text = self.fractal.category;
//    self.fractalDescriptor.text = self.fractal.descriptor;
//}

-(void) updateInterface {
    [self updateValueInputs];
    [self updateLabelsAndControls];
    [self updateNavButtons];
}

-(void) updateValueInputs {
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
-(void) updateLabelsAndControls {
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
-(void) regenerateLevels {
    NSManagedObjectContext* pc = self.privateFractalContext;
    NSManagedObjectID* fid = self.fractalID;
    
    [pc performBlock:^{
        [pc reset];
        LSFractal* fractal = (LSFractal*)[pc objectWithID: fid];
        fractal.rulesUnchanged = NO;
        [fractal generateLevelData];
        
        NSArray* levelDataArray = @[fractal.level0RulesCache, fractal.level1RulesCache, fractal.level2RulesCache, fractal.levelNRulesCache];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateGeneratorLevels: levelDataArray];
        });
    }];
}
-(NSUInteger) levelNIndex {
    NSUInteger levelNIndex = [self.fractal.level integerValue] > 3 ? 3 : [self.fractal.level integerValue];
    return levelNIndex;
}
-(void) updateGeneratorLevels: (NSArray*)levelDataArray {
    self.levelDataArray = levelDataArray;
    
    
    if (self.levelDataArray.count == 4) {
        self.fractalGeneratorL0.levelData = self.levelDataArray[0];
        self.fractalGeneratorL1.levelData = self.levelDataArray[1];
        self.fractalGeneratorL2.levelData = self.levelDataArray[2];
//        self.fractalGeneratorLN2S1.levelData = self.levelDataArray[2];
        self.fractalGeneratorLNS1.levelData = self.levelDataArray[[self levelNIndex]];
        self.fractalGeneratorLNS4.levelData = self.levelDataArray[[self levelNIndex]];
        [self queueFractalImageUpdates];
    }
}
-(void) queueFractalImageUpdates {

    if (self.fractalGeneratorLNS4.operation && !self.fractalGeneratorLNS4.operation.isFinished) {
        [self.fractalGeneratorLNS4.operation cancel];
    }

    if (self.fractalGeneratorLNS1.operation && !self.fractalGeneratorLNS1.operation.isFinished) {
        [self.fractalGeneratorLNS4.operation cancel];
        [self.fractalGeneratorLNS1.operation cancel];
    }

    [self.privateImageGenerationQueue waitUntilAllOperationsAreFinished];

    [self queueHudImageUpdates];
    
    self.fractalGeneratorLNS4.autoscale = self.autoscaleN;
    NSBlockOperation* operationNN4 = [self operationForGenerator: self.fractalGeneratorLNS4];

    if ([self.fractal.level integerValue] > 4) {
        self.fractalGeneratorLNS1.autoscale = self.autoscaleN;
        NSBlockOperation* operationNN1 = [self operationForGenerator: self.fractalGeneratorLNS1];
        
        [operationNN4 addDependency: operationNN1];
        
        [self.privateImageGenerationQueue addOperation: operationNN1];
    }
    
    [self.privateImageGenerationQueue addOperation: operationNN4];
}
-(void) queueHudImageUpdates {
    if (!self.fractalViewLevel0.superview.hidden) {
        NSBlockOperation* operation0 = [self operationForGenerator: self.fractalGeneratorL0];
        self.fractalGeneratorL0.backgroundColor = [UIColor clearColor];
        [self.privateImageGenerationQueue addOperation: operation0];
    }
    
    if (!self.fractalViewLevel1.superview.hidden) {
        NSBlockOperation* operation1 = [self operationForGenerator: self.fractalGeneratorL1];
        self.fractalGeneratorL1.backgroundColor = [UIColor clearColor];
        [self.privateImageGenerationQueue addOperation: operation1];
    }
    
    if (!self.fractalViewLevel2.superview.hidden) {
        NSBlockOperation* operation2 = [self operationForGenerator: self.fractalGeneratorL2];
        self.fractalGeneratorL2.backgroundColor = [UIColor clearColor];
        [self.privateImageGenerationQueue addOperation: operation2];
    }
}
-(NSBlockOperation*) operationForGenerator: (LSFractalRenderer*)generator {
    
    [generator setValuesForFractal: self.fractal];

    NSBlockOperation* operation = [NSBlockOperation new];
    generator.operation = operation;
    
    [operation addExecutionBlock: ^{
        //code
        if (!generator.operation.isCancelled) {
            [generator generateImage];
            if (generator.imageView && generator.image) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    generator.imageView.image = generator.image;
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
- (void) updateNavButtons {
    self.title = _fractal.name;
    self.toolbarTitle.text = _fractal.name;
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

-(void) updateViewConstraints {
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
    
    if ([sender isKindOfClass: [UIBarButtonItem class]]) {
        ppc.barButtonItem = sender;
    } else {
        
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
-(IBAction)libraryButtonPressed:(id)sender {
    [self handleNewPopoverRequest: self.libraryViewController sender: sender otherPopover: self.appearanceViewController];
}
-(IBAction)appearanceButtonPressed:(id)sender {
    if (self.presentedViewController == self.appearanceViewController) {
        [self dismissViewControllerAnimated: YES completion:^{
            self.currentPresentedController = nil;
        }];
        return;
    }
    
    if ([self.fractal.isImmutable boolValue]) {
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
- (IBAction)shareButtonPressedOld:(id)sender {
//    [self.shareActionsSheet showFromBarButtonItem: sender animated: YES];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Share"
                                                                   message: @"How would you like to share the image?"
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;

    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    
    if (cameraAuthStatus == ALAuthorizationStatusNotDetermined || cameraAuthStatus == ALAuthorizationStatusAuthorized) {
        UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:@"Camera Roll" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                                 [self shareFractalToCameraRoll];
                                                             }];
        [alert addAction: cameraAction];
    }
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Public Cloud" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                              [self shareFractalToPublicCloud];
                                                          }];
    [alert addAction: fractalCloud];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
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
- (IBAction)shareButtonPressed:(id)sender {
    [self shareWithDocumentInteractionController: sender];
}

- (IBAction)shareWithDocumentInteractionController:(id)sender {
    
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
    if (iconList.count > 0) {
        if ([sender isKindOfClass: [UIBarButtonItem class]]) {
            BOOL success = [_documentShareController presentOptionsMenuFromBarButtonItem: sender animated: YES];
            //        BOOL result = [documentSharer presentOpenInMenuFromBarButtonItem: sender animated: YES];
        } else {
            [_documentShareController presentOpenInMenuFromRect: [sender bounds] inView: self.fractalViewRoot animated: YES];
        }
    }
}
- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    _documentShareController = nil;
}
- (IBAction)shareWithActivityControler:(id)sender {
    
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
    
    
    if ([sender isKindOfClass: [UIBarButtonItem class]]) {
        ppc.barButtonItem = sender;
    } else {
        
        ppc.sourceView = sender;
        ppc.sourceRect = [sender bounds];
    }
    
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController: activityViewController animated: YES completion: ^{
        //
        //        self.currentPresentedController = newController;
    }];
}

-(NSBlockOperation*) operationForGenerator: (LSFractalRenderer*)generator percent: (CGFloat)percent {
    
    NSBlockOperation* operation = [NSBlockOperation new];
    generator.operation = operation;
    
    [operation addExecutionBlock: ^{
        //code
        if (!generator.operation.isCancelled) {
            [generator generateImagePercent: percent];
            if (generator.imageView && generator.image) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    generator.imageView.image = generator.image;
                }];
            }
        }
    }];
    return operation;
}
#pragma message "TODO Add pause and stop buttons."
- (IBAction)playButtonPressed:(id)sender {
    
#pragma message "TODO use generator.renderTime to determine the percent increment."
    self.fractalGeneratorLNS1.autoscale = NO;
    LSFractalRenderer* generator;
    NSBlockOperation* operation;
    NSBlockOperation* prevOperation;
    
//    CGFloat time = self.fractalGeneratorLNS1.renderTime;
//    CGFloat stepSize = 0.0 * time;
    
    prevOperation = [self operationForGenerator: self.fractalGeneratorLNS1 percent: 1.0];

    for (CGFloat percent = 2.0; percent <= 100; percent += 1.0) {
        operation = [self operationForGenerator: self.fractalGeneratorLNS1 percent: percent];
        [operation addDependency: prevOperation];
        [self.privateImageGenerationQueue addOperation: prevOperation];
        prevOperation = operation;
    }
    
    [self.privateImageGenerationQueue addOperation: prevOperation];
}
- (IBAction)copyFractal:(id)sender {
    // copy
    self.fractal = [self.fractal mutableCopy];
    
    [self appearanceButtonPressed: self.editButton];
}

- (IBAction)levelInputChanged:(UIControl*)sender {
    double rawValue = [[sender valueForKey: @"value"] doubleValue];
    NSNumber* roundedNumber = @(lround(rawValue));
    self.fractal.level = roundedNumber;
}


/* want to use 2 finger pans for changing rotation and line thickness in place of swiping
  need to lock in either horizontal or vertical panning view a state and state change */
-(IBAction)twoFingerPanFractal:(UIPanGestureRecognizer *)gestureRecognizer {
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
- (IBAction)panLevel0:(UIPanGestureRecognizer *)sender {
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
- (IBAction)panLevel1:(UIPanGestureRecognizer *)sender {
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
- (IBAction)panLevel2:(UIPanGestureRecognizer *)sender {
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
                            maxAspect: (CGFloat) maxAspect {
    
    static CGPoint initialPosition;
    static CGFloat  initialAngleDegrees;
    static CGFloat  initialWidth;
    static NSInteger determinedState;
    static BOOL     isIncreasing;
    static NSInteger axisState;
    
    UIView *fractalView = [gestureRecognizer view];
    UIGestureRecognizerState state = gestureRecognizer.state;
    
    if (state == UIGestureRecognizerStateBegan) {
        self.autoscaleN = NO;
        
        [self.undoManager beginUndoGrouping];
        [self.fractal.managedObjectContext processPendingChanges];
        
        initialPosition = CGPointZero;//subLayer.position;
        
        if (anglePath) {
            initialAngleDegrees =  floorf(100.0 * degrees([[self.fractal valueForKey: anglePath] doubleValue])) / 100.0;
        }
        if (aspectPath) {
            initialWidth = floorf(100.0 * [[self.fractal valueForKey: aspectPath] doubleValue]) / 100.0;
        }
        
        determinedState = 0;
        isIncreasing = NO;
        
    } else if (state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gestureRecognizer translationInView: fractalView];
        CGPoint velocity = [gestureRecognizer velocityInView: fractalView];
        
        if (determinedState==0) {
            if (fabsf(translation.x) >= fabsf(translation.y)) {
                axisState = 0;
            } else {
                axisState = 1;
            }
            determinedState = 1;
        } else {
            if (axisState && aspectPath) {
                // vertical, change aspect
                CGFloat scaledWidth = floorf(translation.y * aspectScale * 1000.0)/1000.0;
                CGFloat newWidth = fminf(fmaxf(initialWidth + scaledWidth, minAspect), maxAspect);
                [self.fractal setValue: @(newWidth) forKey: aspectPath];
                //self.fractal.lineWidth = @(newidth);
                
            } else if (!axisState && anglePath) {
                // hosrizontal
                CGFloat closeEnough = stepAngle/5.0;
                
                CGFloat scaledStepAngle = floorf(translation.x * angleScale)/100;
                CGFloat newAngleDegrees = fminf(fmaxf(initialAngleDegrees + scaledStepAngle, minAngle), maxAngle);
                if (stepAngle > 0) {
                    CGFloat proximity = fmodf(newAngleDegrees, stepAngle);
                    if (fabsf(proximity) < closeEnough) {
                        newAngleDegrees = floorf(newAngleDegrees/stepAngle)*stepAngle;
                    } else if (velocity.x > 0.0) {
                        newAngleDegrees -= closeEnough;
                    }
                }
                [self.fractal setValue: @(radians(newAngleDegrees)) forKey: anglePath];
                
            }
        }
        
    } else if (state == UIGestureRecognizerStateCancelled) {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
        
        [self.fractal setValue:  @(radians(initialAngleDegrees)) forKey: anglePath];
        //[self.fractal setTurningAngleAsDegrees:  @(initialAngleDegrees)];
        determinedState = 0;
        if ([self.undoManager groupingLevel] > 0) {
            [self.undoManager endUndoGrouping];
            [self.undoManager undoNestedGroup];
        }
    } else if (state == UIGestureRecognizerStateEnded) {
        
        [gestureRecognizer setTranslation: CGPointZero inView: fractalView];
        determinedState = 0;
        [self saveContext];
        self.autoscaleN = YES;
    }
}

-(IBAction) autoScale:(id)sender {
//    CALayer* subLayer = nil; //[self fractalLevelNLayer];
//    subLayer.transform = CATransform3DIdentity;
//    subLayer.position = self.fractalView.center;
    // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
    [self.fractalScrollView setZoomScale: 1.0 animated: YES];
    self.fractalScrollView.contentOffset = CGPointZero;
}

- (IBAction)toggleFullScreen:(id)sender {
    BOOL fullScreenState;
    if (self.fractalViewLevel0.superview.hidden == YES) {
        [self fullScreenOff];
        fullScreenState = NO;
    } else {
        [self fullScreenOn];
        fullScreenState = YES;
    }
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: fullScreenState forKey: kPrefFullScreenState];
    [defaults synchronize];
}
-(void) fullScreenOn {
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

-(void) fullScreenOff {
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
-(NSData*) createPDF {
    CGRect imageBounds = CGRectMake(0, 0, 1024, 1024);
    
    LSFractalRenderer* generator = [LSFractalRenderer newRendererForFractal: self.fractal];
    generator.levelData = self.levelDataArray[3];
    generator.name = @"PDF Generator";
    generator.margin = 72.0;
    generator.autoscale = YES;
    generator.flipY = YES;
    
    NSMutableData* pdfData = [NSMutableData data];
    NSDictionary* pdfMetaData = @{(NSString*)kCGPDFContextCreator:@"FractalScape", (NSString*)kCGPDFContextTitle:self.fractal.name, (NSString*)kCGPDFContextKeywords:self.fractal.category};
    
    UIGraphicsBeginPDFContextToData(pdfData, imageBounds, pdfMetaData);
    {
        UIGraphicsBeginPDFPage();
        CGContextRef pdfContext = UIGraphicsGetCurrentContext();
        [generator drawInContext: pdfContext size: imageBounds.size];
    }
    UIGraphicsEndPDFContext();
    
//    CFDataRef myPDFData        = (CFDataRef)pdfData;
//    CGDataProviderRef provider = CGDataProviderCreateWithCFData(myPDFData);
//    CGPDFDocumentRef pdf       = CGPDFDocumentCreateWithProvider(provider);
    return pdfData;
}
-(void) shareFractalToCameraRoll {
    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];

    if (cameraAuthStatus == ALAuthorizationStatusNotDetermined || cameraAuthStatus == ALAuthorizationStatusAuthorized) {
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

        
        [library writeImageDataToSavedPhotosAlbum: pngImage metadata: dict completionBlock:^(NSURL *assetURL, NSError *error) {
            // call method for UIAlert about successful save with save text
            [self showSharedCompletionAlertWithText: @"your camera roll." error: error];
            
            NSLog(@"Sharing to camera status %@.", error);
        }];

//        [library writeImageToSavedPhotosAlbum: [fractalImage CGImage] orientation: ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
//            // call method for UIAlert about successful save with save text
//            [self showSharedCompletionAlertWithText: @"your camera roll." error: error];
//            
//            NSLog(@"Sharing to camera status %@.", error);
//        }];
    }
    
    NSLog(@"Sharing to camera called.");
}
-(void) shareFractalToPublicCloud {
    NSLog(@"Unimplemented sharing to public cloud.");
}
-(void) showSharedCompletionAlertWithText: (NSString*) alertText error: (NSError*) error {
    
    NSString* successText;
    
    if (error==nil) {
        successText = [NSString stringWithFormat: @"Your fractal was shared to %@.", alertText];
    } else {
        successText = [NSString stringWithFormat: @"There was a problem sharing your fractal. \nError: %@", error];
    }
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Share Status"
                                                                   message: successText
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alert addAction: defaultAction];
    
    
    [self presentViewController:alert animated:YES completion:nil];
    
}
#pragma mark - UIScrollViewDelegate
-(UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.fractalView.superview;
}
-(void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    // TODO: if view is smaller than scrollview, center view in scrollview.
}
#pragma mark - control actions
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
    [self.fractal setTurningAngleAsDegrees:  @([self.fractal.turningAngleAsDegrees doubleValue] + 0.5)];
}
- (IBAction)decrementTurnAngle:(id)sender {
    [self.undoManager beginUndoGrouping];
    [self.fractal.managedObjectContext processPendingChanges];
    [self.fractal setTurningAngleAsDegrees:  @([self.fractal.turningAngleAsDegrees doubleValue] - 0.5)];
}

// TODO: copy app delegate saveContext method

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
    [self updateInterface];
}


- (void)undoManagerDidRedo:(NSNotification *)notification {
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
-(NSNumberFormatter*) percentFormatter {
    if (_percentFormatter == nil) {
        _percentFormatter = [[NSNumberFormatter alloc] init];
        _percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
    }
    return _percentFormatter;
}

-(void) dealloc {
    self.fractal = nil; // removes observers via custom setter call
}

@end
