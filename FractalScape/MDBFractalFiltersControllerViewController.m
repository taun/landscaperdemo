//
//  MDBFractalFiltersControllerViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 02/17/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalFiltersControllerViewController.h"
#import "MBLSFractalEditViewController.h"
#import "MDBImageFiltersCategoriesListView.h"
#import "MBImageFilter.h"


@interface MDBFractalFiltersControllerViewController ()

@property (nonatomic,strong) MBImageFilter          *tappedFilter;
@property (nonatomic,weak) NSTimer                  *removalTimer;

@end

@implementation MDBFractalFiltersControllerViewController

@dynamic visualEffectView;

-(void) updateFractalDependents
{
    [super updateFractalDependents];

    [self.destinationView setDefaultObjectClass: [MBImageFilter class]];
    self.destinationView.objectList = self.fractalDocument.fractal.imageFilters;
    self.destinationView.layer.name = @"imageFilters";
    
    [self.view setNeedsUpdateConstraints];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSArray* filterCategories = @[kCICategoryTileEffect,kCICategoryDistortionEffect,kCICategoryBlur];
    NSLocalizedString( @"CICategoryTileEffect", @"Core Image Filters");
    NSLocalizedString( @"CICategoryDistortionEffect", @"Core Image Filters");
    NSLocalizedString( @"CICategoryBlur", @"Core Image Filters");
    NSLocalizedString( @"CICategoryColorEffect", @"Core Image Filters");
    
    MDBImageFiltersCategoriesListView* categoriesView = (MDBImageFiltersCategoriesListView*) self.sourceListView;
    categoriesView.fractal = self.fractalDocument.fractal;
    categoriesView.filterCategories = filterCategories;
}


-(void)viewDidDisappear:(BOOL)animated
{
    [self removedTappedFilterFromObjectList: self.removalTimer];
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sourceTapGesture:(UIGestureRecognizer *)sender
{
    CGPoint touchPoint = [sender locationInView: self.view];
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
    [self showInfoForView: viewUnderTouch];
    MDBLSObjectTileView* tappedView = (MDBLSObjectTileView*)viewUnderTouch;
    
    if ([tappedView isKindOfClass: [MDBLSObjectTileView class]] && (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateBegan))
    {
        MBImageFilter* filter = (MBImageFilter*)tappedView.representedObject;
        [self qeueTappedFilter: filter];
     }
}

- (IBAction)filtersLongPress:(UILongPressGestureRecognizer *)sender
{
    [self sourceDragLongGesture: sender];
}

-(void)sourceDragLongGesture:(UIGestureRecognizer *)sender
{
//    [self removedTappedFilterFromObjectList: self.removalTimer];
    if (sender.state == UIGestureRecognizerStateChanged)
    {
        [self removedTappedFilterFromObjectList: self.removalTimer];
    }
    [super sourceDragLongGesture: sender];
}

-(void)qeueTappedFilter: (MBImageFilter*)filter
{
    [self removedTappedFilterFromObjectList: self.removalTimer];
    
    self.tappedFilter = filter;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.destinationView.objectList addObject: self.tappedFilter];
        NSTimer* removalTimer = [NSTimer timerWithTimeInterval: 2.0 target: self selector: @selector(removedTappedFilterFromObjectList:) userInfo: nil repeats: NO];
        [[NSRunLoop mainRunLoop]addTimer: removalTimer forMode: NSDefaultRunLoopMode];
        self.removalTimer = removalTimer;
    });
}

-(void)removedTappedFilterFromObjectList: (NSTimer*)timer
{
    if (timer && timer.valid) {
        [timer invalidate];
    }
    if (self.tappedFilter) {
        [self.destinationView.objectList removeObject: self.tappedFilter];
        self.tappedFilter = nil;
    }
}

@end
