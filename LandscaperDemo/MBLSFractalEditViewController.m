//
//  MBLSFractalEditViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalEditViewController.h"
#import "LSFractalGenerator.h"

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
@property (weak, nonatomic) IBOutlet FractalDefinitionKeyboardView *fractalInputControl;

/*
 So a setNeedsDisplay can be sent to each layer when a fractal property is changed.
 */
@property (nonatomic, strong) NSMutableArray* fractalDisplayLayersArray;
/*
 a generator for each level being displayed.
 */
@property (nonatomic, strong) NSMutableArray* generatorsArray; 

-(void) setupLevelGeneratorForLayer: (CALayer*) aLayer forceLevel: (NSInteger) aLevel;
-(void) reloadFractal;

@end

/*!
 Could setup KVO for model proerties to fields.
 Would be same as using bindings.
 */

@implementation MBLSFractalEditViewController

@synthesize currentFractal = _currentFractal;
@synthesize fractalNameTextField = _fractalNameTextField;
@synthesize fractalAxiomTextField = _fractalAxiomTextField;
@synthesize fractalInputControl = _fractalInputControl;
@synthesize activeTextField = _activeField;
@synthesize fractalLevelView0 = _fractalLevelView0;
@synthesize fractalLevelView1 = _fractalLevelView1;
@synthesize fractalLevelViewN = _fractalLevelViewN;
@synthesize lineLengthTextField = _lineLengthTextField;
@synthesize lineLengthStepper = _lineLengthStepper;

@synthesize fractalDisplayLayersArray = _fractalDisplayLayersArray;
@synthesize generatorsArray = _generatorsArray;
@synthesize undoManager = _undoManager;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

#pragma mark - custom setter getters
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

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

-(void) setupLevelGeneratorForLayer: (CALayer*) aLayer forceLevel: (NSInteger) aLevel {
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
//TODO: replace with KVO for generator of core data properties
-(void) reloadFractal {
    for (LSFractalGenerator* aGenerator in self.generatorsArray) {
        [aGenerator productionRuleChanged];
    }
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        [layer setNeedsDisplay];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
//TODO: change the generator, layer, levels to be more generic.
//TODO: note changing number of levels only changes N view.
- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self setupLevelGeneratorForLayer:self.fractalLevelView0.layer forceLevel:0];
    [self setupLevelGeneratorForLayer:self.fractalLevelView1.layer forceLevel:1];
    [self setupLevelGeneratorForLayer:self.fractalLevelViewN.layer forceLevel:-1];
    
    self.fractalNameTextField.text = self.currentFractal.name;
    self.fractalAxiomTextField.text = self.currentFractal.axiom;
    self.fractalAxiomTextField.inputView = self.fractalInputControl.view;
    self.lineLengthTextField.text =  [self.currentFractal.lineLength stringValue];
    
    [self reloadFractal];
}

-(void) setEditMode: (BOOL) editing {
    UITextBorderStyle bs;
    if (editing) {
        bs = UITextBorderStyleBezel;
    } else {
        bs = UITextBorderStyleNone;
    }
    
    self.fractalNameTextField.enabled = editing;
    [self.fractalNameTextField setBorderStyle: bs];
    
    [self.fractalAxiomTextField setBorderStyle: bs];
    self.fractalAxiomTextField.enabled = editing;
    
    [self.lineLengthTextField setBorderStyle: bs];
    self.lineLengthTextField.enabled = editing;
    
    self.lineLengthStepper.enabled = editing;
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
    }
}

- (void)viewDidUnload
{
    //should save be here or at higher level
    //
    [self.currentFractal.managedObjectContext save: nil];
    
    [self setFractalNameTextField:nil];
    [self setFractalAxiomTextField:nil];
    [self setFractalInputControl:nil];
    [self setFractalLevelView0:nil];
    [self setFractalLevelView1:nil];
    [self setFractalLevelViewN:nil];
    [self setLineLengthTextField:nil];
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }
    [self setLineLengthStepper:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Custom Keyboard Handling

- (void)keyTapped:(NSString*)title {
    if (self.activeTextField) {
        self.activeTextField.text = [self.activeTextField.text stringByAppendingString: title];
        // Update fractal when this value changes?
        // live updates?
        // save on each press and use observer?
    }
}
- (void)doneTapped {
}
//TODO: remove once KVO implemented
- (IBAction)lineLengthInputChanged:(id)sender {
    if ([sender isKindOfClass: [UITextField class]]) {
        // handle text input
    } else if ([sender isKindOfClass: [UIStepper class]]) {
        // handle stepper input
        UIStepper* stepper = sender;
        self.currentFractal.lineLength = [NSNumber numberWithDouble: stepper.value];
        self.lineLengthTextField.text = [self.currentFractal.lineLength stringValue];
        [self reloadFractal];
    }
}
     
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeTextField = nil;
}

#pragma mark - core data 
- (void)updateRightBarButtonItemState {
    // Conditionally enable the right bar button item -- it should only be enabled if the book is in a valid state for saving.
    self.navigationItem.rightBarButtonItem.enabled = [self.currentFractal validateForUpdate:NULL];
}   

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


- (NSUndoManager *)undoManager {
    return self.currentFractal.managedObjectContext.undoManager;
}


- (void)undoManagerDidUndo:(NSNotification *)notification {
    [self reloadFractal];
    [self updateRightBarButtonItemState];
}


- (void)undoManagerDidRedo:(NSNotification *)notification {
    [self reloadFractal];
    [self updateRightBarButtonItemState];
}


-(void) dealloc {
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }
}

@end
