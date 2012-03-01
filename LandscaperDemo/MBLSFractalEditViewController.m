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

#import "MBStepperTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

#include <math.h>

#define HUD_CORNER_RADIUS 12.0
#define HUD_OPACITY 1

static inline double radians (double degrees) {return degrees * M_PI/180.0;}
static inline double degrees (double radians) {return radians * 180.0/M_PI;}

@interface MBLSFractalEditViewController () 

/*!
 for tracking which text input field has the current focus.
 allows using a custom input keyboard.
 Want to change to a popover at some point.
 */
@property (weak, nonatomic) UITextField*            activeTextField;

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
@synthesize colorPopover = _colorPopover;
@synthesize placeHolderBounds = _placeHolderBounds;
@synthesize placeHolderCenter = _placeHolderCenter;
@synthesize currentFractal = _currentFractal;
@synthesize coloringKey = _coloringKey;
@synthesize onePlaceFormatter = _onePlaceFormatter;
@synthesize aCopyButtonItem = _aCopyButtonItem;
@synthesize fractalPropertyTableHeaderView = _fractalPropertyTableHeaderView;
@synthesize fractalName = _fractalNameTextField;
@synthesize fractalDescriptor = _fractalDescription;
@synthesize fractalAxiom = _fractalAxiomTextField;
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
    
    if ([[LSFractal productionRuleProperties] containsObject: keyPath]) {
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

-(NSNumberFormatter*) onePlaceFormatter {
    if (_onePlaceFormatter == nil) {
        _onePlaceFormatter = [[NSNumberFormatter alloc] init];
        [_onePlaceFormatter setAllowsFloats: YES];
        [_onePlaceFormatter setMaximumFractionDigits: 1];
        [_onePlaceFormatter setMaximumIntegerDigits: 3];
        [_onePlaceFormatter setPositiveFormat: @"##0.0"];
        [_onePlaceFormatter setNegativeFormat: @"-##0.0"];
    }
    return _onePlaceFormatter;
}

-(void) setFractalViewLevel0:(UIView *)fractalViewLevel0 {
    _fractalViewLevel0 = fractalViewLevel0;
    UIRotationGestureRecognizer* rgr = [[UIRotationGestureRecognizer alloc] 
                                        initWithTarget: self 
                                        action: @selector(rotateTurnAngle:)];
    
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

-(void) fitLayer: (CALayer*) layerA inLayer: (CALayer*) layerB margin: (double) margin {
    CGRect boundsB = layerB.bounds;
    CGRect boundsA = CGRectInset(boundsB, margin, margin);
    layerA.bounds = boundsA;
    layerA.position = CGPointMake(boundsB.size.width/2, boundsB.size.height/2);
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
//    self.fractalTurningAngle.text = [self.onePlaceFormatter stringFromNumber: [self.currentFractal turningAngleAsDegree]];
    self.turnAngleStepper.value = [[self.currentFractal turningAngleAsDegree] doubleValue];
    
//    
//    self.fractalLevel.text = [self.currentFractal.level stringValue];
//    self.levelStepper.value = [self.currentFractal.level doubleValue];
//    self.levelSlider.value = [self.currentFractal.level doubleValue];
//    
//    self.strokeSwitch.on = [self.currentFractal.stroke boolValue];
//    self.fillSwitch.on = [self.currentFractal.fill boolValue];
}

-(void) refreshLayers {
    self.fractalViewLevelNLabel.text = [self.currentFractal.level stringValue];
    self.fractalBaseAngle.text = [self.onePlaceFormatter stringFromNumber: [self.currentFractal baseAngleAsDegree]];
    
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
    [super viewDidLoad];
    
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
    
    [self setupLevelGeneratorForView: self.fractalViewLevel0 name: @"fractalLevel0" forceLevel: 0];
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


/*!
 Want to monitor the layout to resize the fractal layer of fractalViewLevelN. Always fit the layer in the view on layout.
 Can change the layer scale or the frame and redraw the layer?
 */
-(void) viewDidLayoutSubviews {
    CALayer* containingLayer = self.fractalViewLevelN.layer;
    NSArray* subLayers = containingLayer.sublayers;
    for (CALayer* layer in subLayers) {
        if ([layer.name isEqualToString: @"fractalLevel0"]) {
            [self fitLayer: layer inLayer: containingLayer margin: 10];
            // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
        } else if ([layer.name isEqualToString: @"fractalLevel1"]) {
            [self fitLayer: layer inLayer: containingLayer margin: 10];
            // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
        } if ([layer.name isEqualToString: @"fractalLevelN"]) {
            [self fitLayer: layer inLayer: containingLayer margin: 10];
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
        
        NSMutableArray* lefties = [self.navigationItem.leftBarButtonItems mutableCopy];
        [lefties addObject: cancelButton];
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
            exit(-1);  // Fail
        }
        NSMutableArray* lefties = [self.navigationItem.leftBarButtonItems mutableCopy];
        [lefties removeLastObject];
        self.navigationItem.leftBarButtonItems = lefties;
        [self becomeFirstResponder];
    }
}

- (void)cancel:(id)sender {
    [self.undoManager undo];
    [self setEditMode: NO];
    [self cleanUpUndoManager];
}

- (void)viewDidUnload
{
    //should save be here or at higher level
    //
    [self.currentFractal.managedObjectContext save: nil];
    self.fractalInputControl.delegate = nil;
    [self setFractalInputControl: nil];
    
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }

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
enum TableSections {
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
        rows = 1;
    }
    return rows;
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

    } else if (indexPath.section == SectionAppearance) {
        // appearance
        MBStepperTableViewCell *stepperCell = (MBStepperTableViewCell *)[tableView dequeueReusableCellWithIdentifier: StepperCellIdentifier];
        
        stepperCell.label.text = @"Angle";
        stepperCell.formatter = [self.onePlaceFormatter copy];
//        [stepperCell addObserver: stepperCell forKeyPath: @"stepper.value" options: NSKeyValueObservingOptionNew context: NULL];
        
//        self.fractalTurningAngle = stepperCell.value;
        
        UIStepper* stepper = stepperCell.stepper;
        self.turnAngleStepper = stepper;
        
        stepper.minimumValue = -180.0;
        stepper.maximumValue = 181.0;
        stepper.stepValue = 1.0;
        stepper.value = [[self.currentFractal turningAngleAsDegree] doubleValue];
        
        // manually call to set the textField to the stepper value
//        [stepperCell stepperValueChanged: stepper];
        
        [stepper addTarget: self 
                                action: @selector(turnAngleInputChanged:) 
                      forControlEvents: UIControlEventValueChanged];
        

        cell = stepperCell;
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
    double rawValue = [[sender valueForKey: @"value"] doubleValue];
    NSNumber* roundedNumber = [NSNumber numberWithDouble: (floor(rawValue*10)/10.0)];
    self.currentFractal.lineWidth = roundedNumber;
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

- (IBAction)turnAngleInputChanged:(UIStepper*)sender {
    [self.currentFractal setTurningAngleAsDegrees: [NSNumber numberWithDouble: sender.value]];
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

-(IBAction) rotateTurnAngle:(UIRotationGestureRecognizer*)sender {
    if (self.editing) {
        

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
- (void)setUpUndoManager {
    /*
     If the book's managed object context doesn't already have an undo manager, then create one and set it for the context and self.
     The view controller needs to keep a reference to the undo manager it creates so that it can determine whether to remove the undo manager when editing finishes.
     */
    if (self.currentFractal.managedObjectContext.undoManager == nil) {
        
        NSUndoManager *anUndoManager = [[NSUndoManager alloc] init];
        [anUndoManager setLevelsOfUndo:3];
        self.undoManager = anUndoManager;
        
        self.currentFractal.managedObjectContext.undoManager = self.undoManager;
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
    
    if (self.currentFractal.managedObjectContext.undoManager == self.undoManager) {
        self.currentFractal.managedObjectContext.undoManager = nil;
        self.undoManager = nil;
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
