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

#import "LSFractalGenerator.h"
#import "LSFractalRecursiveGenerator.h"

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

    [super viewDidLoad];
        
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
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    // Could use GLKVector2 but chose not to. This works at the expense of a little verbosity but avoiding adding GLK dependence.
    CGPoint currentCenter = self.view.center;
    CGPoint newCenter = CGPointMake(size.width/2.0, size.height/2.0);
    CGPoint translation = CGPointMake(newCenter.x-currentCenter.x, newCenter.y-currentCenter.y);
    CGPoint fractalCenter = [[self fractalLevelNLayer] position];
    CGPoint fractalNewPosition = CGPointMake(fractalCenter.x+translation.x, fractalCenter.y+translation.y);
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //
        self.fractalLevelNLayer.position = fractalNewPosition;
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //
    }];
//    subLayer.position = self.fractalView.center;
}


// TODO: generate a thumbnail whenever saving. add thumbnails to coreData
-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [UIView transitionWithView: self.view
                      duration:0.5
                       options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{ [self updateViewsForEditMode: editing]; }
                    completion:^(BOOL finished){ [self autoScale:nil]; }];
    
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
        
        [self refreshInterface];
        
    } else if ([[LSFractal appearanceProperties] containsObject: keyPath]) {
        
        [self refreshInterface];
        
    } else if ([[LSFractal productionRuleProperties] containsObject: keyPath] ||
               [keyPath isEqualToString: [LSReplacementRule rulesKey]] ||
               [keyPath isEqualToString: [LSReplacementRule contextRuleKey]]) {
        
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

-(CALayer*) fractalLevel0Layer {
    CALayer* subLayer;
    for (CALayer* layer in self.fractalViewLevel0.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevel0"]) {
            subLayer = layer;
            break;
        }
    }
    return subLayer;
}
-(CALayer*) fractalLevel1Layer {
    CALayer* subLayer;
    for (CALayer* layer in self.fractalViewLevel1.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevel1"]) {
            subLayer = layer;
            break;
        }
    }
    return subLayer;
}
-(CALayer*) fractalLevel2Layer {
    CALayer* subLayer;
    for (CALayer* layer in self.fractalViewLevel2.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevel2"]) {
            subLayer = layer;
            break;
        }
    }
    return subLayer;
}
-(CALayer*) fractalLevelNLayer {
    CALayer* subLayer;
    for (CALayer* layer in self.fractalView.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevelN"]) {
            subLayer = layer;
            break;
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
-(void) updateGeneratorsForFractal:(LSFractal *)fractal {
    if (fractal) {
        // If the generators have been created, the fractal needs to be replaced.
        if ([self.generatorsArray count] > 0) {
            for (LSFractalGenerator* generator in self.generatorsArray) {
                generator.fractal = fractal;
            }
        } else {
            [self setupRecursiveLevelGeneratorForFractal: fractal View: self.fractalView name: @"fractalLevelN" margin: 50.0 forceLevel: -1];
//            [self setupLevelGeneratorForFractal: fractal View: self.fractalView name: @"fractalLevelN" margin: 50.0 forceLevel: -1];
            [self setupLevelGeneratorForFractal: fractal View: self.fractalViewLevel0 name: @"fractalLevel0" margin: 10.0 forceLevel: 0];
            [self setupLevelGeneratorForFractal: fractal View: self.fractalViewLevel1 name: @"fractalLevel1" margin: 10.0 forceLevel: 1];
            [self setupLevelGeneratorForFractal: fractal View: self.fractalViewLevel2 name: @"fractalLevel2" margin: 10.0 forceLevel: 2];
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

-(void) setupLevelGeneratorForFractal: (LSFractal*) fractal View: (UIView*) aView name: (NSString*) name margin: (CGFloat) margin forceLevel: (NSInteger) aLevel {
//    CATiledLayer* aLayer = [[CATiledLayer alloc] init];
//    aLayer.tileSize = CGSizeMake(5120.0, 5120.0);
//    CAShapeLayer* aLayer = [[CAShapeLayer alloc] init];
    CALayer* aLayer = [[CALayer alloc] init];
    aLayer.drawsAsynchronously = YES;
    aLayer.name = name;
    aLayer.needsDisplayOnBoundsChange = YES;
    aLayer.speed = 1.0;
//    aLayer.contentsScale = 2.0 * aView.layer.contentsScale;
    
    [self fitLayer: aLayer inLayer: aView.layer margin: margin];
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
-(void) setupRecursiveLevelGeneratorForFractal: (LSFractal*) fractal View: (UIView*) aView name: (NSString*) name margin: (CGFloat) margin forceLevel: (NSInteger) aLevel {
    //    CATiledLayer* aLayer = [[CATiledLayer alloc] init];
    //    aLayer.tileSize = CGSizeMake(5120.0, 5120.0);
    //    CAShapeLayer* aLayer = [[CAShapeLayer alloc] init];
    CALayer* aLayer = [[CALayer alloc] init];
    aLayer.drawsAsynchronously = YES;
    aLayer.name = name;
    aLayer.needsDisplayOnBoundsChange = YES;
    aLayer.speed = 1.0;
    //    aLayer.contentsScale = 2.0 * aView.layer.contentsScale;
    
    [self fitLayer: aLayer inLayer: aView.layer margin: margin];
    
    CGRect bounds = aLayer.bounds;
    aLayer.bounds = CGRectInset(bounds, -4000.0, -4000.0);


    [aView.layer addSublayer: aLayer];
//    aLayer.anchorPoint = CGPointMake(0.0, 0.0);
    
    LSFractalRecursiveGenerator* generator = [[LSFractalRecursiveGenerator alloc] init];
    
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
    self.hudLevelStepper.value = [self.fractal.level integerValue];
    //    
    self.hudText2.text =[self.twoPlaceFormatter stringFromNumber: @(degrees([self.fractal.turningAngle doubleValue]))];
}

-(void) refreshLayers {
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

    MBColor* backgroundColor = self.fractal.backgroundColor;
    if (backgroundColor) {
        self.fractalView.backgroundColor = [backgroundColor asUIColor];
    } else {
        self.fractalView.backgroundColor = [UIColor clearColor];
    }
}

-(void) refreshContents {
//    [self reloadLabels];
    [self refreshValueInputs];
    [self refreshLayers];
    [self configureNavButtons];
}

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
- (IBAction)cancelEdit:(id)sender {
    self.cancelled = YES;
    [self setEditing: NO animated: YES];
}

-(void) updateViewsForEditMode:(BOOL)editing {
    
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];

    if (!editing) {
        [self fullScreenOn];
        
    } else {
        [self fullScreenOff];
    }
}

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

- (IBAction)shareButtonPressed:(id)sender {
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

- (IBAction)playButtonPressed:(id)sender {
    CGPathRef thePath = (CGPathRef)[(LSFractalGenerator*)[self.generatorsArray firstObject] fractalCGPathRef];
    
    CALayer* turtle = [[CALayer alloc] init];
    UIImage* turtleImage = [UIImage imageNamed: @"emptyStatus"];
    turtle.contents = (__bridge id)([turtleImage CGImage]);
    turtle.bounds = CGRectMake(0., 0., turtleImage.size.width, turtleImage.size.height);
    turtle.position = CGPointMake(-10000.0, -10000.0);
    
    CALayer* fractalLayer = self.fractalLevelNLayer;
    [fractalLayer addSublayer: turtle];

    CGRect layerBounds = fractalLayer.bounds;
    CGFloat layerScale = fractalLayer.contentsScale;
    CGFloat flipFactor = fractalLayer.contentsAreFlipped ? -1.0 : 1.0;
    
    CGAffineTransform pathTransform = CGAffineTransformIdentity;
    // flip the Y axis so +Y is up direction from origin
    CGAffineTransform scaleTrans = CGAffineTransformScale(pathTransform, 1.0/layerScale, flipFactor/layerScale);
    CGAffineTransform moveTrans = CGAffineTransformTranslate(scaleTrans, layerScale*layerBounds.origin.x, flipFactor*layerScale*(layerBounds.origin.y + layerBounds.size.height));
    
    CGPathRef transPath = CGPathCreateCopyByTransformingPath(thePath, &moveTrans);
    
    NSMutableArray* countArray = [NSMutableArray arrayWithObjects: @0, nil];
    CGPathApply(transPath, (void *)countArray, countPathElements);
    // want the animatino to use less time for fewer elements
    NSInteger elementCount = [countArray[0] integerValue];
    CGFloat duration = 10.0;
    if (elementCount < 100) {
        duration = 5.0;
    } else if (elementCount < 1000) {
        duration = 10.0;
    } else if (elementCount <10000) {
        duration = 20.0;
    } else {
        duration = 30.0;
    }
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        // This will be performed after actions added after the block
        CGPathRelease(transPath);
        [turtle removeFromSuperlayer];
        self.playButton.enabled = YES;
        
        // check for leak
    }];
    
    self.playButton.enabled = NO;
    
    CAKeyframeAnimation * theAnimation;
    
    // Create the animation object, specifying the position property as the key path.
    theAnimation=[CAKeyframeAnimation animationWithKeyPath:@"position"];
    //        theAnimation.rotationMode = kCAAnimationRotateAuto;
    theAnimation.calculationMode = kCAAnimationPaced;
    theAnimation.path = transPath;
    theAnimation.duration = duration;
    
    turtle.hidden = NO;
    [turtle addAnimation:theAnimation forKey:@"position"];
    
    [CATransaction commit];
    
}
static void countPathElements(void *info, const CGPathElement *element) {
    
    NSMutableArray *countArray = (__bridge NSMutableArray *)info;
    countArray[0] = [NSNumber numberWithInteger: ([countArray[0] integerValue]+1)];
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
    [self convertPanToAngleAspectChange: gestureRecognizer
                               subLayer: self.fractalLevelNLayer
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
                               subLayer: self.fractalLevel0Layer
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
                               subLayer: self.fractalLevel1Layer
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
                               subLayer: self.fractalLevel2Layer
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
                             subLayer: (CALayer*) subLayer
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
        
        [self.undoManager beginUndoGrouping];
        [self.fractal.managedObjectContext processPendingChanges];
        
        initialPosition = subLayer.position;
        
        if (anglePath) {
            initialAngleDegrees =  floorf(100.0 * degrees([[self.fractal valueForKey: anglePath] doubleValue])) / 100.0;
        }
        if (aspectPath) {
            initialWidth = floorf(100.0 * [[self.fractal valueForKey: aspectPath] doubleValue]) / 100.0;
        }
    
//        initialAngleDegrees = [self.fractal.turningAngleAsDegrees doubleValue];
//        initialWidth = [self.fractal.lineWidth doubleValue];
        
        
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
//                [self.fractal setTurningAngleAsDegrees:  @(newAngleDegrees)];
                
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
    }
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
#pragma message "Unused code"
- (IBAction)toggleAutoScale:(id)sender {
    UIView* strongFractalView = self.fractalView;
    
    for (id object in self.generatorsArray) {
        if ([object isKindOfClass: [LSFractalGenerator class]]) {
            LSFractalGenerator* generator = (LSFractalGenerator*) object;
            generator.autoscale = !generator.autoscale;
            NSLog(@"autoscale: %u;", generator.autoscale);
            if (generator.autoscale) {
                // refit view frame and refresh layer
                strongFractalView.transform = CGAffineTransformIdentity;
                CGPoint containerOrigin = self.fractalViewParent.bounds.origin;
                CGSize containerSize = self.fractalViewParent.bounds.size;
                CGFloat toolbarHeight = 45.0;
                CGRect boundsMinusToolbar = CGRectMake(containerOrigin.x,
                                                       (containerOrigin.y + toolbarHeight),
                                                       containerSize.width,
                                                       (containerSize.height - toolbarHeight));
                
                strongFractalView.frame = boundsMinusToolbar;
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

- (IBAction)toggleFullScreen:(id)sender {
    if (self.fractalViewLevel0.superview.hidden == YES) {
        [self fullScreenOff];
    } else {
        [self fullScreenOn];
    }
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
-(NSNumberFormatter*) percentFormatter {
    if (_percentFormatter == nil) {
        _percentFormatter = [[NSNumberFormatter alloc] init];
        _percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
    }
    return _percentFormatter;
}

-(void) dealloc {
    self.fractal = nil; // removes observers via custom setter call
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }
}

@end
