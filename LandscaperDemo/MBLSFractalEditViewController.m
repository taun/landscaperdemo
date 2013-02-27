//
//  MBLSFractalEditViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalEditViewController.h"
#import "MBFractalPropertyTableHeaderView.h"
//#import "MBLSFractalLevelNView.h"
#import "LSFractal+addons.h"
#import "LSFractalGenerator.h"
#import "LSReplacementRule.h"
#import "MBColor+addons.h"

#import "MBPortalStyleView.h"

#import "MBStepperTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

#include <math.h>
//
//static inline double radians (double degrees) {return degrees * M_PI/180.0;}
//static inline double degrees (double radians) {return radians * 180.0/M_PI;}
#define LOGBOUNDS 0

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


@property (nonatomic, strong) NSSet*                editControls;
@property (nonatomic, strong) NSMutableArray*       cachedEditViews;
@property (nonatomic, assign) NSInteger             cachedEditorsHeight;

@property (nonatomic, assign) double                viewNRotationFromStart;

@property (nonatomic, strong) UIBarButtonItem*      cancelButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      undoButtonItem;
@property (nonatomic, strong) UIBarButtonItem*      redoButtonItem;

@property (nonatomic,assign,getter=isCancelled) BOOL cancelled;

-(CALayer*) fractalLevelNLayer;

-(void) setEditMode: (BOOL) editing;
-(void) updateViewsForEditMode: (BOOL) editing;
-(void) moveEditorHeightTo: (NSInteger) height;
-(void) fullScreenOn;
-(void) fullScreenOff;

-(void) useFractalDefinitionRulesView;
-(void) useFractalDefinitionAppearanceView;
-(void) loadDefinitionViews;

- (void)updateUndoRedoBarButtonState;
- (void)setUpUndoManager;
- (void)cleanUpUndoManager;

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

#pragma mark Init
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
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
}

/*
 should only be called by viewDidLoad
 */
-(void) __savePortraitViewFrames {
    // This is only called when the nib is first loaded and the views have not been resized.
    double barHeight = self.navigationController.navigationBar.frame.size.height;
    
    double topMargin = 0;
    
    if (UIDeviceOrientationIsLandscape(self.interfaceOrientation)) {
        self.startedInLandscape = YES;
        // remove extra 20 pixels added when started in landscape but getting nib dimensions before autolayout.
        topMargin = 20.0;
    } else {
        self.startedInLandscape = NO;
    }
    
    CGRect frame = self.fractalView.superview.frame;
    //        CGRect frameNLessNav = CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height-barHeight-MBPORTALMARGIN);
    CGRect frameNLessNav = CGRectMake(frame.origin.x,frame.origin.y,frame.size.width,frame.size.height-barHeight-MBPORTALMARGIN-topMargin);
    NSDictionary* frame0 = (__bridge_transfer NSDictionary*) CGRectCreateDictionaryRepresentation(self.fractalViewLevel0.superview.frame);
    NSDictionary* frame1 = (__bridge_transfer NSDictionary*) CGRectCreateDictionaryRepresentation(self.fractalViewLevel1.superview.frame);
    NSDictionary* frameN = (__bridge_transfer NSDictionary*) CGRectCreateDictionaryRepresentation(frameNLessNav);
    
    self.portraitViewFrames = @{@"frame0": frame0, @"frame1": frame1, @"frameN": frameN};
    NSLog(@"%@ setPortraitViewFrames frame0 = %@; frame1 = %@; frameN = %@;", NSStringFromSelector(_cmd), frame0, frame1, frameN);
    
}

-(void)viewDidLoad {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    [super viewDidLoad];
    
    self.title = self.currentFractal.name;
    
    
//    NSArray* resources0 = [[NSBundle mainBundle] loadNibNamed:@"MBLSFractalLevelNView" owner:self options:nil];
//#pragma unused (resources0)
    //    self.fractalViewRoot = resources[0];
    //    UIImage* patternImage = [UIImage imageWithContentsOfFile: @"grey.png"];
    UIImage* patternImage = [UIImage imageNamed: @"linen-fine.jpg"];
    UIColor* newColor = [UIColor colorWithPatternImage: patternImage];
    self.fractalViewRoot.backgroundColor = newColor;
//    self.fractalViewRoot.frame = self.fractalViewHolder.bounds;
//    [self.fractalViewHolder addSubview: self.fractalViewRoot];
    

    //    self.fractalViewLevelN = nil
    [self logBounds: self.fractalViewHolder.bounds info: @"fractalViewHolder"];
    [self logBounds: self.fractalViewParent.bounds info: @"fractalViewView"];
    [self logBounds: self.fractalView.bounds info: @"fractalView"];
    
    if (self.portraitViewFrames == nil) {
        // we want to save the frames as layed out in the nib.
        [self __savePortraitViewFrames];
    }
    
//    NSArray* resources1 = [[NSBundle mainBundle] loadNibNamed:@"MBFractalPropertyTableHeaderView" owner:self options:nil];
//#pragma unused (resources1)
    
    //    UIView* header = self.fractalPropertyTableHeaderView;
    //
    //    header.backgroundColor = [UIColor groupTableViewBackgroundColor];
    //    self.fractalPropertiesTableView.allowsSelectionDuringEditing = YES;
    //    self.fractalPropertiesTableView.tableHeaderView = header;
    //
    //    NSDictionary *views = NSDictionaryOfVariableBindings(header);
    //    [self.fractalPropertiesTableView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[header]-0-|" options:0 metrics:nil views:views]];
    //    [self.fractalPropertiesTableView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[header]-0-|" options:0 metrics:nil views:views]];
    
    [self setupLevelGeneratorForView: self.fractalView name: @"fractalLevelN" forceLevel: -1];
    [self setupLevelGeneratorForView: self.fractalViewLevel1 name: @"fractalLevel1" forceLevel: 1];
    
    self.fractalAxiom.inputView = self.fractalInputControl.view;

    [self.fractalPanGR requireGestureRecognizerToFail: self.fractalRightSwipeGR];
    [self.fractalPanGR requireGestureRecognizerToFail: self.fractalLeftSwipeGR];
    [self.fractalPanGR requireGestureRecognizerToFail: self.fractalUpSwipeGR];
    [self.fractalPanGR requireGestureRecognizerToFail: self.fractalDownSwipeGR];
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
    
    [self logBounds: self.fractalViewHolder.bounds info: @"fractalViewHolder"];
    [self logBounds: self.fractalViewParent.bounds info: @"fractalViewView"];
    [self logBounds: self.fractalView.bounds info: @"fractalView"];
    
    if (!self.editing) {
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
    }
    //    for (CALayer* layer in self.fractalView.layer.sublayers) {
    //        if ([layer.name isEqualToString: @"fractalLevelN"]) {
    //            [self fitLayer: layer inLayer: self.fractalView.superview.layer margin: 5];
    //            // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
    //        }
    //    }
}

-(void) viewWillAppear:(BOOL)animated {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    //    self.editing = NO;
    [super viewWillAppear:animated];
    
}

-(void) viewDidAppear:(BOOL)animated {
    
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    [super viewDidAppear:animated];
    [self refreshContents];
    [self logBounds: self.fractalViewHolder.bounds info: @"fractalViewHolder"];
    [self logBounds: self.fractalViewParent.bounds info: @"fractalViewView"];
    [self logBounds: self.fractalView.bounds info: @"fractalView"];

//    if (self.cachedEditorsHeight==0) {
//        self.cachedEditorsHeight = self.fractalEditorsHolder.frame.size.height;
//    }
    self.editing = YES;
}

-(void)viewWillDisappear:(BOOL)animated {
    
    if (self.editing) {
        [self.currentFractal.managedObjectContext save: nil];
        [self setUndoManager: nil];
    } else {
        // undo all non-saved changes
        [self.currentFractal.managedObjectContext rollback];
    }
    //	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

-(void)viewDidUnload {
    //should save be here or at higher level
    // Only need to save if still in edit mode
    if (self.editing) {
        [self.currentFractal.managedObjectContext save: nil];
        [self setUndoManager: nil];
    } else {
        // undo all non-saved changes
        [self.currentFractal.managedObjectContext rollback];
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
    [self setLevelSlider:nil];
    [self setFractalBaseAngle:nil];
    [self setACopyButtonItem: nil];
    [self setFractalPropertyTableHeaderView:nil];
    [self setFractalPropertiesTableView:nil];    

    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
        
        //        [self.undoManager beginUndoGrouping];
        
        
    } else {
        
        //[self.undoManager endUndoGrouping];
        
        if (self.isCancelled) {
            //            NSManagedObjectID* objectID = self.currentFractal.objectID;
            //            NSManagedObjectContext* moc = self.currentFractal.managedObjectContext;
            
            [self.currentFractal.managedObjectContext rollback];
            self.cancelled = NO;
            // reload fractal from store.
            //            self.currentFractal = (LSFractal*)[moc objectRegisteredForID: objectID];
        } else {
            // Save the changes.
            NSError *error;
            if (![self.currentFractal.managedObjectContext save:&error]) {
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
    
    [self setEditMode: editing];
    [self.fractalPropertiesTableView setEditing: editing animated: animated];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Getters & Setters
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

-(NSMutableArray*) cachedEditViews {
    if (_cachedEditViews==nil) {
        _cachedEditViews = [[NSMutableArray alloc] initWithCapacity: 3];
    }
    return _cachedEditViews;
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

-(NSMutableDictionary*) rulesCellIndexPaths {
    if (_rulesCellIndexPaths == nil) {
        _rulesCellIndexPaths = [[NSMutableDictionary alloc] initWithCapacity: 5];
    }
    return _rulesCellIndexPaths;
}

-(UIBarButtonItem*) cancelButtonItem {
    if (_cancelButtonItem == nil) {
        _cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel 
                                                                          target:self 
                                                                          action:@selector(cancelEdit:)];
        
    }
    return _cancelButtonItem;
}

-(UIBarButtonItem*) undoButtonItem {
    if (_undoButtonItem == nil) {
        _undoButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemUndo 
                                                                        target:self 
                                                                        action:@selector(undoEdit:)];
    }
    return _undoButtonItem;
}

-(UIBarButtonItem*) redoButtonItem {
    if (_redoButtonItem == nil) {
        _redoButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRedo 
                                                                        target:self 
                                                                        action:@selector(redoEdit:)];
    }
    return _redoButtonItem;
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
                                                                        action:@selector(toggleAutoScale:)];
        
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

-(NSSet*) editControls {
    if (_editControls == nil) {
        _editControls = [[NSSet alloc] initWithObjects: 
                         self.fractalName,
                         self.fractalCategory,
                         self.fractalDescriptor,
                         nil];
//                         self.levelSlider,
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
        //        CGAffineTransform rotateCC = CGAffineTransformMakeRotation(-M_PI_2);
        //        [_sliderContainerView setTransform: rotateCC];
    }
}

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

-(CALayer*) fractalLevelNLayer {
    CALayer* subLayer;
    for (CALayer* layer in self.fractalView.layer.sublayers) {
        if ([layer.name isEqualToString: @"fractalLevelN"]) {
            subLayer = layer;
        }
    }
    return subLayer;
}

-(void) setFractalViewLevel0:(UIView *)fractalViewLevel0 {
    _fractalViewLevel0 = fractalViewLevel0;
    UIRotationGestureRecognizer* rgr = [[UIRotationGestureRecognizer alloc] 
                                        initWithTarget: self 
                                        action: @selector(rotateTurningAngle:)];
    
    [_fractalViewLevel0 addGestureRecognizer: rgr];
    
    [self setupLevelGeneratorForView: _fractalViewLevel0 name: @"fractalLevel0" forceLevel: 0];
}


#pragma mark - Fractal Property KVO
//TODO: change so replacementRulesArray is cached and updated when rules are updated.
/*
 If the passed fractal a read-only instance,
 create a read-write copy of the passed fractal.
 
 Id there  method for copying a fractal? Should be just [fractal mutableCopy]
 */
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
        NSArray* descriptors = @[sort];
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
    aLayer.speed = 10.0;
    aLayer.drawsAsynchronously = YES;
    
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    [self updateUndoRedoBarButtonState];
    
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


#pragma mark - view utility methods

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
    self.slider.value = [self.currentFractal.level doubleValue];
    self.levelSlider.value = [self.currentFractal.level doubleValue];
    //    
    //    self.strokeSwitch.on = [self.currentFractal.stroke boolValue];
    //    self.fillSwitch.on = [self.currentFractal.fill boolValue];
    self.hudText2.text =[self.twoPlaceFormatter stringFromNumber: [self.currentFractal turningAngleAsDegree]];
}

-(void) refreshLayers {
    self.hudText1.text = [self.currentFractal.level stringValue];
    self.hudText2.text = [self.twoPlaceFormatter stringFromNumber: [self.currentFractal turningAngleAsDegree]];
    
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
    [self.fractalPropertiesTableView reloadData];
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
        if ([self.undoManager canRedo]) {
            self.redoButtonItem.enabled = YES;
        } else {
            self.redoButtonItem.enabled = NO;
        }
        
        [self logGroupingLevelFrom: NSStringFromSelector(_cmd)];
        NSInteger level = [self.undoManager groupingLevel] > 0;
        if ([self.undoManager canUndo] && level) {
            self.undoButtonItem.enabled = YES;
        } else {
            self.undoButtonItem.enabled = NO;
        }
    }
}

//TODO: add Undo and Redo buttons for editing
- (void) configureNavButtons {
    
    NSMutableArray *rightButtons, *leftButtons;
    
    
    if ([self.currentFractal.isImmutable boolValue]) {
        // no edit button if it is read only
        rightButtons = [[NSMutableArray alloc] initWithObjects: self.aCopyButtonItem, nil];
        
        self.navigationItem.title = [NSString stringWithFormat: @"%@ (read-only)", self.title];
        
    } else if (self.editing) {
        self.navigationItem.title = [NSString stringWithFormat: @"%@ (editing)", self.title];
        
        leftButtons = [[NSMutableArray alloc] initWithObjects: self.cancelButtonItem,self.spaceButtonItem, self.undoButtonItem, self.redoButtonItem, nil];
        
        // include edit button but no copy button
        rightButtons = [[NSMutableArray alloc] initWithObjects: self.editButtonItem, self.spaceButtonItem, nil];
        
    } else {
        self.navigationItem.title = self.title;
        // copy and edit button        
        rightButtons = [[NSMutableArray alloc] initWithObjects: self.editButtonItem, self.spaceButtonItem, self.aCopyButtonItem, nil];
    }
    
    [rightButtons addObject: self.infoButtonItem];
    
    self.navigationItem.leftItemsSupplementBackButton = YES;

    [self updateUndoRedoBarButtonState];
    
    [UIView animateWithDuration:0.20 animations:^{
        self.navigationItem.rightBarButtonItems = rightButtons;
        
        self.navigationItem.leftBarButtonItems = leftButtons;
    }];

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
    [self.currentFractal.managedObjectContext redo];
}

/*
 since we are using core data, all we need to do to undo all changes and cancel the edit session is not save the core data and use rollback.
 */
- (IBAction)cancelEdit:(id)sender {
    self.cancelled = YES;
    [self setEditing: NO animated: YES];
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
            if (editing) {
                tf.layer.borderColor = [[UIColor colorWithWhite: 0.75 alpha: 1.0] CGColor];
                tf.layer.borderWidth = 1.0;
                tf.layer.cornerRadius = 8.0;
                // Would need to add another layer to have a shadow.
                //tf.layer.shadowOpacity = 0.5;
                //tf.layer.shadowOffset = CGSizeMake(5.0, 5.0);
                //tf.layer.masksToBounds = NO;
            } else {
                tf.layer.borderColor = [[UIColor colorWithWhite: 1.0 alpha: 1.0] CGColor];
                //tf.layer.shadowOpacity = 0.0;
            }
            
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
    
    return YES;
}

- (IBAction)copyFractal:(id)sender {
    LSFractal* fractal = self.currentFractal;
    
    // copy
    LSFractal* copiedFractal = [fractal mutableCopy];
    
    self.currentFractal = copiedFractal;
    
    // coalesce to a common method for saving, copy from appDelegate
    NSError *error;
    if (![self.currentFractal.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self refreshContents];
}

- (IBAction)levelInputChanged:(UIControl*)sender {
    double rawValue = [[sender valueForKey: @"value"] doubleValue];
    NSNumber* roundedNumber = @(lround(rawValue));
    self.currentFractal.level = roundedNumber;
}

-(IBAction) rotateTurningAngle:(UIRotationGestureRecognizer*)sender {
    if (self.editing) {
        
        NSIndexPath* turnAngleIndex = (self.appearanceCellIndexPaths)[@"turningAngle"];
        
        if (turnAngleIndex) {
            [self.fractalPropertiesTableView scrollToRowAtIndexPath: turnAngleIndex
                                                   atScrollPosition: UITableViewScrollPositionMiddle
                                                           animated: YES];
            
        }
        
        
        double stepRadians = radians(self.turnAngleStepper.stepValue);
        // 2.5 degrees -> radians
        
        double deltaTurnToDeltaGestureRatio = 1.0/6.0;
        // reduce the sensitivity to make it easier to rotate small degrees
        
        double deltaTurnAngle = [self convertAndQuantizeRotationFrom: sender
                                                              quanta: stepRadians
                                                               ratio: deltaTurnToDeltaGestureRatio];
        
        if (deltaTurnAngle != 0.0 ) {
            double newAngle = remainder([self.currentFractal.turningAngle doubleValue]-deltaTurnAngle, M_PI*2);
            self.currentFractal.turningAngle = @(newAngle);
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
            self.currentFractal.baseAngle = @(newAngle);
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

}

- (IBAction)swipeFractal:(UISwipeGestureRecognizer *)gestureRecognizer {
    
    if (self.editing) {
        UIGestureRecognizerState state = gestureRecognizer.state;
        
        if (state == UIGestureRecognizerStatePossible) {
            
        } else if (state == UIGestureRecognizerStateRecognized) {
            
            if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
                [self decrementLineWidth: nil];
            } else if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
                [self incrementLineWidth: nil];
            } else if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionUp) {
                [self incrementTurnAngle: nil];
            } else if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionDown) {
                [self decrementTurnAngle: nil];
            }
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
}

-(void) autoScale:(id)sender {
    [self fitLayer: [self fractalLevelNLayer] inLayer: self.fractalView.superview.layer margin: 5];
    // needsDisplayOnBoundsChange = YES, ensures layer will be redrawn.
}


#pragma mark - control actions
- (IBAction)nameInputDidEnd:(UITextField*)sender {
    self.currentFractal.name = sender.text;
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

- (IBAction)incrementLineWidth:(id)sender {
    double width = [self.currentFractal.lineWidth doubleValue];
    double increment = [self.currentFractal.lineWidthIncrement doubleValue];
    
    [self.undoManager beginUndoGrouping];
    self.currentFractal.lineWidth = @(fmax(width+increment, 1.0));
}

- (IBAction)decrementLineWidth:(id)sender {
    double width = [self.currentFractal.lineWidth doubleValue];
    double increment = [self.currentFractal.lineWidthIncrement doubleValue];
    
    [self.undoManager beginUndoGrouping];
    self.currentFractal.lineWidth = @(fmax(width-increment, 1.0));
}

//TODO: User preference for turnAngle swipe increment
- (IBAction)incrementTurnAngle:(id)sender {
    [self.undoManager beginUndoGrouping];
    [self.currentFractal.managedObjectContext processPendingChanges];
    [self.currentFractal setTurningAngleAsDegrees:  @([self.currentFractal.turningAngleAsDegree doubleValue] + 0.5)];
}
- (IBAction)decrementTurnAngle:(id)sender {
    [self.undoManager beginUndoGrouping];
    [self.currentFractal.managedObjectContext processPendingChanges];
    [self.currentFractal setTurningAngleAsDegrees:  @([self.currentFractal.turningAngleAsDegree doubleValue] - 0.5)];
}
- (IBAction)toggleStroke:(UISwitch*)sender {
    self.currentFractal.stroke = @(sender.on);
}

- (IBAction)toggleFill:(UISwitch*)sender {
    self.currentFractal.fill = @(sender.on);
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
    self.currentFractal.lineLength = @(sender.value);
}

- (IBAction)lineLengthScaleFactorInputChanged:(UIStepper*)sender {
    self.currentFractal.lineLengthScaleFactor = @(sender.value);
}

- (IBAction)turningAngleInputChanged:(UIStepper*)sender {
    [self.undoManager beginUndoGrouping];
    [self.currentFractal.managedObjectContext processPendingChanges];
    [self.currentFractal setTurningAngleAsDegrees: @(sender.value)];
    [self logGroupingLevelFrom: NSStringFromSelector(_cmd)];
}

- (IBAction)turningAngleIncrementInputChanged:(UIStepper*)sender {
    [self.currentFractal setTurningAngleIncrementAsDegrees: @(sender.value)];
}

- (IBAction)switchFractalDefinitionView:(UISegmentedControl*)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self useFractalDefinitionRulesView];
        
    } else if(sender.selectedSegmentIndex == 1) {
        [self useFractalDefinitionAppearanceView];
    }
}


// TODO: copy app delegate saveContext method

#pragma mark - ColorPicker Delegate Protocol
//TODO: check for pre-existing colors, maybe only allow selecting from pre-existing colors? replacing colorPicker with swatches?
- (void)colorPickerSaved:(ColorPickerController *)controller {
    
    MBColor* newColor = [MBColor mbColorWithUIColor: controller.selectedColor inContext: self.currentFractal.managedObjectContext];
    MBColor* currentColor = [self.currentFractal valueForKey: self.coloringKey];
    
    NSString* camelCase = [self.coloringKey stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString: [[self.coloringKey substringWithRange: NSMakeRange(0, 1)] uppercaseString]];
    
    NSString* selectorString = [NSString stringWithFormat: @"set%@:", camelCase];
            
    [self.undoManager beginUndoGrouping];
    
    [self.undoManager registerUndoWithTarget: self.currentFractal selector: NSSelectorFromString(selectorString) object: currentColor];
    
    [self.currentFractal setValue: newColor forKey: self.coloringKey];
    
    [self.undoManager endUndoGrouping];
}

- (void)colorPickerUndo:(ColorPickerController *)controller {
    if ([self.undoManager canUndo]) {
        [self.undoManager undo];
    }
}

- (void)colorPickerRedo:(ColorPickerController *)controller {
    if ([self.undoManager canRedo]) {
        [self.undoManager redo];
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
    
    cell.propertyImage.image = [UIImage imageNamed: settings[@"imageName"]];
    cell.propertyLabel.text = settings[@"label"];
    cell.formatter = [self.twoPlaceFormatter copy];
    //        [stepperCell addObserver: stepperCell forKeyPath: @"stepper.value" options: NSKeyValueObservingOptionNew context: NULL];
    
    //        self.fractalTurningAngle = stepperCell.value;
    
    UIStepper* stepper = cell.stepper;
    self.turnAngleStepper = stepper;
    
    stepper.minimumValue = [settings[@"minimumValue"] doubleValue];
    stepper.maximumValue = [settings[@"maximumValue"] doubleValue];
    stepper.stepValue = [settings[@"stepValue"] doubleValue];
    stepper.value = [[self.currentFractal valueForKey: settings[@"propertyValueKey"]] doubleValue];
    
    // manually call to set the textField to the stepper value
    //        [stepperCell stepperValueChanged: stepper];
    
    [stepper addTarget: self
                action: NSSelectorFromString(settings[@"actionSelectorString"])
      forControlEvents: UIControlEventValueChanged];
    
    (self.appearanceCellIndexPaths)[settings[@"propertyValueKey"]] = indexPath;
    
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
        LSReplacementRule* rule = (self.replacementRulesArray)[indexPath.row];
        
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
        (self.rulesCellIndexPaths)[rule.contextString] = indexPath;
        
    } else if (indexPath.section == SectionAppearance) {
        // appearance
        MBStepperTableViewCell *stepperCell = (MBStepperTableViewCell *)[tableView dequeueReusableCellWithIdentifier: StepperCellIdentifier];
        
        cell = [self populateStepperCell: stepperCell
                        withSettingsFrom: (self.fractalPropertiesAppearanceSectionDefinitions)[indexPath.row]
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
        [anUndoManager setLevelsOfUndo:50];
        [anUndoManager setGroupsByEvent: NO];
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
    [self refreshContents];
}


- (void)undoManagerDidRedo:(NSNotification *)notification {
    [self refreshContents];
}

#pragma Utilities

-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo {
    if (LOGBOUNDS) {
        CFDictionaryRef boundsDict = CGRectCreateDictionaryRepresentation(bounds);
        NSString* boundsDescription = [(__bridge NSString*)boundsDict description];
        CFRelease(boundsDict);
        
        NSLog(@"%@ = %@", boundsInfo,boundsDescription);
    }
}
-(void) logGroupingLevelFrom:  (NSString*) cmd {
    if (NO) {
        NSLog(@"%@: Undo group levels = %u", cmd, [self.undoManager groupingLevel]);
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
    self.currentFractal = nil; // removes observers via custom setter call
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }
}

@end
