//
//  MDBLSObjectTilesViewBaseController.m
//  
//
//  Created by Taun Chapman on 12/03/14.
//
//

#import "MDBLSObjectTilesViewBaseController.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configureParallax];
}
-(void) viewWillLayoutSubviews {
//    [self.sourceListView setNeedsUpdateConstraints];
    [self.sourceListView setNeedsLayout];
//    [self.destinationView setNeedsUpdateConstraints];
    [self.destinationView setNeedsLayout];
    [super viewWillLayoutSubviews];
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
        
        [self.sourceListView addMotionEffect:self.backgroundMotionEffect];
    }
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
    {
        CGFloat scrollTouchInsets = -15.0;
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
    if ([viewUnderDragImage isKindOfClass: [MDBLSObjectTileView class]]) {
        ddViewContainer = (UIView<MBLSRuleDragAndDropProtocol>*)viewUnderDragImage.superview;
    } else if ([[viewUnderDragImage subviews].firstObject isKindOfClass: [MDBLSObjectTileView class]]) {
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
        [self.draggingItem.view removeFromSuperview];
        LSDrawingRule* draggedRule = self.draggingItem.dragItem;
        [self deleteObjectIfUnreferenced: draggedRule];
        self.draggingItem = nil;
        self.lastDragViewContainer = nil;
        
    } else if (self.draggingItem && gestureState == UIGestureRecognizerStateCancelled) {
        [self.draggingItem.view removeFromSuperview];
        LSDrawingRule* draggedRule = self.draggingItem.dragItem;
        [self deleteObjectIfUnreferenced: draggedRule];
        self.draggingItem = nil;
        self.lastDragViewContainer = nil;
        
    } else if (self.draggingItem && gestureState == UIGestureRecognizerStateFailed) {
        [self.draggingItem.view removeFromSuperview];
        LSDrawingRule* draggedRule = self.draggingItem.dragItem;
        [self deleteObjectIfUnreferenced: draggedRule];
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
-(void) showInfoForView: (UIView*) aView {
    
}
-(void) infoAnimateView: (UIView*) aView {
    
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
