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

/*
 So a setNeedsDisplay can be sent to each layer when a fractal property is changed.
 */
@property (nonatomic, weak) NSArray* fractalDisplayLayersArray;
/*
 a generator for each level being displayed.
 */
@property (nonatomic, strong) NSMutableArray* generatorsArray; 

-(void) setupLevel0Generator;
-(void) setupLevel1Generator;
-(void) setupLevelNGenerator;

@end

/*!
 Could setup KVO for model proerties to fields.
 Would be same as using bindings.
 */

@implementation MBLSFractalEditViewController

@synthesize currentFractal = _currentFractal;
@synthesize fractalNameTextField = _fractalNameTextField;
@synthesize fractalAxiomTextField = _fractalAxiomTextField;
@synthesize appManagedObjectContext = _appManagedObjectContext;
@synthesize fractalInputControl = _fractalInputControl;
@synthesize activeTextField = _activeField;
@synthesize fractalLevelView0 = _fractalLevelView0;
@synthesize fractalLevelView1 = _fractalLevelView1;
@synthesize fractalLevelViewN = _fractalLevelViewN;
@synthesize lineLengthTextField = _lineLengthTextField;

@synthesize fractalDisplayLayersArray = _fractalDisplayLayersArray;
@synthesize generatorsArray = _generatorsArray;

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

-(void) setupLevel0Generator {
    LSFractalGenerator* generator = [[LSFractalGenerator alloc] init];
    if (generator) {
        generator.fractal = self.currentFractal;
        generator.forceLevel = 0;
        CALayer* layer = [self.fractalDisplayLayersArray objectAtIndex: 0];
        layer.delegate = generator;
        [self.generatorsArray addObject: generator];
    }
}

-(void) setupLevel1Generator {
    LSFractalGenerator* generator = [[LSFractalGenerator alloc] init];
    if (generator) {
        generator.fractal = self.currentFractal;
        generator.forceLevel = 1;
        CALayer* layer = [self.fractalDisplayLayersArray objectAtIndex: 1];
        layer.delegate = generator;
        [self.generatorsArray addObject: generator];
    }
}

-(void) setupLevelNGenerator {
    LSFractalGenerator* generator = [[LSFractalGenerator alloc] init];
    if (generator) {
        generator.fractal = self.currentFractal;
        generator.forceLevel = -1;
        CALayer* layer = [self.fractalDisplayLayersArray objectAtIndex: 2];
        layer.delegate = generator;
        [self.generatorsArray addObject: generator];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
//TODO: change the generator, layer, levels to be more generic.
//TODO: note changing number of levels only changes N view.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fractalDisplayLayersArray = [NSArray arrayWithObjects: 
                                 self.fractalLevelView0.layer,
                                 self.fractalLevelView1.layer,
                                 self.fractalLevelViewN.layer, nil];
    
    [self setupLevel0Generator];
    [self setupLevel1Generator];
    [self setupLevelNGenerator];
    
    self.fractalNameTextField.text = self.currentFractal.name;
    self.fractalAxiomTextField.text = self.currentFractal.axiom;
    self.fractalAxiomTextField.inputView = self.fractalInputControl.view;
    self.lineLengthTextField.text =  [self.currentFractal.lineLength stringValue];
}


- (void)viewDidUnload
{
    [self setFractalNameTextField:nil];
    [self setFractalAxiomTextField:nil];
    [self setFractalInputControl:nil];
    [self setFractalLevelView0:nil];
    [self setFractalLevelView1:nil];
    [self setFractalLevelViewN:nil];
    [self setLineLengthTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

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

- (IBAction)lineLengthInputChanged:(id)sender {
    if ([sender isKindOfClass: [UITextField class]]) {
        // handle text input
    } else if ([sender isKindOfClass: [UIStepper class]]) {
        // handle stepper input
        UIStepper* stepper = sender;
        self.currentFractal.lineLength = [NSNumber numberWithDouble: stepper.value];
        self.lineLengthTextField.text = [self.currentFractal.lineLength stringValue];
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


@end
