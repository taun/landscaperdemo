//
//  MBLSFractalViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/08/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalViewController.h"
#import "LSFractal+addons.h"
#import "LSFractalGenerator.h"
#import "MBColor+addons.h"
#import "MBPortalStyleView.h"
//#import "MBLSFractalLevelNView.h"

#import "LSFractalGenerator.h"
#import "LSReplacementRule.h"

#import <QuartzCore/QuartzCore.h>

#include <math.h>


@interface MBLSFractalViewController ()

@end

@implementation MBLSFractalViewController

@synthesize currentFractal = _currentFractal;
@synthesize fractalName = _fractalName, fractalCategory = _fractalCategory;
@synthesize fractalDescriptor = _fractalDescriptor;
@synthesize fractalViewHolder = _fractalViewHolder;
@synthesize fractalViewView = _fractalViewView;

@synthesize generatorsArray = _generatorsArray;
@synthesize replacementRulesArray = _replacementRulesArray;
@synthesize fractalDisplayLayersArray = _fractalDisplayLayersArray;
@synthesize twoPlaceFormatter = _twoPlaceFormatter;
@synthesize aCopyButtonItem = _aCopyButtonItem;
@synthesize spaceButtonItem = _spaceButtonItem, infoButtonItem = _infoButtonItem;

@synthesize fractalView = _fractalView, sliderContainerView = _sliderContainerView;
@synthesize hudViewBackground = _hudViewBackground;

@synthesize slider = _slider;
@synthesize hudLabel = _hudLabel, hudText1 = _hudText1, hudText2 = _hudText2;

-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo {
    CFDictionaryRef boundsDict = CGRectCreateDictionaryRepresentation(bounds);
    NSString* boundsDescription = [(__bridge NSString*)boundsDict description];
    CFRelease(boundsDict);
    
    NSLog(@"%@ = %@", boundsInfo,boundsDescription);
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


#pragma mark - Getters & Setters
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

-(void) setSliderContainerView:(UIView *)sliderContainerView {
    if (_sliderContainerView != sliderContainerView) {
        _sliderContainerView = sliderContainerView;
        CGAffineTransform rotateCC = CGAffineTransformMakeRotation(-M_PI_2);
        [_sliderContainerView setTransform: rotateCC];
    }
}

-(void) setFractalView:(UIView *)fractalView {
    if (_fractalView != fractalView) {
        _fractalView = fractalView;
        
        UIRotationGestureRecognizer* rgr = [[UIRotationGestureRecognizer alloc] 
                                            initWithTarget: self 
                                            action: @selector(rotateTurningAngle:)];
        
        [_fractalView addGestureRecognizer: rgr];
        
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] 
                                                  initWithTarget:self 
                                                  action:@selector(scaleFractal:)];
        
        [pinchGesture setDelegate:self];
        [_fractalView addGestureRecognizer: pinchGesture];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] 
                                              initWithTarget:self 
                                              action:@selector(panFractal:)];
        
        [panGesture setMaximumNumberOfTouches:2];
        [panGesture setDelegate:self];
        
        [_fractalView addGestureRecognizer:panGesture];

        [self setupLevelGeneratorForView: _fractalView name: @"fractalLevelN" forceLevel: -1];
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

-(UIBarButtonItem*) infoButtonItem {
    if (_infoButtonItem == nil) {
        _infoButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemOrganize 
                                                                        target:self 
                                                                        action:@selector(info:)];
        
    }
    return _infoButtonItem;
}

-(UIBarButtonItem*) spaceButtonItem {
    if (_spaceButtonItem == nil) {
        _spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace 
                                                                         target:self 
                                                                         action:nil];
        _spaceButtonItem.width = 10.0;
    }
    return _spaceButtonItem;
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

#pragma mark - view utility methods

-(void) reloadLabels {
    self.fractalName.text = self.currentFractal.name;
    self.fractalCategory.text = self.currentFractal.category;
    self.fractalDescriptor.text = self.currentFractal.descriptor;
}

-(void) refreshValueInputs {    
    self.slider.value = [self.currentFractal.level doubleValue];
}

-(void) refreshLayers {
    self.hudText1.text = [self.currentFractal.level stringValue];
    self.hudText2.text = [self.twoPlaceFormatter stringFromNumber: [self.currentFractal baseAngleAsDegree]];
    
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
    [self configureNavButtons];
}

- (void) configureNavButtons {
    
    NSMutableArray *rightButtons, *leftButtons;
    
    
    if ([self.currentFractal.isImmutable boolValue]) {
        // no edit button if it is read only
        rightButtons = [[NSMutableArray alloc] initWithObjects: self.aCopyButtonItem, nil];
        
        self.navigationItem.title = [NSString stringWithFormat: @"%@ (read-only)", self.title];
        
    } else {
        self.navigationItem.title = self.title;
        // copy and edit button        
        rightButtons = [[NSMutableArray alloc] initWithObjects: self.editButtonItem, self.spaceButtonItem, self.aCopyButtonItem, nil];
    }
    
    [rightButtons addObject: self.infoButtonItem];
    
    self.navigationItem.leftItemsSupplementBackButton = YES;
        
    [UIView animateWithDuration:0.20 animations:^{
        self.navigationItem.rightBarButtonItems = rightButtons;
        
        self.navigationItem.leftBarButtonItems = leftButtons;
    }];
    
}

#pragma mark - action utility methods
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
- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

#pragma mark - actions

- (IBAction)levelInputChanged:(UIControl*)sender {
    double rawValue = [[sender valueForKey: @"value"] doubleValue];
    NSNumber* roundedNumber = [NSNumber numberWithLong: lround(rawValue)];
    self.currentFractal.level = roundedNumber;
}

-(IBAction) rotateTurningAngle:(UIRotationGestureRecognizer*)gestureRecognizer {
    double stepRadians = radians(2.5);
    // 2.5 degrees -> radians
    
    double deltaTurnToDeltaGestureRatio = 1.0/6.0;
    // reduce the sensitivity to make it easier to rotate small degrees
    
    double deltaTurnAngle = [self convertAndQuantizeRotationFrom: gestureRecognizer 
                                                          quanta: stepRadians 
                                                           ratio: deltaTurnToDeltaGestureRatio];
    
    if (deltaTurnAngle != 0.0 ) {
        double newAngle = remainder([self.currentFractal.turningAngle doubleValue]-deltaTurnAngle, M_PI*2);
        self.currentFractal.turningAngle = [NSNumber numberWithDouble: newAngle];
    }
}

-(IBAction) rotateFractal:(UIRotationGestureRecognizer*)gestureRecognizer {
    [self adjustAnchorPointForGestureRecognizer: gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        [gestureRecognizer view].transform = CGAffineTransformRotate([[gestureRecognizer view] transform], [gestureRecognizer rotation]);
        [gestureRecognizer setRotation:0];
    }
}

- (IBAction)panFractal:(UIPanGestureRecognizer *)gestureRecognizer {
    UIView *fractalView = [gestureRecognizer view];
    
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gestureRecognizer translationInView:[fractalView superview]];
        
        [fractalView setCenter:CGPointMake([fractalView center].x + translation.x, [fractalView center].y + translation.y)];
        [gestureRecognizer setTranslation:CGPointZero inView:[fractalView superview]];
    }
}


- (IBAction)magnifyFractal:(UILongPressGestureRecognizer*)sender {
    
}

- (IBAction)scaleFractal:(UIPinchGestureRecognizer *)gestureRecognizer {
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        [gestureRecognizer view].transform = CGAffineTransformScale([[gestureRecognizer view] transform], [gestureRecognizer scale], [gestureRecognizer scale]);
        [gestureRecognizer setScale:1];
    }
}

// ensure that the pinch, pan and rotate gesture recognizers on a particular view can all recognize simultaneously
// prevent other gesture recognizers from recognizing simultaneously
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // if the gesture recognizers's view isn't one of our pieces, don't allow simultaneous recognition
    if (gestureRecognizer.view != self.fractalView)
        return NO;
    
    // if the gesture recognizers are on different views, don't allow simultaneous recognition
    if (gestureRecognizer.view != otherGestureRecognizer.view)
        return NO;
    
    // if either of the gesture recognizers is the long press, don't allow simultaneous recognition
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
        return NO;
    
    return YES;
}

#pragma mark - UIView methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIViewController Methods
- (void)viewDidLoad {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    [super viewDidLoad];
    
    self.title = self.currentFractal.name;
    
    
    NSArray* resources = [[NSBundle mainBundle] loadNibNamed:@"MBLSFractalLevelNView" owner:self options:nil];
    self.fractalViewView = [resources objectAtIndex: 0];
    self.fractalViewView.frame = self.fractalViewHolder.bounds;
    [self.fractalViewHolder addSubview: self.fractalViewView];
//    self.fractalViewLevelN = nil
    [self logBounds: self.fractalViewHolder.bounds info: @"fractalViewHolder"];
    [self logBounds: self.fractalViewView.bounds info: @"fractalViewView"];
    [self logBounds: self.fractalView.bounds info: @"fractalView"];
}

- (void)viewWillAppear:(BOOL)animated {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    [super viewWillAppear:animated];
    
}

-(void) viewDidLayoutSubviews {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];

    for (CALayer* layer in self.fractalView.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevelN"]) {
            [self fitLayer: layer inLayer: self.fractalView.superview.layer margin: 5];
            // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
        }
    }
    [self logBounds: self.fractalViewHolder.bounds info: @"fractalViewHolder"];
    [self logBounds: self.fractalViewView.bounds info: @"fractalViewView"];
    [self logBounds: self.fractalView.bounds info: @"fractalView"];

}

- (void) viewDidAppear:(BOOL)animated {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    [super viewDidAppear:animated];
    [self refreshContents];
    [self logBounds: self.fractalViewHolder.bounds info: @"fractalViewHolder"];
    [self logBounds: self.fractalViewView.bounds info: @"fractalViewView"];
    [self logBounds: self.fractalView.bounds info: @"fractalView"];
}

- (void)viewWillDisappear:(BOOL)animated {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    // undo all non-saved changes
    [self.currentFractal.managedObjectContext rollback];

	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }

    [self setReplacementRulesArray: nil];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

-(void) dealloc {
    self.currentFractal = nil; // removes observers via custom setter call
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }
}

@end
