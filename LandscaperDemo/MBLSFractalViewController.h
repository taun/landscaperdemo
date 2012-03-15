//
//  MBLSFractalViewController.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/08/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LSFractal;
//@class MBLSFractalLevelNView;

@interface MBLSFractalViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, strong) LSFractal*                      currentFractal;

@property (weak, nonatomic)  IBOutlet UITextField*  fractalName;
@property (weak, nonatomic)  IBOutlet UITextField*  fractalCategory;
@property (weak, nonatomic)  IBOutlet UITextView*   fractalDescriptor;

@property (weak, nonatomic) IBOutlet UIView*        fractalViewHolder;

@property (weak, nonatomic) IBOutlet UIView*        fractalViewView;
@property (weak, nonatomic) IBOutlet UIView*        fractalView;
@property (weak, nonatomic) IBOutlet UIView*        sliderContainerView;
@property (weak, nonatomic) IBOutlet UIView*        hudViewBackground;

@property (weak, nonatomic) IBOutlet UISlider*      slider;
@property (weak, nonatomic) IBOutlet UILabel*       hudLabel;
@property (weak, nonatomic) IBOutlet UILabel*       hudText1;
@property (weak, nonatomic) IBOutlet UILabel*       hudText2;


/*
 So a setNeedsDisplay can be sent to each layer when a fractal property is changed.
 */
@property (nonatomic, strong) NSMutableArray*               fractalDisplayLayersArray;
/*
 a generator for each level being displayed.
 */
@property (nonatomic, strong) NSMutableArray*               generatorsArray; 
@property (nonatomic, strong) NSArray*                      replacementRulesArray;
@property (nonatomic, strong) NSNumberFormatter*            twoPlaceFormatter;
@property (nonatomic, strong) UIBarButtonItem*              aCopyButtonItem;
@property (nonatomic, strong) UIBarButtonItem*              infoButtonItem;
@property (nonatomic, strong) UIBarButtonItem*              spaceButtonItem;



-(void) logBounds: (CGRect) bounds info: (NSString*) boundsInfo;

-(void) setupLevelGeneratorForView: (UIView*) aView name: (NSString*) name forceLevel: (NSInteger) aLevel;
-(void) fitLayer: (CALayer*) layerInner inLayer: (CALayer*) layerOuter margin: (double) margin;
-(void) configureNavButtons;
-(void) reloadLabels;
-(void) refreshLayers;
-(void) refreshValueInputs;
-(void) refreshContents;

-(double) convertAndQuantizeRotationFrom: (UIRotationGestureRecognizer*)sender quanta: (double) stepRadians ratio: (double) deltaAngleToDeltaGestureRatio;

- (IBAction)levelInputChanged: (UIControl*)sender;
- (IBAction) rotateTurningAngle:(UIRotationGestureRecognizer*)gestureRecognizer;
- (IBAction)panFractal:(UIPanGestureRecognizer *)gestureRecognizer;
- (IBAction)swipeFractal:(UISwipeGestureRecognizer *)gestureRecognizer;
- (IBAction)rotateFractal:(UIRotationGestureRecognizer*)gestureRecognizer;
- (IBAction)magnifyFractal:(UILongPressGestureRecognizer*)gestureRecognizer;
- (IBAction)scaleFractal:(UIPinchGestureRecognizer *)gestureRecognizer;
@end
