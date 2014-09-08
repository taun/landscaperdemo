//
//  MBFractalAppearanceViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalLineSegmentsEditorViewController.h"
#import "LSFractal+addons.h"
#import "MBColor+addons.h"


@interface MBFractalLineSegmentsEditorViewController () {

__strong NSArray* _fractalPropertiesAppearanceSectionDefinitions;
}
@property (nonatomic,readonly) NSArray* fractalPropertiesAppearanceSectionDefinitions;

@property (nonatomic, strong) NSMutableDictionary*  appearanceCellIndexPaths;

-(void)refreshValueInputs;

@end

@implementation MBFractalLineSegmentsEditorViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.editing = YES;
    [self refreshValueInputs];
}
-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSArray*) fractalPropertiesAppearanceSectionDefinitions {
    if (_fractalPropertiesAppearanceSectionDefinitions == nil) {
        NSDictionary* turningAngle = @{@"label": @"Angle",
                                       @"imageName": @"Plus rotate CC dark.png",
                                       @"minimumValue": @-180.0,
                                       @"maximumValue": @181.0,
                                       @"stepValue": @1.0,
                                       @"propertyValueKey": @"turningAngleAsDegree",
                                       @"actionSelectorString": @"turningAngleInputChanged:"};
        
        NSDictionary* turningAngleIncrement = @{@"label": @"A Increment",
                                                @"imageName": @"Parenthesis increment turn angle dark.png",
                                                @"minimumValue": @-180.0,
                                                @"maximumValue": @181.0,
                                                @"stepValue": @0.25,
                                                @"propertyValueKey": @"turningAngleIncrementAsDegree",
                                                @"actionSelectorString": @"turningAngleIncrementInputChanged:"};
        
        NSDictionary* lineWidth = @{@"label": @"Width",
                                    @"imageName": @"Line width dark.png",
                                    @"minimumValue": @1.0,
                                    @"maximumValue": @20.0,
                                    @"stepValue": @1.0,
                                    @"propertyValueKey": @"lineWidth",
                                    @"actionSelectorString": @"lineWidthInputChanged:"};
        
        NSDictionary* lineWidthIncrement = @{@"label": @"L Increment",
                                             @"imageName": @"Pound increment width dark.png",
                                             @"minimumValue": @1.0,
                                             @"maximumValue": @20.0,
                                             @"stepValue": @0.25,
                                             @"propertyValueKey": @"lineWidthIncrement",
                                             @"actionSelectorString": @"lineWidthIncrementInputChanged:"};
        
        NSDictionary* lineLengthScaleFactor = @{@"label": @"Length Scale",
                                                @"minimumValue": @0.0,
                                                @"maximumValue": @10.0,
                                                @"stepValue": @0.1,
                                                @"propertyValueKey": @"lineLengthScaleFactor",
                                                @"actionSelectorString": @"lineLengthScaleFactorInputChanged:"};
        
        _fractalPropertiesAppearanceSectionDefinitions = @[turningAngle,
                                                           turningAngleIncrement,
                                                           lineWidth,
                                                           lineWidthIncrement,
                                                           lineLengthScaleFactor];
    }
    return _fractalPropertiesAppearanceSectionDefinitions;
}

-(NSMutableDictionary*) appearanceCellIndexPaths {
    if (_appearanceCellIndexPaths == nil) {
        _appearanceCellIndexPaths = [[NSMutableDictionary alloc] initWithCapacity: 5];
    }
    return _appearanceCellIndexPaths;
}

-(void) refreshValueInputs {
    self.fractalLineLength.text =  [self.fractal.lineLength stringValue];
    self.lineLengthStepper.value = [self.fractal.lineLength doubleValue];

    self.fractalWidth.text =  [self.fractal.lineWidth stringValue];
    self.widthStepper.value = [self.fractal.lineWidth doubleValue];

    self.fractalTurningAngle.text = [self.twoPlaceFormatter stringFromNumber: [self.fractal turningAngleAsDegree]];
    self.turnAngleStepper.value = [[self.fractal turningAngleAsDegree] doubleValue];
    
    self.randomness.text = [self.twoPlaceFormatter stringFromNumber: [self.fractal randomness]];
    self.randomnessStepper.value = [[self.fractal randomness] doubleValue];

    self.strokeSwitch.on = [self.fractal.stroke boolValue];
    self.fillSwitch.on = [self.fractal.fill boolValue];
    self.fillEvenOddSwitch.on = [self.fractal.eoFill boolValue];
    
    self.lineCapSegment.selectedSegmentIndex = [self.fractal.lineCap intValue];
    self.lineJoinSegment.selectedSegmentIndex = [self.fractal.lineJoin intValue];
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

#pragma mark - Actions
- (IBAction)toggleStroke:(UISwitch*)sender {
    self.fractal.stroke = @(sender.on);
}

- (IBAction)toggleFill:(UISwitch*)sender {
    self.fractal.fill = @(sender.on);
}

- (IBAction)lineWidthStepperChanged:(UIStepper*)sender {
    self.fractal.lineWidth = [sender valueForKey: @"value"];
    self.fractalWidth.text = [self.fractal.lineWidth stringValue];
}

- (IBAction)lineWidthIncrementInputChanged:(id)sender {
    self.fractal.lineWidthIncrement = [sender valueForKey: @"value"];
}
- (IBAction)lineLengthStepperChanged:(UIStepper*)sender {
    self.fractal.lineLength = @(sender.value);
    self.fractalLineLength.text = [self.fractal.lineLength stringValue];
}

- (IBAction)lineLengthScaleFactorInputChanged:(UIStepper*)sender {
    self.fractal.lineLengthScaleFactor = @(sender.value);
}

- (IBAction)turningAngleStepperInputChanged:(UIStepper*)sender {
    [self.fractalUndoManager beginUndoGrouping];
    [self.fractal.managedObjectContext processPendingChanges];
    [self.fractal setTurningAngleAsDegrees: @(sender.value)];
    self.fractalTurningAngle.text = [self.twoPlaceFormatter stringFromNumber: [self.fractal turningAngleAsDegree]];
}
- (IBAction)turningAngleTextInputChanged: (UITextField*)sender {
    [self.fractalUndoManager beginUndoGrouping];
    [self.fractal.managedObjectContext processPendingChanges];
    [self.fractal setTurningAngleAsDegrees: @([sender.text doubleValue])];
    self.turnAngleStepper.value = [[self.fractal turningAngleAsDegree] doubleValue];
    self.fractalTurningAngle.text = [self.twoPlaceFormatter stringFromNumber: [self.fractal turningAngleAsDegree]];
}


- (IBAction)turningAngleIncrementInputChanged:(UIStepper*)sender {
    [self.fractal setTurningAngleIncrementAsDegrees: @(sender.value)];
}


- (IBAction)toggleFillMode:(UISwitch *)sender {
    self.fractal.eoFill = @(sender.on);
}

- (IBAction)changeLineCap:(UISegmentedControl *)sender {
    self.fractal.lineCap = @(sender.selectedSegmentIndex);
}

- (IBAction)changeLineJoin:(UISegmentedControl *)sender {
    self.fractal.lineJoin = @(sender.selectedSegmentIndex);
}

- (IBAction)randomnessStepperChanged:(UIStepper *)sender {
    [self.fractalUndoManager beginUndoGrouping];
    [self.fractal.managedObjectContext processPendingChanges];
    self.fractal.randomness = @(sender.value);
    self.randomness.text = [self.twoPlaceFormatter stringFromNumber: [self.fractal randomness]];
    if (self.fractal.randomness == 0) {
        self.fractal.randomize = @NO;
    }
}

- (IBAction)randomnessInputChanged:(UITextField *)sender {
    [self.fractalUndoManager beginUndoGrouping];
    [self.fractal.managedObjectContext processPendingChanges];
    [self.fractal setRandomness: @([sender.text doubleValue])];
    self.randomnessStepper.value = [[self.fractal randomness] doubleValue];
    self.randomness.text = [self.twoPlaceFormatter stringFromNumber: [self.fractal randomness]];
    if (self.fractal.randomness == 0) {
        self.fractal.randomize = @NO;
    }
}
@end
