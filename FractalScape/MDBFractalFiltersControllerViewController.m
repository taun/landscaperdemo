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
@property (nonatomic,weak) NSTimer                  *removalTImer;

@end

@implementation MDBFractalFiltersControllerViewController

-(void) updateFractalDependents
{
    [self.destinationView setDefaultObjectClass: [MBImageFilter class]];
    self.destinationView.objectList = self.fractalDocument.fractal.imageFilters;
    self.destinationView.layer.name = @"imageFilters";
    
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.view.translatesAutoresizingMaskIntoConstraints = NO;
//    _filterPicker.translatesAutoresizingMaskIntoConstraints = NO;
//    _filters = [CIFilter filterNamesInCategory: kCICategoryTileEffect];
//    NSMutableArray* tempArray = [NSMutableArray new];
//    [tempArray addObjectsFromArray: [CIFilter filterNamesInCategory: kCICategoryTileEffect]];
//    [tempArray addObjectsFromArray: [CIFilter filterNamesInCategory: kCICategoryColorEffect]];
//    [tempArray addObjectsFromArray: [CIFilter filterNamesInCategory: kCICategoryDistortionEffect]];
//    [tempArray addObjectsFromArray: [CIFilter filterNamesInCategory: kCICategoryBlur]];
//    _filters = [tempArray copy];

    CGFloat effectHeight = self.visualEffectView.bounds.size.height;
    self.scrollView.contentInset = UIEdgeInsetsMake(effectHeight, 0, 44, 0);
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(effectHeight, 0, 44, 0);;

    NSArray* filterCategories = @[kCICategoryTileEffect,kCICategoryDistortionEffect,kCICategoryBlur,kCICategoryColorEffect];
    MDBImageFiltersCategoriesListView* categoriesView = (MDBImageFiltersCategoriesListView*) self.sourceListView;
    categoriesView.filterCategories = filterCategories;
}

-(void) viewWillLayoutSubviews
{
    [self.visualEffectView setNeedsLayout];
    
    [super viewWillLayoutSubviews];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self removedTappedFilterFromObjectList: self.removalTImer];
    [super viewDidDisappear:animated];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self.view setNeedsLayout];
    [self.visualEffectView setNeedsLayout];
    [self updateViewConstraints];
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
}

-(void) updateViewConstraints
{
    [super updateViewConstraints];
    
    [self.visualEffectView layoutIfNeeded];
    
    [self.sourceListView setNeedsLayout];
    [self.sourceListView layoutIfNeeded];
 
    CGFloat effectHeight = self.visualEffectView.bounds.size.height + 20.0;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(effectHeight, 0, 44, 0);
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(effectHeight, 0, 44, 0);;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)filterSourceTapGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView: self.view];
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
    [self showInfoForView: viewUnderTouch];
    MDBLSObjectTileView* tappedView = (MDBLSObjectTileView*)viewUnderTouch;
    
    if ([tappedView isKindOfClass: [MDBLSObjectTileView class]])
    {
        MBImageFilter* filter = (MBImageFilter*)tappedView.representedObject;
        [self qeueTappedFilter: filter];
     }
}

- (IBAction)filtersLongPress:(UILongPressGestureRecognizer *)sender
{
    [self sourceDragLongGesture: sender];
}

-(void)sourceDragLongGesture:(UILongPressGestureRecognizer *)sender
{
    [self removedTappedFilterFromObjectList: self.removalTImer];
    
    [super sourceDragLongGesture: sender];
}

-(void)qeueTappedFilter: (MBImageFilter*)filter
{
    [self removedTappedFilterFromObjectList: self.removalTImer];
    
    self.tappedFilter = filter;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.destinationView.objectList addObject: self.tappedFilter];
        NSTimer* removalTimer = [NSTimer timerWithTimeInterval: 3.0 target: self selector: @selector(removedTappedFilterFromObjectList:) userInfo: nil repeats: NO];
        [[NSRunLoop mainRunLoop]addTimer: removalTimer forMode: NSDefaultRunLoopMode];
        self.removalTImer = removalTimer;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//#pragma mark - UIPickerSource
//-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
//{
//    return 1;
//}
//-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
//{
//#if TARGET_INTERFACE_BUILDER
//    return 2;
//#else
//    return self.filters.count;
//#endif
//}
//
//#pragma mark - UIPickerDelegate
//-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
//{
//    return 24.0;
//}
//-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
//{
//    CGFloat width = self.filterPicker.bounds.size.width;
//    return width*(120.0/130.0);
//}
//-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    return self.filters[row];
//}
//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
//{
//    UILabel* tView = (UILabel*)view;
//    if (!tView)
//    {
//        tView = [[UILabel alloc] init];
//        [tView setFont:[UIFont systemFontOfSize: 18]];
//        //[tView setTextAlignment:UITextAlignmentLeft];
//        tView.numberOfLines=1;
//    }
//    // Fill the label text here
//    tView.text = self.filters[row];
//    return tView;
//}
//-(void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
//    [self.view becomeFirstResponder];
//    MBLSFractalEditViewController* editor = (MBLSFractalEditViewController*)self.fractalControllerDelegate;
//    
//    CIFilter *filter = [CIFilter filterWithName: self.filters[row]];
//
//    [editor applyFilter: filter];
//}

@end
