//
//  MDBLSObjectTilesViewBaseController.m
//  
//
//  Created by Taun Chapman on 12/03/14.
//
//

#import "MDBLSObjectTilesViewBaseController.h"

@interface MDBLSObjectTilesViewBaseController ()

@end

@implementation MDBLSObjectTilesViewBaseController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) setFractal:(LSFractal *)fractal {
    _fractal = fractal;
    [self updateFractalDependents];
}

-(void) updateFractalDependents {
    
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    UITraitCollection* traits = self.traitCollection;
    NSLog(@"Trait collection: %@", traits);
}
/*!
 It appears, sometimes the tabView has loaded the childViewController's view before setting the fractal and sometimes after.
 By ensuring the fractalDependents are updated after viewDidLoad, it doesn't matter which happens first.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.fractal) {
        [self updateFractalDependents];
    }
    [self configureParallax];
}

-(void) viewWillLayoutSubviews {
//    [self.sourceListView setNeedsUpdateConstraints];
    [self.sourceListView setNeedsLayout];
//    [self.destinationView setNeedsUpdateConstraints];
    [self.destinationView setNeedsLayout];

    // Hack to get the label to adjust size after the transition.
    NSString* info = self.ruleHelpLabel.text;
    self.ruleHelpLabel.text = info;
    
    [super viewWillLayoutSubviews];
}

-(void) configureParallax
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL showParalax = ![defaults boolForKey: kPrefParalaxOff];

    if (showParalax) {
        UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xAxis.minimumRelativeValue = @(25.0);
        xAxis.maximumRelativeValue = @(-25.0);
        
        UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yAxis.minimumRelativeValue = @(32.0);
        yAxis.maximumRelativeValue = @(-32.0);
        
        self.backgroundMotionEffect = [[UIMotionEffectGroup alloc] init];
        self.backgroundMotionEffect.motionEffects = @[xAxis, yAxis];
        
        [self.sourceListView addMotionEffect:self.backgroundMotionEffect];
    }
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self.sourceListView setNeedsUpdateConstraints];
    [self.destinationView setNeedsUpdateConstraints];
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
}

- (IBAction)sourceDragLongGesture:(UILongPressGestureRecognizer *)sender {
    UIGestureRecognizerState gestureState = sender.state;
    BOOL reloadCell = NO;
    
    if (!self.draggingItem) {
        self.draggingItem = [MBDraggingItem newWithItem: nil size: self.destinationView.tileWidth];
        //        self.draggingRule = [[MBDraggingRule alloc] init];
        //        self.draggingRule.size = 30;
        self.draggingItem.touchToDragViewOffset = CGPointMake(0.0, -30.0);
    }
    
    
    CGPoint touchPoint = [sender locationInView: self.view];
    
    if (self.draggingItem.view) {
        self.draggingItem.viewCenter = touchPoint;
    }
    
    // Scroll to keep dragging in view
    if (self.autoScroll)
    {
        CGFloat scrollTouchInsets = -5.0;
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
        
        if (scrollTopLeft.y > 0.0) {
            CGRect scrollVisibleRect = CGRectMake(scrollTopLeft.x, scrollTopLeft.y, width, height);
//            NSString* scrollDescription = NSStringFromCGRect(scrollVisibleRect);
            // animation block because no animation scrolls too quickly on iPhone
            if (!self.isAnimatingScroll)
            {
                [UIView animateKeyframesWithDuration: 1.0
                                               delay: 0.0
                                             options: UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                                          animations:^{
                                              //
                                              [self.scrollView scrollRectToVisible: scrollVisibleRect animated: NO];
                                          } completion:^(BOOL finished) {
                                              //
                                          }];
            }
        }
    }
    
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderDragImage = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: self.draggingItem.viewCenter withEvent: nil];
    
    UIView<MBLSRuleDragAndDropProtocol>* ddViewContainer;
    if ([viewUnderDragImage isKindOfClass: [MDBLSObjectTileView class]]) {
        ddViewContainer = (UIView<MBLSRuleDragAndDropProtocol>*)viewUnderDragImage.superview;
    } else if ([[viewUnderDragImage subviews].firstObject isKindOfClass: [MDBLSObjectTileView class]]) {
        ddViewContainer = viewUnderDragImage;
    }
    
    if (self.draggingItem && [self handlesDragAndDrop: viewUnderTouch] && gestureState == UIGestureRecognizerStateBegan) {
        self.ruleHelpView.hidden = YES; // hide during dragging
        
        CGPoint localPoint = [self.view convertPoint: touchPoint toView: viewUnderTouch];
        [viewUnderTouch dragDidStartAtLocalPoint: localPoint draggingItem: self.draggingItem];
        if (self.draggingItem.view && self.draggingItem.dragItem) {
            [self showInfoForView: viewUnderTouch];
            self.draggingItem.view.userInteractionEnabled = NO;
            [self.view addSubview: self.draggingItem.view];
            [self.view bringSubviewToFront: self.draggingItem.view];
            self.lastDragViewContainer = (UIView<MBLSRuleDragAndDropProtocol>*)viewUnderTouch.superview;
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
            [self.lastDragViewContainer dragDidExitDraggingItem: self.draggingItem];
            
            self.lastDragViewContainer = nil;
        }
        
    } else if (self.draggingItem && gestureState == UIGestureRecognizerStateEnded) {
        [self cleanupAfterDrag];
        [self saveContext];
    } else if (self.draggingItem && gestureState == UIGestureRecognizerStateCancelled) {
        [self cleanupAfterDrag];
        
    } else if (self.draggingItem && gestureState == UIGestureRecognizerStateFailed) {
        [self cleanupAfterDrag];
    }
    
    if ([self.fractal hasChanges]) {
        [self saveContext];
    }
}
-(void)cleanupAfterDrag
{
    [self.draggingItem.view removeFromSuperview];
    LSDrawingRule* draggedRule = self.draggingItem.dragItem;
    [self deleteObjectIfUnreferenced: draggedRule];
    self.draggingItem = nil;
    self.lastDragViewContainer = nil;
    self.ruleHelpView.hidden = NO;
}
-(BOOL) handlesDragAndDrop: (id) anObject {
    return [anObject conformsToProtocol: @protocol(MBLSRuleDragAndDropProtocol)];
}

-(void) showInfoForView: (UIView*) aView {
    BOOL hasItem = [aView respondsToSelector: @selector(item)];
    if (hasItem) {
        id item = [aView valueForKey:@"item"];
        
        NSString* infoString;
        
        BOOL hasName = [item respondsToSelector: @selector(name)];
        BOOL hasDescriptorInfo = [item respondsToSelector: @selector(descriptor)];
        
        if (hasDescriptorInfo)
        {
            infoString = [item valueForKey: @"descriptor"];
        } else if (hasName)
        {
            infoString = [item valueForKey: @"name"];
        }
        
        if ([infoString isKindOfClass: [NSString class]] && infoString.length > 0) {
            self.ruleHelpLabel.text = infoString;
            [self infoAnimateView: aView];
        }
    }
    
}
-(void) infoAnimateView: (UIView*) aView {
    UIColor* oldColor = aView.backgroundColor;
    aView.backgroundColor = [FractalScapeIconSet selectionBackgrundColor];
    
    UIColor* oldHelpColor = self.ruleHelpLabel.superview.backgroundColor;
    self.ruleHelpLabel.superview.backgroundColor = [FractalScapeIconSet selectionBackgrundColor];
    
    [UIView animateWithDuration: 0.5 animations:^{
        //
        aView.backgroundColor = oldColor;
        self.ruleHelpLabel.superview.backgroundColor = oldHelpColor;
        
    } completion:^(BOOL finished) {
        //
    }];
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

-(void) deleteObjectIfUnreferenced: (id) object {

 }

@end
