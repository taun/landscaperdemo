//
//  MDBLSObjectTilesViewBaseController.m
//  
//
//  Created by Taun Chapman on 12/03/14.
//
//

#import "MDBLSObjectTilesViewBaseController.h"
#import "MDBAppModel.h"


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

-(void) setFractalDocument:(MDBFractalDocument *)fractalDocument {
    _fractalDocument = fractalDocument;
    if (self.view) {
        [self updateFractalDependents];
    }
}

-(void) updateFractalDependents
{
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
//    UITraitCollection* traits = self.traitCollection;
//    NSLog(@"Trait collection: %@", traits);
}
/*!
 It appears, sometimes the tabView has loaded the childViewController's view before setting the fractal and sometimes after.
 By ensuring the fractalDependents are updated after viewDidLoad, it doesn't matter which happens first.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.fractalDocument.fractal)
    {
//        [self updateFractalDependents];
    }
    [self configureParallax];
}

-(void) viewWillLayoutSubviews
{
    @autoreleasepool
    {
        id strongSourceListView = self.sourceListView;
        id strongDestinationView = self.destinationView;
        self.allowedDestinationViews = [@[strongDestinationView] arrayByAddingObjectsFromArray: self.allowedDestinationViews];
        
        for (UIView*destination in self.allowedDestinationViews)
        {
            [destination setNeedsLayout];
        }
        //    [self.sourceListView setNeedsUpdateConstraints];
        [strongSourceListView setNeedsLayout];
        //    [self.destinationView setNeedsUpdateConstraints];
        //    [strongDestinationView setNeedsLayout];
        
        // Hack to get the label to adjust size after the transition.
        NSString* info = self.ruleHelpLabel.text;
        self.ruleHelpLabel.text = info;
//        self.ruleHelpLabel.highlighted = NO;
        
        
        [self updateViewConstraints];
        [self.view setNeedsLayout];
    }

    [super viewWillLayoutSubviews];
}

//-(void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    
//}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.appModel.showHelpTips)
    {
//        NSString* info = self.ruleHelpLabel.text;
//        self.ruleHelpLabel.text = info;
//        self.ruleHelpLabel.highlighted = NO;
    } else
    {
        self.ruleHelpView.hidden = YES;
    }
}
-(void) configureParallax
{
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    BOOL showParalax = [defaults boolForKey: kPrefParalax];

    if ((NO)) {
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

-(void) updateViewConstraints
{
    [super updateViewConstraints];
    
    [self.sourceListView setNeedsLayout];
    [self.sourceListView layoutIfNeeded];
    
    if (self.visualEffectView) [self adjustScrollviewInsetForDestinationViewOverlay];
}

-(void)adjustScrollviewInsetForDestinationViewOverlay
{
    [self.visualEffectView layoutIfNeeded];
    CGFloat effectHeight = self.visualEffectView.bounds.size.height;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(effectHeight, 0, 0, 0);
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(effectHeight, 0, 0, 0);
}


-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
//    id strongSourceListView = self.sourceListView;
    
    for (UIView* destination in self.allowedDestinationViews)
    {
        [destination setNeedsUpdateConstraints];
        [destination setNeedsUpdateConstraints];
    }

    [self.view setNeedsLayout];
    [self.visualEffectView setNeedsLayout];
    [self updateViewConstraints];
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
}

- (void)sourceTapGesture:(UIGestureRecognizer *)sender
{
    
}

- (IBAction)sourceDragLongGesture:(UILongPressGestureRecognizer *)sender
{
    UIGestureRecognizerState gestureState = sender.state;

    if (gestureState == UIGestureRecognizerStateBegan)
    {
        [self sourceTapGesture: sender];
    }

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
        CGFloat scrollTouchInsets = -10.0; // start scrolling when this close to the edge
        CGRect dropImageRect = CGRectInset(self.draggingItem.view.frame, scrollTouchInsets, scrollTouchInsets);
        CGRect touchRect = CGRectInset(CGRectMake(touchPoint.x, touchPoint.y, 1, 1), scrollTouchInsets*2, scrollTouchInsets*2);
        CGRect visibleRect = CGRectUnion(dropImageRect, touchRect);
        CGFloat minX = CGRectGetMinX(visibleRect);
        CGFloat maxX = CGRectGetMaxX(visibleRect);
        CGFloat minY = CGRectGetMinY(visibleRect);
        CGFloat maxY = CGRectGetMaxY(visibleRect);
        
        CGFloat scrollStepSize = 4.0;
        
        CGFloat scrollTouchTop = [self.view convertPoint: CGPointMake(minX, minY) toView: self.scrollView].y;
        CGFloat scrollTouchBottom = [self.view convertPoint: CGPointMake(maxX, maxY) toView: self.scrollView].y;

        CGFloat currentScrollViewOffsetY = self.scrollView.contentOffset.y;
        CGFloat maxScrollViewContentOffsetY = self.scrollView.contentSize.height - self.scrollView.bounds.size.height - scrollStepSize;
        // does not account for scroll zooming.
//        CGFloat width = maxX - minX;
//        CGFloat height = maxY - minY;
        CGFloat newOffsetStep = 0;
        
        if (scrollTouchTop < currentScrollViewOffsetY && currentScrollViewOffsetY > scrollStepSize)
        {
            newOffsetStep = -scrollStepSize;
        }
        else if (scrollTouchBottom > (currentScrollViewOffsetY + self.scrollView.bounds.size.height) && currentScrollViewOffsetY < maxScrollViewContentOffsetY)
        {
            newOffsetStep = scrollStepSize;
        }
        
        if (newOffsetStep) // don't scroll if already at top or bottom of view
        {
            // animation block because no animation scrolls too quickly on iPhone
            if ((YES))
            {
                
                [UIView animateWithDuration: 1.0
                                      delay: 0.0
                     usingSpringWithDamping: 1.0
                      initialSpringVelocity: 0.0
                                    options: UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                                 animations: ^{
                                     //
                                     self.scrollView.contentOffset = CGPointMake(0, currentScrollViewOffsetY+newOffsetStep);
                                 }
                                 completion:^(BOOL finished) {
                                     //
                                 }];
                
            }
        }
    }
    
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderDragImage = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: self.draggingItem.viewCenter withEvent: nil];
    
    UIView<MBLSRuleDragAndDropProtocol>* ddViewContainer;
    if ([viewUnderDragImage isKindOfClass: [MDBLSObjectTileView class]])
    {
        ddViewContainer = (UIView<MBLSRuleDragAndDropProtocol>*)viewUnderDragImage.superview;
    }
    else if ([[viewUnderDragImage subviews].firstObject isKindOfClass: [MDBLSObjectTileView class]])
    {
        ddViewContainer = viewUnderDragImage;
    }
    
    if (self.draggingItem && [self handlesDragAndDrop: viewUnderTouch] && gestureState == UIGestureRecognizerStateBegan)
    {
        for (MBLSObjectListTileViewer*destination in self.allowedDestinationViews)
        {
            [destination startBlinkOutline]; // needs to be a protocol
        }

        self.ruleHelpView.hidden = YES; // hide during dragging if not already hidden
        
        CGPoint localPoint = [self.view convertPoint: touchPoint toView: viewUnderTouch];
        [viewUnderTouch dragDidStartAtLocalPoint: localPoint draggingItem: self.draggingItem];
        if (self.draggingItem.view && self.draggingItem.dragItem) {
            [self showInfoForView: viewUnderTouch];
            self.draggingItem.view.userInteractionEnabled = NO;
            [self.view addSubview: self.draggingItem.view];
            [self.view bringSubviewToFront: self.draggingItem.view];
            self.lastDragViewContainer = (UIView<MBLSRuleDragAndDropProtocol>*)viewUnderTouch.superview;
        }
        
    }
    else if (self.draggingItem && gestureState == UIGestureRecognizerStateChanged)
    {
        
        CGPoint localPoint = [self.view convertPoint: self.draggingItem.viewCenter toView: ddViewContainer];
        
        if (self.lastDragViewContainer == nil && ddViewContainer != nil && [self handlesDragAndDrop: ddViewContainer])
        {
            // entering
            [ddViewContainer dragDidEnterAtLocalPoint: localPoint draggingItem: self.draggingItem];
            self.lastDragViewContainer = ddViewContainer;
            
        }
        else if (self.lastDragViewContainer != nil && ddViewContainer != nil && self.lastDragViewContainer == ddViewContainer)
        {
            // changing
            [ddViewContainer dragDidChangeToLocalPoint: localPoint draggingItem: self.draggingItem];
            
        }
        else if (self.lastDragViewContainer != nil && (ddViewContainer == nil || self.lastDragViewContainer != ddViewContainer))
        {
            // leaving
            [self.lastDragViewContainer dragDidExitDraggingItem: self.draggingItem];
            
            self.lastDragViewContainer = nil;
        }
        
    }
    else if (self.draggingItem && gestureState == UIGestureRecognizerStateEnded)
    {
        [self cleanupAfterDrag];
        [self.fractalDocument updateChangeCount: UIDocumentChangeDone];
    }
    else if (self.draggingItem && gestureState == UIGestureRecognizerStateCancelled)
    {
        [self cleanupAfterDrag];
        
    }
    else if (self.draggingItem && gestureState == UIGestureRecognizerStateFailed)
    {
        [self cleanupAfterDrag];
    }
    
//    if ([self.fractalDocument.fractal hasChanges]) {
//        [self saveContext];
//    }
}
-(void)cleanupAfterDrag
{
    for (MBLSObjectListTileViewer*destination in self.allowedDestinationViews)
    {
        [destination endBlinkOutline]; // needs to be a protocol
    }

    [self.draggingItem.view removeFromSuperview];
    id<MDBTileObjectProtocol> draggedRule = self.draggingItem.dragItem;
    [self deleteObjectIfUnreferenced: draggedRule]; // check if unreferenced and add POOF effect
    self.draggingItem = nil;
    self.lastDragViewContainer = nil;
    if (self.appModel.showHelpTips)
    {
        self.ruleHelpView.hidden = NO;
    }
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
    aView.backgroundColor = [FractalScapeIconSet selectionBackgroundColor];
    
    UIColor* oldHelpColor = self.ruleHelpLabel.superview.backgroundColor;
    self.ruleHelpLabel.superview.backgroundColor = [FractalScapeIconSet selectionBackgroundColor];
    
    [UIView animateWithDuration: 0.5 animations:^{
        //
        aView.backgroundColor = oldColor;
        self.ruleHelpLabel.superview.backgroundColor = oldHelpColor;
        
    } completion:^(BOOL finished) {
        //
    }];
}

-(void) deleteObjectIfUnreferenced: (id) object {

 }

@end
