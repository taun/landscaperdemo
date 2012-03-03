//
//  MBLSFractalEditViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalEditViewController.h"
#import "MBFractalPropertyTableHeaderView.h"
#import "LSFractal+addons.h"
#import "LSFractalGenerator.h"
#import "LSReplacementRule.h"
#import "MBColor+addons.h"
#import "MBPortalStyleView.h"

#import "MBStepperTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

#include <math.h>

#define HUD_CORNER_RADIUS 12.0
#define HUD_OPACITY 1

static inline double radians (double degrees) {return degrees * M_PI/180.0;}
static inline double degrees (double radians) {return radians * 180.0/M_PI;}

@interface MBLSFractalEditViewController () {
    __strong NSArray* _fractalPropertiesAppearanceSectionDefinitions;
}

/*!
 for tracking which text input field has the current focus.
 allows using a custom input keyboard.
 Want to change to a popover at some point.
 */
@property (weak, nonatomic) UITextField*            activeTextField;

@property (nonatomic, assign) BOOL                  startedInLandscape;

@property (nonatomic, readonly) NSArray*            fractalPropertiesAppearanceSectionDefinitions;

@property (nonatomic, strong) NSMutableDictionary*  appearanceCellIndexPaths;
@property (nonatomic, strong) NSMutableDictionary*  rulesCellIndexPaths;

/*!
 Custom keyboard for inputting fractal axioms and rules.
 Change to a popover?
 */
@property (strong, nonatomic) IBOutlet FractalDefinitionKeyboardView *fractalInputControl;

/*
 So a setNeedsDisplay can be sent to each layer when a fractal property is changed.
 */
@property (nonatomic, strong) NSMutableArray* fractalDisplayLayersArray;
/*
 a generator for each level being displayed.
 */
@property (nonatomic, strong) NSMutableArray* generatorsArray; 

@property (nonatomic, strong, readonly) NSSet*   editControls;

@property (nonatomic, assign) double viewNRotationFromStart;

@property (nonatomic, strong) NSNumberFormatter*    twoPlaceFormatter;

-(void) fitLayer: (CALayer*) layerA inLayer: (CALayer*) layerB margin: (double) margin;

-(void) configureRightButtons;
-(void) setEditMode: (BOOL) editing;
-(void) setupLevelGeneratorForView: (UIView*) aView name: (NSString*) name forceLevel: (NSInteger) aLevel;
-(void) reloadLabels;
-(void) refreshValueInputs;
-(void) refreshLayers;
-(void) refreshContents;

-(void) useFractalDefinitionRulesView;
-(void) useFractalDefinitionAppearanceView;
-(void) loadDefinitionViews;

@end

/*!
 Could setup KVO for model proerties to fields.
 Would be same as using bindings.
 */

@implementation MBLSFractalEditViewController

@synthesize fractalDefinitionAppearanceView = _fractalDefinitionAppearanceView;
@synthesize fractalDefinitionRulesView = _fractalDefinitionRulesView;
@synthesize fractalDefinitionPlaceholderView = _fractalDefinitionPlaceholderView;
@synthesize replacementRulesArray = _replacementRulesArray;
@synthesize portraitViewFrames = _portraitViewFrames;
@synthesize colorPopover = _colorPopover;
@synthesize placeHolderBounds = _placeHolderBounds;
@synthesize placeHolderCenter = _placeHolderCenter;
@synthesize currentFractal = _currentFractal;
@synthesize coloringKey = _coloringKey;
@synthesize twoPlaceFormatter = _twoPlaceFormatter;
@synthesize aCopyButtonItem = _aCopyButtonItem;
@synthesize fractalPropertyTableHeaderView = _fractalPropertyTableHeaderView;
@synthesize fractalName = _fractalName, fractalCategory = _fractalCategory;
@synthesize fractalDescriptor = _fractalDescriptor;
@synthesize fractalAxiom = _fractalAxiom;
@synthesize fractalInputControl = _fractalInputControl;
@synthesize activeTextField = _activeField;
@synthesize fractalViewLevel0 = _fractalViewLevel0;
@synthesize fractalViewLevel1 = _fractalViewLevel1;
@synthesize fractalViewLevelN = _fractalViewLevelN;
@synthesize levelSliderContainerView = _levelSliderContainerView;
@synthesize fractalViewLevelNHUD = _fractalViewLevelNHUD;
@synthesize fractalLineLength = _lineLengthTextField;
@synthesize lineLengthStepper = _lineLengthStepper;
@synthesize fractalWidth = _fractalWidth;
@synthesize widthStepper = _widthStepper;
@synthesize widthSlider = _widthSlider;
@synthesize fractalTurningAngle = _turnAngleTextField;
@synthesize turnAngleStepper = _turnAngleStepper;
@synthesize fractalBaseAngle = _fractalBaseAngle;
@synthesize fractalLevel = _fractalLevel;
@synthesize levelStepper = _levelStepper;
@synthesize levelSlider = _levelSlider;
@synthesize strokeSwitch = _strokeSwitch;
@synthesize fillColorButton = _fillColorButton;
@synthesize strokeColorButton = _strokeColorButton;
@synthesize fillSwitch = _fillSwitch;
@synthesize fractalPropertiesView = _fractalPropertiesView;
@synthesize fractalPropertiesTableView = _fractalPropertiesTableView;
@synthesize fractalViewLevelNLabel = _fractalViewLevelNLabel;

@synthesize fractalDisplayLayersArray = _fractalDisplayLayersArray;
@synthesize generatorsArray = _generatorsArray;
@synthesize editControls = _editControls;
@synthesize viewNRotationFromStart = _viewNRotationFromStart;
@synthesize startedInLandscape = _startedInLandscape;
@synthesize appearanceCellIndexPaths = _appearanceCellIndexPaths;
@synthesize rulesCellIndexPaths = _rulesCellIndexPaths;
@synthesize fractalPropertiesAppearanceSectionDefinitions = _fractalPropertiesAppearanceSectionDefinitions;

@synthesize undoManager = _undoManager;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo {
    CFDictionaryRef boundsDict = CGRectCreateDictionaryRepresentation(bounds);
    NSString* boundsDescription = [(__bridge NSString*)boundsDict description];
    CFRelease(boundsDict);
    
    NSLog(@"%@ = %@", boundsInfo,boundsDescription);
}



#pragma mark - Fractal Property KVO
//TODO: change so replacementRulesArray is cached and updated when rules are updated.
-(void) setCurrentFractal:(LSFractal *)fractal {
    if (_currentFractal != fractal) {
        
        NSSet* propertiesToObserve = [[LSFractal productionRuleProperties] setByAddingObjectsFromSet:[LSFractal appearanceProperties]];
        propertiesToObserve = [propertiesToObserve setByAddingObjectsFromSet: [LSFractal lableProperties]];
        
        for (NSString* keyPath in propertiesToObserve) {
            [_currentFractal removeObserver: self forKeyPath: keyPath];
            [fractal addObserver: self forKeyPath:keyPath options: 0 context: NULL];
        }
        
        _currentFractal = fractal;
        NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey: @"contextString" ascending: YES];
        NSArray* descriptors = [[NSArray alloc] initWithObjects: sort, nil];
        self.replacementRulesArray = [_currentFractal.replacementRules sortedArrayUsingDescriptors: descriptors];
        
        // If the generators have been created, the fractal needs to be replaced.
        if ([self.generatorsArray count] > 0) {
            for (LSFractalGenerator* generator in self.generatorsArray) {
                generator.fractal = _currentFractal;
            }
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([[LSFractal productionRuleProperties] containsObject: keyPath] || [keyPath isEqualToString:  @"replacementString"]) {
        // productionRuleChanged
        [self refreshValueInputs];
        [self refreshLayers];
    } else if ([[LSFractal appearanceProperties] containsObject: keyPath]) {
        [self refreshValueInputs];
        [self refreshLayers];
    } else if ([[LSFractal lableProperties] containsObject: keyPath]) {
        [self reloadLabels];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - custom setter getters
//enum AppearanceIndex {
//    TurningAngle=0,
//    TurningAngleIncrement,
//    LineWidth,
//    LineWidthIncrement,
//    LineLengthScaleFactor
//};

-(NSArray*) fractalPropertiesAppearanceSectionDefinitions {
    if (_fractalPropertiesAppearanceSectionDefinitions == nil) {
        NSDictionary* turningAngle = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                   @"Angle",@"label",
                                   @"Plus rotate CC dark.png", @"imageName",
                                   [NSNumber numberWithDouble: -180.0], @"minimumValue",
                                   [NSNumber numberWithDouble: 181.0], @"maximumValue",
                                   [NSNumber numberWithDouble: 1.0], @"stepValue",
                                   @"turningAngleAsDegree", @"propertyValueKey",
                                   @"turningAngleInputChanged:", @"actionSelectorString",
                                   nil];
        
        NSDictionary* turningAngleIncrement = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                               @"A Increment",@"label",
                                               [NSNumber numberWithDouble: -180.0], @"minimumValue",
                                               [NSNumber numberWithDouble: 181.0], @"maximumValue",
                                               [NSNumber numberWithDouble: 0.25], @"stepValue",
                                               @"turningAngleIncrementAsDegree", @"propertyValueKey",
                                               @"turningAngleIncrementInputChanged:", @"actionSelectorString",
                                               nil];
        
        NSDictionary* lineWidth = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                               @"Width",@"label",
                                               [NSNumber numberWithDouble: 1.0], @"minimumValue",
                                               [NSNumber numberWithDouble: 20.0], @"maximumValue",
                                               [NSNumber numberWithDouble: 1.0], @"stepValue",
                                               @"lineWidth", @"propertyValueKey",
                                               @"lineWidthInputChanged:", @"actionSelectorString",
                                               nil];
        
        NSDictionary* lineWidthIncrement = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                   @"L Increment",@"label",
                                   [NSNumber numberWithDouble: 1.0], @"minimumValue",
                                   [NSNumber numberWithDouble: 20.0], @"maximumValue",
                                   [NSNumber numberWithDouble: 0.25], @"stepValue",
                                   @"lineWidthIncrement", @"propertyValueKey",
                                   @"lineWidthIncrementInputChanged:", @"actionSelectorString",
                                   nil];
        
        NSDictionary* lineLengthScaleFactor = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                   @"Length Scale",@"label",
                                   [NSNumber numberWithDouble: 0.0], @"minimumValue",
                                   [NSNumber numberWithDouble: 10.0], @"maximumValue",
                                   [NSNumber numberWithDouble: 0.1], @"stepValue",
                                   @"lineLengthScaleFactor", @"propertyValueKey",
                                   @"lineLengthScaleFactorInputChanged:", @"actionSelectorString",
                                   nil];
        
        _fractalPropertiesAppearanceSectionDefinitions = [[NSArray alloc] initWithObjects: 
                                                          turningAngle, 
                                                          turningAngleIncrement,
                                                          lineWidth,
                                                          lineWidthIncrement,
                                                          lineLengthScaleFactor,
                                                          nil];
    }
    return _fractalPropertiesAppearanceSectionDefinitions;
}

-(NSMutableDictionary*) appearanceCellIndexPaths {
    if (_appearanceCellIndexPaths == nil) {
        _appearanceCellIndexPaths = [[NSMutableDictionary alloc] initWithCapacity: 5];
    }
    return _appearanceCellIndexPaths;
}

-(NSMutableDictionary*) rulesCellIndexPaths {
    if (_rulesCellIndexPaths == nil) {
        _rulesCellIndexPaths = [[NSMutableDictionary alloc] initWithCapacity: 5];
    }
    return _rulesCellIndexPaths;
}

-(void) setReplacementRulesArray:(NSArray *)replacementRulesArray {
    if (replacementRulesArray != _replacementRulesArray) {
        for (LSReplacementRule* rule in _replacementRulesArray) {
            NSString* keyPath = [NSString stringWithFormat: @"replacementString"];
            [rule removeObserver: self forKeyPath: keyPath];
        }
        for (LSReplacementRule* rule in replacementRulesArray) {
            NSString* keyPath = [NSString stringWithFormat: @"replacementString"];
            [rule addObserver: self forKeyPath: keyPath options: 0 context: NULL];
        }
        _replacementRulesArray = replacementRulesArray;
    }
}

-(UIBarButtonItem*) aCopyButtonItem {
    if (_aCopyButtonItem == nil) {
        _aCopyButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Copy" 
                                                            style:UIBarButtonItemStyleBordered 
                                                           target:self 
                                                           action:@selector(copyFractal:)];

    }
    return _aCopyButtonItem;
}

-(UIPopoverController*) colorPopover {
    if (_colorPopover == nil) {
        UIColor* color = [self.currentFractal lineColorAsUI];
        ColorPickerController* colorPicker = [[ColorPickerController alloc] initWithColor: color andTitle: @"Pick a Fill Color"];
        colorPicker.delegate = self;
        colorPicker.contentSizeForViewInPopover = CGSizeMake(400, 300);

        UINavigationController* navCon = [[UINavigationController alloc] initWithRootViewController: colorPicker];
        
        navCon.contentSizeForViewInPopover = CGSizeMake(400, 300);
        navCon.modalInPopover = YES;
        
        _colorPopover = [[UIPopoverController alloc] initWithContentViewController: navCon];
        _colorPopover.delegate = (id<UIPopoverControllerDelegate>)self;
        _colorPopover.popoverContentSize = CGSizeMake(400, 300);
    }
    return _colorPopover;
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

-(NSSet*) editControls {
    if (_editControls == nil) {
        _editControls = [[NSSet alloc] initWithObjects: 
                         self.fractalName,
                         self.fractalCategory,
                         self.fractalDescriptor,
                         self.levelSlider,
                         nil];
        //                         self.lineLengthStepper,
        //                         self.turnAngleStepper,
        //                         self.widthStepper,
        //                         self.widthSlider,
        //                         self.strokeSwitch,
        //                         self.strokeColorButton,
        //                         self.fillSwitch,
        //                         self.fillColorButton,
        //                         self.fractalAxiom,
        //                         self.levelStepper,
    }
    return _editControls;
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

-(void) setFractalViewLevel0:(UIView *)fractalViewLevel0 {
    _fractalViewLevel0 = fractalViewLevel0;
    UIRotationGestureRecognizer* rgr = [[UIRotationGestureRecognizer alloc] 
                                        initWithTarget: self 
                                        action: @selector(rotateTurningAngle:)];
    
    [_fractalViewLevel0 addGestureRecognizer: rgr];
    
    [self setupLevelGeneratorForView: _fractalViewLevel0 name: @"fractalLevel0" forceLevel: 0];
}

-(void) setFractalViewLevelN:(UIView *)fractalViewLevelN {
    _fractalViewLevelN = fractalViewLevelN;
    UIRotationGestureRecognizer* rgr = [[UIRotationGestureRecognizer alloc] 
                                        initWithTarget: self 
                                        action: @selector(rotateFractal:)];
    
    [_fractalViewLevelN addGestureRecognizer: rgr];
    
    UILongPressGestureRecognizer* lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget: self
                                          action: @selector(magnifyFractal:)];
    
    [_fractalViewLevelN addGestureRecognizer: lpgr];
    
    [self setupLevelGeneratorForView: _fractalViewLevelN name: @"fractalLevelN" forceLevel: -1];
}

-(void) setFractalViewLevelNHUD: (UIView*) fractalViewLevelNHUD {
    _fractalViewLevelNHUD = fractalViewLevelNHUD;

    CALayer* background = _fractalViewLevelNHUD.layer; 
    
    background.cornerRadius = HUD_CORNER_RADIUS;
    background.borderWidth = 1.6;
    background.borderColor = [UIColor grayColor].CGColor;

    background.shadowOffset = CGSizeMake(0, 3.0);
    background.shadowOpacity = 0.6;
}

#pragma mark - View lifecycle

- (void)updateRightBarButtonItemState {
    // Conditionally enable the right bar button item -- it should only be enabled if the book is in a valid state for saving.
    self.navigationItem.rightBarButtonItem.enabled = [self.currentFractal validateForUpdate:NULL];
    self.navigationItem.leftBarButtonItem.enabled = [self.currentFractal validateForUpdate:NULL];
}   

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void) fitLayer: (CALayer*) layerInner inLayer: (CALayer*) layerOuter margin: (double) margin {
    CGRect boundsOuter = layerOuter.bounds;
    CGRect boundsInner = CGRectInset(boundsOuter, margin, margin);
    layerInner.bounds = boundsInner;
    layerInner.position = CGPointMake(boundsOuter.size.width/2, boundsOuter.size.height/2);
}

-(void) setupLevelGeneratorForView: (UIView*) aView name: (NSString*) name forceLevel: (NSInteger) aLevel {
    CALayer* aLayer = [[CALayer alloc] init];
    aLayer.name = name;
    aLayer.needsDisplayOnBoundsChange = YES;
    
    [self fitLayer: aLayer inLayer: aView.layer margin: 10];        
    [aView.layer addSublayer: aLayer];

    
    LSFractalGenerator* generator = [[LSFractalGenerator alloc] init];
    
    if (generator) {
        NSUInteger arrayCount = [self.generatorsArray count];
        
        generator.fractal = self.currentFractal;
        generator.forceLevel = aLevel;
        
        aLayer.delegate = generator;
        [aLayer setValue: [NSNumber numberWithInteger: arrayCount] forKey: @"arrayCount"];
        
        [self.fractalDisplayLayersArray addObject: aLayer];
        [self.generatorsArray addObject: generator];
    }
}

-(void) reloadLabels {
    self.fractalName.text = self.currentFractal.name;
    self.fractalCategory.text = self.currentFractal.category;
    self.fractalDescriptor.text = self.currentFractal.descriptor;
}

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
    self.turnAngleStepper.value = [[self.currentFractal turningAngleAsDegree] doubleValue];
    
//    
//    self.fractalLevel.text = [self.currentFractal.level stringValue];
//    self.levelStepper.value = [self.currentFractal.level doubleValue];
    self.levelSlider.value = [self.currentFractal.level doubleValue];
//    
//    self.strokeSwitch.on = [self.currentFractal.stroke boolValue];
//    self.fillSwitch.on = [self.currentFractal.fill boolValue];
}

-(void) refreshLayers {
    self.fractalViewLevelNLabel.text = [self.currentFractal.level stringValue];
    self.fractalBaseAngle.text = [self.twoPlaceFormatter stringFromNumber: [self.currentFractal baseAngleAsDegree]];
    
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
    [self reloadLabels];
    [self refreshValueInputs];
    [self refreshLayers];
}

-(void) loadDefinitionViews {
    [[NSBundle mainBundle] loadNibNamed: @"FractalDefinitionRulesView" owner: self options: nil];
    [[NSBundle mainBundle] loadNibNamed: @"FractalDefinitionAppearanceView" owner: self options: nil];
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

//TODO: add Undo and Redo buttons for editing
- (void) configureRightButtons {
    
    NSArray* rightButtons;
    
    if ([self.currentFractal.isImmutable boolValue]) {
        // no edit button if it is read only
        rightButtons = [[NSArray alloc] initWithObjects: self.aCopyButtonItem, nil];
        self.navigationItem.title = [NSString stringWithFormat: @"%@ (read-only)", self.title];
    } else if (self.editing) {
        // include edit button but no copy button
        rightButtons = [[NSArray alloc] initWithObjects: self.editButtonItem, nil];
    } else {
        // copy and edit button
        UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace 
                                                                               target: self 
                                                                               action:nil];
        
        rightButtons = [[NSArray alloc] initWithObjects: self.editButtonItem, space, space, self.aCopyButtonItem, nil];
    }
    self.navigationItem.rightBarButtonItems = rightButtons;
}

- (void)viewDidLoad
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    [super viewDidLoad];
    
    if (UIDeviceOrientationIsLandscape(self.interfaceOrientation)) {
        self.startedInLandscape = YES;
    } else { 
        self.startedInLandscape = NO;
    }
    
    
    
    _placeHolderCenter = self.fractalDefinitionPlaceholderView.center;
    _placeHolderBounds = self.fractalDefinitionPlaceholderView.bounds;
    
    [[NSBundle mainBundle] loadNibNamed:@"MBFractalPropertyTableHeaderView" owner:self options:nil];
        
    UIView* header = self.fractalPropertyTableHeaderView;
    
    header.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.fractalPropertiesTableView.allowsSelectionDuringEditing = YES;
    self.fractalPropertiesTableView.tableHeaderView = header;
    
//    [self.fractalDefinitionPlaceholderView removeFromSuperview];
//    [self loadDefinitionViews];
//    [self useFractalDefinitionRulesView];
        
    [self configureRightButtons];
    
    [self setEditMode: NO];
    
    [self setupLevelGeneratorForView: self.fractalViewLevel1 name: @"fractalLevel1" forceLevel: 1];
        
    self.fractalAxiom.inputView = self.fractalInputControl.view;
        
    CGAffineTransform rotateCC = CGAffineTransformMakeRotation(-M_PI_2);
    [self.levelSliderContainerView setTransform: rotateCC];
    
    [self refreshContents];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [self.navigationController setToolbarHidden: NO animated: YES];
}

-(void)configureLandscapeViewFrames {
    
    if (self.portraitViewFrames != nil) {
        // should always not be nil
        CGRect portrait0 = self.fractalViewLevel0.superview.frame;
        CGRect portrait1 = self.fractalViewLevel1.superview.frame;
        CGRect portraitN = self.fractalViewLevelN.superview.frame;
        
        CGRect new0;
        CGRect new1;
        CGRect newN;

        
        newN = CGRectUnion(portrait0, portrait1);
        
        // Portrait
        // Swap position of N with 0 & 1
        CGRectDivide(portraitN, &new0, &new1, portraitN.size.width/2.0, CGRectMinXEdge);        
        [UIView animateWithDuration:1.0 animations:^{
            // move N to empty spot
            self.fractalViewLevelN.superview.frame = newN;
            
            // move 0 & 1 to empty N spot
            self.fractalViewLevel0.superview.frame = new0;
            self.fractalViewLevel1.superview.frame = new1;
        }];
        
    }
}

-(void) restorePortraitViewFrames {
    if (self.portraitViewFrames != nil) {
        // should always not be nil
        CGRect portrait0;
        CGRect portrait1;
        CGRect portraitN;

        CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)[self.portraitViewFrames objectForKey:@"frame0"], &portrait0);
        CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)[self.portraitViewFrames objectForKey:@"frame1"], &portrait1);
        CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)[self.portraitViewFrames objectForKey:@"frameN"], &portraitN);

        [UIView animateWithDuration:1.0 animations:^{
            // move N to empty spot
            self.fractalViewLevelN.superview.frame = portraitN;
            
            // move 0 & 1 to empty N spot
            self.fractalViewLevel0.superview.frame = portrait0;
            self.fractalViewLevel1.superview.frame = portrait1;
        }];

    }
}

/*
 When this is first called, the dimensions are the nib dimensions.
 We can capture the nib portrait intent here then use it later for
 calculating landscape and returning to portrait.
 */
-(void) viewWillLayoutSubviews {

//    CGRect viewBounds = self.view.bounds;
    //NSLog(@"%@ Bounds = %g,%g,%g,%g", NSStringFromSelector(_cmd),viewBounds.origin.x,viewBounds.origin.y,viewBounds.size.width, viewBounds.size.height);

    if (self.portraitViewFrames == nil) {
        
        double barHeight = self.navigationController.navigationBar.frame.size.height;
        //NSLog(@"bar height = %g;", barHeight);
        CGRect frame = self.fractalViewLevelN.superview.frame;
        CGRect frameNLessNav = CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height-barHeight-MBPORTALMARGIN);
        NSDictionary* frame0 = (__bridge_transfer NSDictionary*) CGRectCreateDictionaryRepresentation(self.fractalViewLevel0.superview.frame);
        NSDictionary* frame1 = (__bridge_transfer NSDictionary*) CGRectCreateDictionaryRepresentation(self.fractalViewLevel1.superview.frame);
        NSDictionary* frameN = (__bridge_transfer NSDictionary*) CGRectCreateDictionaryRepresentation(frameNLessNav);

        self.portraitViewFrames = [[NSDictionary alloc] initWithObjectsAndKeys: frame0, @"frame0", frame1, @"frame1", frameN, @"frameN", nil];
        
        //NSLog(@"%@ setPortraitViewFrames frame0 = %@; frame1 = %@; frameN = %@;", NSStringFromSelector(_cmd), frame0, frame1, frameN);

    }
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
    //NSLog(@"%@ Bounds = %g,%g,%g,%g", NSStringFromSelector(_cmd),viewBounds.origin.x,viewBounds.origin.y,viewBounds.size.width, viewBounds.size.height);

    if (self.startedInLandscape && UIDeviceOrientationIsLandscape(self.interfaceOrientation) && (viewBounds.size.width>viewBounds.size.height)) {
        self.startedInLandscape = NO;
        NSLog(@"%@ Started in landscape, orientation = %u; 1,2 = portrait; 3,4 = landscape", NSStringFromSelector(_cmd), self.interfaceOrientation);
        // only called here when first loaded in landscape orientation and with landscape bounds
        [self configureLandscapeViewFrames];
    }
    
    for (CALayer* layer in self.fractalViewLevel0.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevel0"]) {
            [self fitLayer: layer inLayer: self.fractalViewLevel0.superview.layer margin: 5];
            // assumes fractalViewLevel0 is a subview and fitted to a portal view which has
            // a layer with a margin.
            // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
        }
    }
    for (CALayer* layer in self.fractalViewLevel1.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevel1"]) {
            [self fitLayer: layer inLayer: self.fractalViewLevel1.superview.layer margin: 5];
            // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
        }
    }
    for (CALayer* layer in self.fractalViewLevelN.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevelN"]) {
            [self fitLayer: layer inLayer: self.fractalViewLevelN.superview.layer margin: 5];
            // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
        }
    }
}

-(void) setEditMode: (BOOL) editing {
    UIColor* white = [UIColor colorWithWhite: 1.0 alpha: 1.0];
    for (UIControl* control in self.editControls) {
        control.enabled = editing;
        
        if ([control isKindOfClass:[UITextField class]]) {
            UITextField* tf = (UITextField*) control;
            tf.backgroundColor = editing ? white : nil;
            tf.opaque = editing;
            tf.borderStyle = editing ? UITextBorderStyleRoundedRect : UITextBorderStyleNone;

        } else if ([control isKindOfClass:[UITextView class]]) {
            UITextView* tf = (UITextView*) control;
            tf.editable = editing;
            tf.backgroundColor = editing ? white : nil;
            tf.opaque = editing;

        } else  if ([control isKindOfClass:[UIStepper class]]) {
            UIStepper* tf = (UIStepper*) control;
            tf.hidden = !editing;
        } else if ([control isKindOfClass:[UISwitch class]]) {
            UISwitch* tf = (UISwitch*) control;
            tf.hidden = !editing;
        } else if ([control isKindOfClass:[UIButton class]]) {
//            UIButton* tf = (UIButton*) control;
        }
    }
    [self configureRightButtons];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    // Hide the back button when editing starts, and show it again when editing finishes.
    [self.navigationItem setHidesBackButton:editing animated:animated];
    
    [self setEditMode: editing];
    [self.fractalPropertiesTableView setEditing: editing animated: animated];
    /*
     When editing starts, create and set an undo manager to track edits. Then register as an observer of undo manager change notifications, so that if an undo or redo operation is performed, the table view can be reloaded.
     When editing ends, de-register from the notification center and remove the undo manager, and save the changes.
     */
    if (editing) {
        self.navigationItem.title = [NSString stringWithFormat: @"%@ (editing)", self.title];
        [self setUpUndoManager];
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];

        UIBarButtonItem *spaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        
        spaceButton.width = 30.0;

        UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(info:)];
        
        NSArray* lefties = [[NSArray alloc] initWithObjects: cancelButton, spaceButton, infoButton, nil];
        
        self.navigationItem.leftBarButtonItems = lefties;
        self.navigationItem.leftItemsSupplementBackButton = YES;
    }
    else {
        self.navigationItem.title = self.title;
        [self cleanUpUndoManager];
        // Save the changes.
        NSError *error;
        if (![self.currentFractal.managedObjectContext save:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            // exit(-1);  // Fail
            // TODO: alert here?
        }
        NSMutableArray* lefties = [self.navigationItem.leftBarButtonItems mutableCopy];
        [lefties removeLastObject];
        self.navigationItem.leftBarButtonItems = lefties;
        [self becomeFirstResponder];
    }
}

-(IBAction) info:(id)sender {
    
}

- (IBAction)cancel:(id)sender {
    [self.undoManager undo];
    [self setEditMode: NO];
    [self cleanUpUndoManager];
}

- (void)viewDidUnload
{
    //should save be here or at higher level
    // Only need to save if still in edit mode
    if (self.editing) {
        [self.currentFractal.managedObjectContext save: nil];
    }
    self.fractalInputControl.delegate = nil;
    [self setFractalInputControl: nil];
    
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }

    // removes observers
    [self setReplacementRulesArray: nil];
    
    [self setColorPopover: nil];

    [self setFractalName:nil];
    [self setFractalDescriptor:nil];
    [self setFractalAxiom:nil];
    [self setFractalInputControl:nil];
    [self setFractalViewLevel0:nil];
    [self setFractalViewLevel1:nil];
    [self setFractalViewLevelN:nil];
    [self setFractalLineLength:nil];
    [self setLineLengthStepper:nil];
    [self setFractalTurningAngle:nil];
    [self setTurnAngleStepper:nil];

    [self setFractalPropertiesView:nil];

    _editControls = nil;    
    
    [self setFractalViewLevelNLabel:nil];
    [self setFractalLevel:nil];
    [self setLevelStepper:nil];
    [self setFractalDefinitionRulesView:nil];
    [self setFractalDefinitionAppearanceView:nil];
    [self setFractalDefinitionAppearanceView:nil];
    [self setFractalDefinitionAppearanceView:nil];
    [self setFractalDefinitionRulesView:nil];
    [self setFractalDefinitionPlaceholderView:nil];
    [self setStrokeSwitch:nil];
    [self setFillSwitch:nil];
    [self setFractalWidth:nil];
    [self setWidthStepper:nil];
    [self setFillColorButton:nil];
    [self setStrokeColorButton:nil];
    [self setWidthSlider:nil];
    [self setLevelSliderContainerView:nil];
    [self setLevelSlider:nil];
    [self setFractalBaseAngle:nil];
    [self setFractalViewLevelNHUD:nil];
    [self setACopyButtonItem: nil];
    [self setFractalPropertyTableHeaderView:nil];
    [self setFractalPropertiesTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
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

#pragma mark - TextView Delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    return self.editing;
}

// TODO: change to sendActionsFor...
- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == self.fractalDescriptor) {
        self.currentFractal.descriptor = textView.text;
    }
}

#pragma mark - TextField Delegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    return self.editing;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

// TODO: no need for this.
// Level is by a slider and axiom below does nothing
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL result = YES;
//    if (textField == self.fractalAxiom) {
//        // perform continuous updating?
//        // Could cause problems when the axiom is invalid.
//        // How to validate axiom? Such as matching brackets.
//        // Always apply brackets as matching pair with insertion point between the two?
//        NSLog(@"Axiom field being edited, range = %@; string = %@", NSStringFromRange(range), string);
//    } else if (textField == self.fractalLevel) {
//        NSString* newString = [textField.text stringByReplacingCharactersInRange: range withString: string];
//        NSInteger value;
//        NSScanner *scanner = [[NSScanner alloc] initWithString: newString];
//        if (![scanner scanInteger:&value] || !scanner.isAtEnd) {
//            result = NO;
//        }  
//    }
    return result;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

// TODO: calls the ruleCell action twice
// Once directly from the field and once from here.
- (void)textFieldDidEndEditing:(UITextField *)textField
{
//    [textField sendActionsForControlEvents: UIControlEventEditingDidEnd];
    self.activeTextField = nil;
}


#pragma mark - Custom Keyboard Handling

- (void)keyTapped:(NSString*)text {
    // Convert the TextRange to an NSRange
    NSRange selectedNSRange;
    UITextRange* textRange = [self.activeTextField selectedTextRange];

    NSInteger start = [self.activeTextField offsetFromPosition: self.activeTextField.beginningOfDocument 
                                                    toPosition: textRange.start];

    NSInteger length =  [self.activeTextField offsetFromPosition: textRange.start 
                                                      toPosition: textRange.end];
    
    selectedNSRange = NSMakeRange(start, length);

    if ([text isEqualToString: @"done"]) {
        [self.activeTextField resignFirstResponder];
    
    } else 
    if ([text isEqualToString: @"delete"]) {
        // backspace
        if ([self.activeTextField.delegate textField: self.activeTextField 
                       shouldChangeCharactersInRange: selectedNSRange 
                                   replacementString: text] ) {
            [self.activeTextField deleteBackward];

        }
        
    } else
    if (self.activeTextField == self.fractalAxiom) {
        if ([self.activeTextField.delegate textField: self.activeTextField 
                       shouldChangeCharactersInRange: selectedNSRange 
                                   replacementString: text] ) {
            [self.activeTextField insertText: text];
        }
    } else {
        if ([self.activeTextField.delegate textField: self.activeTextField 
                       shouldChangeCharactersInRange: selectedNSRange 
                                   replacementString: text] ) {
            [self.activeTextField insertText: text];
        }
    }
}
- (void)doneTapped {
    // resign first responder? does this ever get called?
}

#pragma mark - table delegate & source
enum TableSection {
    SectionAxiom=0,
    SectionRules,
    SectionAppearance
};


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { 
    NSString* sectionHeader = nil;
    
    if (section == SectionAxiom) {
        // axiom
        sectionHeader = @"Axiom";
        
    } else  if (section == SectionRules) {
        // rules
        sectionHeader = @"Rules";
        
    } else  if (section == SectionAppearance) {
        // 
        sectionHeader = @"Appearance";
    }
    return sectionHeader;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    if (section == SectionAxiom) {
        // axiom
        rows = 1;
        
    } else  if (section == SectionRules) {
        // rules
        rows = [self.replacementRulesArray count];
        
    } else  if (section == SectionAppearance) {
        // 
        rows = [self.fractalPropertiesAppearanceSectionDefinitions count];
    }
    return rows;
}

-(MBStepperTableViewCell*) populateStepperCell: (MBStepperTableViewCell*) cell 
                              withSettingsFrom: (NSDictionary*) settings 
                                     indexPath: (NSIndexPath*) indexPath {
    
    cell.propertyImage.image = [UIImage imageNamed: [settings objectForKey:@"imageName"]];
    cell.propertyLabel.text = [settings objectForKey:@"label"];
    cell.formatter = [self.twoPlaceFormatter copy];
    //        [stepperCell addObserver: stepperCell forKeyPath: @"stepper.value" options: NSKeyValueObservingOptionNew context: NULL];
    
    //        self.fractalTurningAngle = stepperCell.value;
    
    UIStepper* stepper = cell.stepper;
    self.turnAngleStepper = stepper;
    
    stepper.minimumValue = [[settings objectForKey:@"minimumValue"] doubleValue];
    stepper.maximumValue = [[settings objectForKey:@"maximumValue"] doubleValue];
    stepper.stepValue = [[settings objectForKey:@"stepValue"] doubleValue];
    stepper.value = [[self.currentFractal valueForKey: [settings objectForKey: @"propertyValueKey"]] doubleValue];
    
    // manually call to set the textField to the stepper value
    //        [stepperCell stepperValueChanged: stepper];
    
    [stepper addTarget: self 
                action: NSSelectorFromString([settings objectForKey: @"actionSelectorString"]) 
      forControlEvents: UIControlEventValueChanged];
    
    [self.appearanceCellIndexPaths setObject: indexPath forKey: [settings objectForKey: @"propertyValueKey"]];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    static NSString *RuleCellIdentifier = @"MBLSRuleCell";
    static NSString *AxiomCellIdentifier = @"MBLSAxiomCell";
    static NSString *StepperCellIdentifier = @"MBStepperCell";
//    static NSString *ColorCellIdentifier = @"MBColorCell";
    
    if (indexPath.section == SectionAxiom) {
        // axiom
        
        MBLSRuleTableViewCell *ruleCell = (MBLSRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier: AxiomCellIdentifier];
        
        // Configure the cell with data from the managed object.
        UITextField* axiom = ruleCell.textRight;
        self.fractalAxiom = axiom; // may be unneccessary?
        axiom.text = self.currentFractal.axiom;
        
        axiom.inputView = self.fractalInputControl.view;
        axiom.delegate = self;
        [axiom addTarget: self 
                  action: @selector(axiomInputChanged:) 
        forControlEvents: (UIControlEventEditingChanged | UIControlEventEditingDidEnd)];
        
        cell = ruleCell;
        
    } else if (indexPath.section == SectionRules) {
        // rules
        
        MBLSRuleTableViewCell *ruleCell = (MBLSRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier: RuleCellIdentifier];
        LSReplacementRule* rule = [self.replacementRulesArray objectAtIndex: indexPath.row];
        
        // Configure the cell with data from the managed object.
        ruleCell.textLeft.text = rule.contextString;
        ruleCell.textRight.text = rule.replacementString;
        
        ruleCell.textRight.inputView = self.fractalInputControl.view;
        ruleCell.textRight.delegate = self;

        // notify textRight delegate of cell change
        // calls delegate back ruleCellTextRightEditingEnded:
        // a way to pass both fields of the rule cell
        [ruleCell.textRight addTarget: ruleCell 
                    action: @selector(textRightEditingEnded:) 
          forControlEvents: UIControlEventEditingDidEnd];

        cell = ruleCell;
        [self.rulesCellIndexPaths setObject: indexPath forKey: rule.contextString];

    } else if (indexPath.section == SectionAppearance) {
        // appearance
        MBStepperTableViewCell *stepperCell = (MBStepperTableViewCell *)[tableView dequeueReusableCellWithIdentifier: StepperCellIdentifier];
        
        cell = [self populateStepperCell: stepperCell 
                        withSettingsFrom: [self.fractalPropertiesAppearanceSectionDefinitions objectAtIndex:indexPath.row]
                               indexPath: indexPath];
        
    } else if (indexPath.section == 2) {
        // ?
    } 

    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Accessory view");
}

#pragma mark - Rule Cell Delegate
-(void)ruleCellTextRightEditingEnded:(id)sender {
    if ([sender isKindOfClass: [MBLSRuleTableViewCell class]]) {
        MBLSRuleTableViewCell* ruleCell = (MBLSRuleTableViewCell*) sender;
        
        NSString* ruleKey = ruleCell.textLeft.text;
        NSArray* rules = self.replacementRulesArray;
        
        // Find the relevant rule for this cell using the key
        // could do the following using a query
        for (LSReplacementRule* rule in rules) {
            if ([rule.contextString isEqualToString: ruleKey]) {
                rule.replacementString = ruleCell.textRight.text;
            }
        }
    }
}

#pragma mark - control actions
- (IBAction)nameInputDidEnd:(UITextField*)sender {
    self.currentFractal.name = sender.text;
}

- (IBAction)levelInputChanged:(UIControl*)sender {
    double rawValue = [[sender valueForKey: @"value"] doubleValue];
    NSNumber* roundedNumber = [NSNumber numberWithLong: lround(rawValue)];
    self.currentFractal.level = roundedNumber;
}

- (IBAction)selectStrokeColor:(UIButton*)sender {
    self.coloringKey = @"lineColor";
        
    ColorPickerController* colorPicker = (ColorPickerController*) self.colorPopover.contentViewController.navigationController.visibleViewController;
    colorPicker.selectedColor = [self.currentFractal lineColorAsUI];
    
    [self.colorPopover presentPopoverFromRect: sender.frame 
                                       inView: sender.superview 
                     permittedArrowDirections:UIPopoverArrowDirectionAny 
                                     animated: YES];

}

- (IBAction)selectFillColor:(UIButton*)sender {
    self.coloringKey = @"fillColor";
    
    ColorPickerController* colorPicker = (ColorPickerController*) self.colorPopover.contentViewController.navigationController.visibleViewController;
    colorPicker.selectedColor = [self.currentFractal fillColorAsUI];
        
    [self.colorPopover presentPopoverFromRect: sender.frame 
                                       inView: sender.superview 
                     permittedArrowDirections:UIPopoverArrowDirectionAny 
                                     animated: YES];

//    [self performSegueWithIdentifier: @"ColorPickerPopoverSeque" sender: self];


}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (![segue.identifier isEqualToString: @"ColorPickerPopoverSeque"]) {
        // send the color
        UIViewController* dest = segue.destinationViewController;
        [(ColorPickerController*)dest setDelegate: self];
        dest.modalInPopover = YES;
    }
}

- (IBAction)toggleStroke:(UISwitch*)sender {
    self.currentFractal.stroke = [NSNumber numberWithBool: sender.on];
}

- (IBAction)toggleFill:(UISwitch*)sender {
    self.currentFractal.fill = [NSNumber numberWithBool: sender.on];
}

- (IBAction)lineWidthInputChanged:(id)sender {
    self.currentFractal.lineWidth = [sender valueForKey: @"value"];
}

- (IBAction)lineWidthIncrementInputChanged:(id)sender {
    self.currentFractal.lineWidthIncrement = [sender valueForKey: @"value"];
}

- (IBAction)axiomInputChanged:(UITextField*)sender {
    self.currentFractal.axiom = sender.text;
}

- (IBAction)axiomInputEnded:(UITextField*)sender {
    // update rule editing table?
}


- (IBAction)lineLengthInputChanged:(UIStepper*)sender {
    self.currentFractal.lineLength = [NSNumber numberWithDouble: sender.value];
}

- (IBAction)lineLengthScaleFactorInputChanged:(UIStepper*)sender {
    self.currentFractal.lineLengthScaleFactor = [NSNumber numberWithDouble: sender.value];
}

- (IBAction)turningAngleInputChanged:(UIStepper*)sender {
    [self.currentFractal setTurningAngleAsDegrees: [NSNumber numberWithDouble: sender.value]];
}

- (IBAction)turningAngleIncrementInputChanged:(UIStepper*)sender {
    [self.currentFractal setTurningAngleIncrementAsDegrees: [NSNumber numberWithDouble: sender.value]];
}

- (IBAction)switchFractalDefinitionView:(UISegmentedControl*)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self useFractalDefinitionRulesView];
        
    } else if(sender.selectedSegmentIndex == 1) {
        [self useFractalDefinitionAppearanceView];
    }
}

-(double) convertAndQuantizeRotationFrom: (UIRotationGestureRecognizer*)sender quanta: (double) stepRadians ratio: (double) deltaAngleToDeltaGestureRatio {
    
    double deltaAngle = 0.0;
    
    double deltaGestureRotation = sender.rotation;
    
    double deltaAngleSteps = nearbyint(deltaAngleToDeltaGestureRatio*deltaGestureRotation/stepRadians);
    
    if (deltaAngleSteps != 0.0) {
        deltaAngle = deltaAngleSteps*stepRadians;
                
        double newRotation = deltaGestureRotation - deltaAngle/deltaAngleToDeltaGestureRatio;
        sender.rotation = newRotation;
    }
    
    return deltaAngle;
}

-(IBAction) rotateTurningAngle:(UIRotationGestureRecognizer*)sender {
    if (self.editing) {
        
        NSIndexPath* turnAngleIndex = [self.appearanceCellIndexPaths objectForKey: @"turningAngle"];
        
        if (turnAngleIndex) {
            [self.fractalPropertiesTableView scrollToRowAtIndexPath: turnAngleIndex 
                                                   atScrollPosition: UITableViewScrollPositionMiddle 
                                                           animated: YES];

        }
        

        double stepRadians = radians(self.turnAngleStepper.stepValue);
        // 2.5 degrees -> radians
        
        double deltaTurnToDeltaGestureRatio = 1.0/6.0;
        // reduce the sensitivity to make it easier to rotate small degrees

        double deltaTurnAngle = [self convertAndQuantizeRotationFrom: sender quanta: stepRadians ratio: deltaTurnToDeltaGestureRatio];
        
        if (deltaTurnAngle != 0.0 ) {
            double newAngle = remainder([self.currentFractal.turningAngle doubleValue]-deltaTurnAngle, M_PI*2);
            self.currentFractal.turningAngle = [NSNumber numberWithDouble: newAngle];
        }
    }
}

-(IBAction) rotateFractal:(UIRotationGestureRecognizer*)sender {
    if (self.editing) {
        
        double stepRadians = radians(15.0);
        
        double deltaTurnToDeltaGestureRatio = 1.0;
        
        double deltaTurnAngle = [self convertAndQuantizeRotationFrom: sender quanta: stepRadians ratio: deltaTurnToDeltaGestureRatio];
        
        if (deltaTurnAngle != 0) {
            double newAngle = remainder([self.currentFractal.baseAngle doubleValue]-deltaTurnAngle, M_PI*2);
            self.currentFractal.baseAngle = [NSNumber numberWithDouble: newAngle];
        }
    }
}

- (IBAction)magnifyFractal:(UILongPressGestureRecognizer*)sender {
    
}

- (IBAction)copyFractal:(id)sender {
    LSFractal* fractal = self.currentFractal;
    
    // copy
    LSFractal* copiedFractal = [fractal mutableCopy];
    copiedFractal.name = [NSString stringWithFormat: @"%@ copy", copiedFractal.name];
    copiedFractal.isImmutable = [NSNumber numberWithBool: NO];
    copiedFractal.isReadOnly = [NSNumber numberWithBool: NO];
    
    self.currentFractal = copiedFractal;
    // Need to add edit button if missing
    [self configureRightButtons];
    
    [self refreshContents];
    self.editing = YES;
}

#pragma mark - ColorPicker Delegate Protocol
//TODO: check for pre-existing colors, maybe only allow selecting from pre-existing colors? replacing colorPicker with swatches?
- (void)colorPickerSaved:(ColorPickerController *)controller {
    
    MBColor* newColor = [MBColor mbColorWithUIColor: controller.selectedColor inContext: self.currentFractal.managedObjectContext];
    MBColor* currentColor = [self.currentFractal valueForKey: self.coloringKey];
    
    NSString* camelCase = [self.coloringKey stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString: [[self.coloringKey substringWithRange: NSMakeRange(0, 1)] uppercaseString]];
    
    NSString* selectorString = [NSString stringWithFormat: @"set%@:", camelCase];
        
    NSUndoManager* undoManager = self.currentFractal.managedObjectContext.undoManager;
    
    [undoManager beginUndoGrouping];
    
    [undoManager registerUndoWithTarget: self.currentFractal selector: NSSelectorFromString(selectorString) object: currentColor];
    
    [self.currentFractal setValue: newColor forKey: self.coloringKey];
    
    [undoManager endUndoGrouping];
}

- (void)colorPickerUndo:(ColorPickerController *)controller {
    NSUndoManager* undoManager = self.currentFractal.managedObjectContext.undoManager;
    [undoManager undo];
}

- (void)colorPickerRedo:(ColorPickerController *)controller {
    NSUndoManager* undoManager = self.currentFractal.managedObjectContext.undoManager;
    [undoManager redo];
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
    if (self.currentFractal.managedObjectContext.undoManager == nil) {
        
        NSUndoManager *anUndoManager = [[NSUndoManager alloc] init];
        [anUndoManager setLevelsOfUndo:3];
        _undoManager = anUndoManager;
        
        self.currentFractal.managedObjectContext.undoManager = _undoManager;
    }
    
    // Register as an observer of the book's context's undo manager.
    NSUndoManager *fractalUndoManager = self.currentFractal.managedObjectContext.undoManager;
    
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(undoManagerDidUndo:) name:NSUndoManagerDidUndoChangeNotification object:fractalUndoManager];
    [dnc addObserver:self selector:@selector(undoManagerDidRedo:) name:NSUndoManagerDidRedoChangeNotification object:fractalUndoManager];
}


- (void)cleanUpUndoManager {
    
    // Remove self as an observer.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.currentFractal.managedObjectContext.undoManager == _undoManager) {
        self.currentFractal.managedObjectContext.undoManager = nil;
        _undoManager = nil;
    }       
}


//- (NSUndoManager *)undoManager {
//    return self.currentFractal.managedObjectContext.undoManager;
//}


- (void)undoManagerDidUndo:(NSNotification *)notification {
    [self updateRightBarButtonItemState];
}


- (void)undoManagerDidRedo:(NSNotification *)notification {
    [self updateRightBarButtonItemState];
}


-(void) dealloc {
    self.currentFractal = nil; // removes observers via custom setter call
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }
}

@end
