//
//  MBLSFractalEditViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalEditViewController.h"
#import "LSFractalGenerator.h"
#import "MBColor+addons.h"

#import <QuartzCore/QuartzCore.h>

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

-(void) setEditMode: (BOOL) editing;
-(void) setupLevelGeneratorForView: (UIView*) aView name: (NSString*) name forceLevel: (NSInteger) aLevel;
-(void) reloadLabels;
-(void) refreshValueInputs;
-(void) refreshLayers;

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
@synthesize colorPopover = _colorPopover;
@synthesize placeHolderBounds = _placeHolderBounds;
@synthesize placeHolderCenter = _placeHolderCenter;
@synthesize currentFractal = _currentFractal;
@synthesize coloringKey = _coloringKey;
@synthesize onePlaceFormatter = _onePlaceFormatter;
@synthesize fractalName = _fractalNameTextField;
@synthesize fractalDescriptor = _fractalDescription;
@synthesize fractalAxiom = _fractalAxiomTextField;
@synthesize fractalInputControl = _fractalInputControl;
@synthesize activeTextField = _activeField;
@synthesize fractalViewLevel0 = _fractalViewLevel0;
@synthesize fractalViewLevel1 = _fractalViewLevel1;
@synthesize fractalViewLevelN = _fractalViewLevelN;
@synthesize levelSliderContainerView = _levelSliderContainerView;
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
-(void) setCurrentFractal:(LSFractal *)fractal {
    if (_currentFractal != fractal) {
        
        NSSet* propertiesToObserve = [[LSFractal productionRuleProperties] setByAddingObjectsFromSet:[LSFractal appearanceProperties]];
        propertiesToObserve = [propertiesToObserve setByAddingObjectsFromSet: [LSFractal lableProperties]];
        
        for (NSString* keyPath in propertiesToObserve) {
            [_currentFractal removeObserver: self forKeyPath: keyPath];
            [fractal addObserver: self forKeyPath:keyPath options: 0 context: NULL];
        }
        
        _currentFractal = fractal;
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
                         self.fractalAxiom,
                         self.lineLengthStepper,
                         self.turnAngleStepper,
                         self.levelStepper,
                         self.widthStepper,
                         self.widthSlider,
                         self.strokeSwitch,
                         self.strokeColorButton,
                         self.fillSwitch,
                         self.fillColorButton,
                         self.levelSlider,
                         nil];
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

-(void) setFractalViewLevelN:(UIView *)fractalViewLevelN {
    _fractalViewLevelN = fractalViewLevelN;
    UIRotationGestureRecognizer* rgr = [[UIRotationGestureRecognizer alloc] initWithTarget: self action: @selector(rotateFractal:)];
    [_fractalViewLevelN addGestureRecognizer: rgr];
    [self setupLevelGeneratorForView: _fractalViewLevelN name: @"fractalLevelN" forceLevel: -1];
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

//TODO: number formatters
-(void) refreshValueInputs {    
    self.fractalAxiom.text = self.currentFractal.axiom;
    
    self.fractalLineLength.text =  [self.currentFractal.lineLength stringValue];
    self.lineLengthStepper.value = [self.currentFractal.lineLength doubleValue];
    
    self.fractalWidth.text =  [self.currentFractal.lineWidth stringValue];
    self.widthStepper.value = [self.currentFractal.lineWidth doubleValue];
    self.widthSlider.value = [self.currentFractal.lineWidth doubleValue];
    
    self.fractalTurningAngle.text = [self.onePlaceFormatter stringFromNumber: [self.currentFractal turningAngleAsDegree]];
    self.turnAngleStepper.value = [[self.currentFractal turningAngleAsDegree] doubleValue];
    
    self.fractalLevel.text = [self.currentFractal.level stringValue];
    self.levelStepper.value = [self.currentFractal.level doubleValue];
    self.levelSlider.value = [self.currentFractal.level doubleValue];
    
    self.strokeSwitch.on = [self.currentFractal.stroke boolValue];
    self.fillSwitch.on = [self.currentFractal.fill boolValue];
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
//TODO: change the generator, layer, levels to be more generic.
//TODO: note changing number of levels only changes N view.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _placeHolderCenter = self.fractalDefinitionPlaceholderView.center;
    _placeHolderBounds = self.fractalDefinitionPlaceholderView.bounds;
    
//    [self.fractalDefinitionPlaceholderView removeFromSuperview];
    [self loadDefinitionViews];
    [self useFractalDefinitionRulesView];
        
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setEditMode: NO];
    
//    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
//    self.navigationItem.rightBarButtonItem = saveButton;
    
    
    [self setupLevelGeneratorForView: self.fractalViewLevel0 name: @"fractalLevel0" forceLevel: 0];
    [self setupLevelGeneratorForView: self.fractalViewLevel1 name: @"fractalLevel1" forceLevel: 1];
        
    self.fractalAxiom.inputView = self.fractalInputControl.view;
    
    CGAffineTransform rotateCC = CGAffineTransformMakeRotation(-M_PI_2);
    [self.levelSliderContainerView setTransform: rotateCC];
    
    [self reloadLabels];
    [self refreshValueInputs];
    [self refreshLayers];
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
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    // Hide the back button when editing starts, and show it again when editing finishes.
    [self.navigationItem setHidesBackButton:editing animated:animated];
    
    [self setEditMode: editing];
    /*
     When editing starts, create and set an undo manager to track edits. Then register as an observer of undo manager change notifications, so that if an undo or redo operation is performed, the table view can be reloaded.
     When editing ends, de-register from the notification center and remove the undo manager, and save the changes.
     */
    if (editing) {
        
        [self setUpUndoManager];
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        
        NSMutableArray* lefties = [self.navigationItem.leftBarButtonItems mutableCopy];
        [lefties addObject: cancelButton];
        self.navigationItem.leftBarButtonItems = lefties;
        self.navigationItem.leftItemsSupplementBackButton = YES;
    }
    else {
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL result = YES;
    if (textField == self.fractalAxiom) {
        // perform continuous updating?
        // Could cause problems when the axiom is invalid.
        // How to validate axiom? Such as matching brackets.
        // Always apply brackets as matching pair with insertion point between the two?
        NSLog(@"Axiom field being edited");
    } else if (textField == self.fractalLevel) {
        NSString* newString = [textField.text stringByReplacingCharactersInRange: range withString: string];
        NSInteger value;
        NSScanner *scanner = [[NSScanner alloc] initWithString: newString];
        if (![scanner scanInteger:&value] || !scanner.isAtEnd) {
            result = NO;
        }  
    }
    return result;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField sendActionsForControlEvents: UIControlEventEditingDidEnd];
    self.activeTextField = nil;
}

#pragma mark - Custom Keyboard Handling

- (void)keyTapped:(NSString*)text {
    if ([text isEqualToString: @"Done"]) {
        [self.activeTextField resignFirstResponder];
    } else
    if (self.activeTextField) {
        // Update fractal when this value changes?
        // live updates?
        // save on each press and use observer?
        if (self.activeTextField == self.fractalAxiom) {
            self.currentFractal.axiom = [self.activeTextField.text stringByAppendingString: text];
        }
    }
}
- (void)doneTapped {
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

-(void) rotateFractal:(UIRotationGestureRecognizer*)sender {
    if (self.editing) {
        
        double fifteenDegrees = M_PI/12.0;
        
        double quanta = nearbyint(sender.rotation/fifteenDegrees);
        
        sender.rotation = sender.rotation - (quanta*fifteenDegrees);
        double newAngle = remainder([self.currentFractal.baseAngle doubleValue]-(quanta*fifteenDegrees), M_PI*2);
        self.currentFractal.baseAngle = [NSNumber numberWithDouble: newAngle];
    }
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
