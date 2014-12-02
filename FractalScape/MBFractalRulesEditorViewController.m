//
//  MBFractalRulesEditorViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalRulesEditorViewController.h"
#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "LSDrawingRuleType+addons.h"

#import "MDBLSRuleTileView.h"
#import "MBLSRuleDragAndDropProtocol.h"

@interface MBFractalRulesEditorViewController ()
@property (nonatomic,strong) UIMotionEffectGroup                    *foregroundMotionEffect;
@property (nonatomic,strong) UIMotionEffectGroup                    *backgroundMotionEffect;
@property (nonatomic,strong) UIView<MBLSRuleDragAndDropProtocol>    *lastDragViewContainer;
@end

@implementation MBFractalRulesEditorViewController


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
    [self configureParallax];
}
-(void) configureParallax {
//    {
//        UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
//        xAxis.minimumRelativeValue = @(-15.0);
//        xAxis.maximumRelativeValue = @(15.0);
//        
//        UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
//        yAxis.minimumRelativeValue = @(-15.0);
//        yAxis.maximumRelativeValue = @(15.0);
//        
//        self.foregroundMotionEffect = [[UIMotionEffectGroup alloc] init];
//        self.foregroundMotionEffect.motionEffects = @[xAxis, yAxis];
//        
//        [self.foregroundView addMotionEffect:self.foregroundMotionEffect];
//    }
    
    {
        UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xAxis.minimumRelativeValue = @(25.0);
        xAxis.maximumRelativeValue = @(-25.0);
        
        UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yAxis.minimumRelativeValue = @(32.0);
        yAxis.maximumRelativeValue = @(-32.0);
        
        self.backgroundMotionEffect = [[UIMotionEffectGroup alloc] init];
        self.backgroundMotionEffect.motionEffects = @[xAxis, yAxis];
        
        [self.ruleTypeListView addMotionEffect:self.backgroundMotionEffect];
    }
}
-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.editing = YES;
    
    [self.scrollView flashScrollIndicators];
}
-(void) viewDidDisappear:(BOOL)animated {
    [self saveContext];
    [super viewDidDisappear:animated];
}
- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.fractal.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } else {
            //            self.fractalDataChanged = YES;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setFractal:(LSFractal *)fractal {
    _fractal = fractal;
    self.summaryEditView.fractal = self.fractal;
    self.rulesView.rules = [self.fractal mutableOrderedSetValueForKey: @"startingRules"];
    self.rulesView.context = self.fractal.managedObjectContext;
    self.replacementRules.replacementRules = [self.fractal mutableOrderedSetValueForKey: @"replacementRules"];
//    self.fractalStartRulesListView.rules = [_fractal mutableOrderedSetValueForKey: @"startingRules"];
    self.ruleTypeListView.type = self.fractal.drawingRulesType;
    [self.view setNeedsUpdateConstraints];
}

- (IBAction)ruleTypeLongGesture:(UILongPressGestureRecognizer *)sender {
    UIGestureRecognizerState gestureState = sender.state;
    BOOL reloadCell = NO;
    
    if (!self.draggingItem) {
        self.draggingItem = [[MBDraggingItem alloc] initWithItem: nil size: self.rulesView.tileWidth];
        //        self.draggingRule = [[MBDraggingRule alloc] init];
        //        self.draggingRule.size = 30;
        self.draggingItem.touchToDragViewOffset = CGPointMake(0.0, -40.0);
    }
    
    
    CGPoint touchPoint = [sender locationInView: self.view];
    
    if (self.draggingItem.view) {
        self.draggingItem.viewCenter = touchPoint;
    }
    
    // Scroll to keep dragging in view
    {
    CGFloat scrollTouchInsets = -20.0;
    CGRect dropImageRect = CGRectInset(self.draggingItem.view.frame, scrollTouchInsets, scrollTouchInsets);
    CGRect touchRect = CGRectInset(CGRectMake(touchPoint.x, touchPoint.y, 1, 1), scrollTouchInsets*2, scrollTouchInsets*2);
    CGRect visibleRect = CGRectUnion(dropImageRect, touchRect);
    CGFloat minX = CGRectGetMinX(visibleRect);
    CGFloat maxX = CGRectGetMaxX(visibleRect);
    CGFloat minY = CGRectGetMinY(visibleRect);
    CGFloat maxY = CGRectGetMaxY(visibleRect);
    CGPoint scrollTopLeft = [self.view convertPoint: CGPointMake(minX, minY) toView: self.scrollView];
    // does not account for scroll zooming.
    CGFloat width = maxX - minX;
    CGFloat height = maxY - minY;
    
    CGRect scrollVisibleRect = CGRectMake(scrollTopLeft.x, scrollTopLeft.y, width, height);
    [self.scrollView scrollRectToVisible: scrollVisibleRect animated: NO];
    }
    
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderDragImage = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: self.draggingItem.viewCenter withEvent: nil];
    
    UIView<MBLSRuleDragAndDropProtocol>* ddViewContainer;
    if ([viewUnderDragImage isKindOfClass: [MDBLSRuleTileView class]]) {
        ddViewContainer = (UIView<MBLSRuleDragAndDropProtocol>*)viewUnderDragImage.superview;
    } else if ([[viewUnderDragImage subviews].firstObject isKindOfClass: [MDBLSRuleTileView class]]) {
        ddViewContainer = viewUnderDragImage;
    }
    
    if (self.draggingItem && [self handlesDragAndDrop: viewUnderTouch] && gestureState == UIGestureRecognizerStateBegan) {
        CGPoint localPoint = [self.view convertPoint: touchPoint toView: viewUnderTouch];
        [viewUnderTouch dragDidStartAtLocalPoint: localPoint draggingItem: self.draggingItem];
        if (self.draggingItem.view && self.draggingItem.dragItem) {
            [self showInfoForView: viewUnderTouch];
            self.draggingItem.view.userInteractionEnabled = NO;
            [self.view addSubview: self.draggingItem.view];
            [self.view bringSubviewToFront: self.draggingItem.view];
            self.lastDragViewContainer = viewUnderTouch.superview;
        }
        
    } else if (self.draggingItem && gestureState == UIGestureRecognizerStateChanged) {
        
        CGPoint localPoint = [self.view convertPoint: self.draggingItem.viewCenter toView: ddViewContainer];

        if (self.lastDragViewContainer == nil && ddViewContainer != nil && [self handlesDragAndDrop: ddViewContainer]) {
            // entering
            [ddViewContainer dragDidEnterAtLocalPoint: localPoint draggingItem: self.draggingItem];
            self.lastDragViewContainer = ddViewContainer;
            
        } else if (self.lastDragViewContainer != nil && ddViewContainer != nil && self.lastDragViewContainer == ddViewContainer) {
            // changing
            [ddViewContainer dragDidChangeToLocalPoint: localPoint draggingItem: self.draggingItem];
            
        } else if (self.lastDragViewContainer != nil && (ddViewContainer == nil || self.lastDragViewContainer != ddViewContainer)) {
            // leaving
            [self.lastDragViewContainer dragDidEndDraggingItem: self.draggingItem];
            
            self.lastDragViewContainer = nil;
        }
        
    } else if (self.draggingItem && gestureState == UIGestureRecognizerStateEnded) {
        [self.draggingItem.view removeFromSuperview];
        self.draggingItem = nil;
        self.lastDragViewContainer = nil;
        
    } else if (self.draggingItem && gestureState == UIGestureRecognizerStateCancelled) {
        [self.draggingItem.view removeFromSuperview];
        self.draggingItem = nil;
        self.lastDragViewContainer = nil;
        
    } else if (self.draggingItem && gestureState == UIGestureRecognizerStateFailed) {
        [self.draggingItem.view removeFromSuperview];
        self.draggingItem = nil;
        self.lastDragViewContainer = nil;
        
    }
    
    if ([self.fractal hasChanges]) {
        [self saveContext];
    }
}
-(BOOL) handlesDragAndDrop: (id) anObject {
    return [anObject conformsToProtocol: @protocol(MBLSRuleDragAndDropProtocol)];
}
- (IBAction)replacementRuleLongPressGesture:(id)sender {
    [self ruleTypeLongGesture: sender];
}

- (IBAction)startRulesLongPressGesture:(UILongPressGestureRecognizer *)sender {
    [self ruleTypeLongGesture: sender];
}

- (IBAction)ruleTypeTapGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView: self.view];
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
    [self showInfoForView: viewUnderTouch];
}
-(void) showInfoForView: (UIView*) aView {
    BOOL hasItem = [aView respondsToSelector: @selector(item)];
    if (hasItem) {
        id item = [aView valueForKey:@"item"];
        BOOL hasDescriptorInfo = [item respondsToSelector: @selector(descriptor)];
        
        if (hasDescriptorInfo) {
            NSString* infoString = [item valueForKey: @"descriptor"];
            if ([infoString isKindOfClass: [NSString class]] && infoString.length > 0) {
                self.ruleHelpLabel.text = infoString;
                [self infoAnimateView: aView];
            }
        }
    }

}
-(void) infoAnimateView: (UIView*) aView {
    UIColor* oldColor = aView.backgroundColor;
    aView.backgroundColor = [UIColor lightGrayColor];
    [UIView animateWithDuration: 2.0 animations:^{
        //
        aView.backgroundColor = oldColor;
        
    } completion:^(BOOL finished) {
        //
    }];
}
- (IBAction)rulesStartTapGesture:(UITapGestureRecognizer *)sender {
    NSString* infoString = @"Holder for the starting set of rules to draw.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.rulesView];
}

- (IBAction)replacementTapGesture:(UITapGestureRecognizer *)sender {
    NSString* infoString = @"Occurences of rule to left of ':' replaced by rules to the right.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.replacementRules];
}
@end
