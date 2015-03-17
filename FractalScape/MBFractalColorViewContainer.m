//
//  MBFractalColorViewContainer.m
//  FractalScape
//
//  Created by Taun Chapman on 11/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBFractalColorViewContainer.h"
#import "MBColor.h"

#import "QuartzHelpers.h"

@interface MBFractalColorViewContainer ()
@property (nonatomic,strong) NSArray*               categories;
@property (nonatomic,assign) BOOL                   colorsChanged;
@end

@implementation MBFractalColorViewContainer

-(void) updateFractalDependents
{
    self.categories = self.fractalDocument.sourceColorCategories;
    
    MDBColorCategoriesListView* categoriesView = (MDBColorCategoriesListView*) self.sourceListView;
    categoriesView.colorCategories = self.categories;
    
    [self.destinationView setDefaultObjectClass: [MBColor class]];
    self.destinationView.objectList = self.fractalDocument.fractal.lineColors;

    [self.fillColorsListView setDefaultObjectClass: [MBColor class]];
    self.fillColorsListView.objectList = self.fractalDocument.fractal.fillColors;
    
    self.pageColorDestinationTileView.fractalDocument = self.fractalDocument;
    
    self.colorsChanged = YES;

    [self.view setNeedsUpdateConstraints];
}

-(void)viewDidLoad
{
    // seems to be a bug in that the tintColor is not being used unless I re-set it.
    // this way it still takes the tintColor from IB.
    _lineColorsTemplateImageView.tintColor = _lineColorsTemplateImageView.tintColor;
    _fillColorsTemplateImageView.tintColor = _fillColorsTemplateImageView.tintColor;
    
    [super viewDidLoad];
}

-(void) viewWillLayoutSubviews
{
    [self.fillColorsListView setNeedsLayout];
    [self.view setNeedsLayout];
    [self.visualEffectView setNeedsLayout];
    
    [super viewWillLayoutSubviews];
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
    CGFloat effectHeight = self.visualEffectView.bounds.size.height;
    
    [self.sourceListView setNeedsLayout];
    [self.sourceListView layoutIfNeeded];
    
    self.scrollView.contentInset = UIEdgeInsetsMake(effectHeight, 0, 44, 0);
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(effectHeight, 0, 44, 0);;
}

//-(void) addNewColorForRow: (NSUInteger) row {
//    NSInteger newIndex = [self.cachedFractalColors[row] count];
//    MBColor* newColor = (MBColor*)self.draggingItem.dragItem;
//    newColor.index = @(newIndex);
//    
//    [self.mutableColorSets[row] addObject: newColor];
//
//    self.colorsChanged = YES;
//}

- (IBAction)lineColorLongPress:(UILongPressGestureRecognizer *)sender
{
    [self sourceDragLongGesture: sender];
}
- (IBAction)fillColorLongPress:(UILongPressGestureRecognizer *)sender
{
    [self sourceDragLongGesture: sender];
}

- (IBAction)colorSourceTapGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView: self.view];
    UIView<MBLSRuleDragAndDropProtocol>* viewUnderTouch = (UIView<MBLSRuleDragAndDropProtocol>*)[self.view hitTest: touchPoint withEvent: nil];
    [self showInfoForView: viewUnderTouch];
}

- (IBAction)pageColorTapGesture:(UITapGestureRecognizer *)sender {
    NSString* infoString = @"Page background color. Default is clear.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.pageColorDestinationTileView];
}

- (IBAction)lineColorTapGesture:(UITapGestureRecognizer *)sender {
    NSString* infoString = @"Line colors.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.destinationView];
}

- (IBAction)fillColorTapGesture:(UITapGestureRecognizer *)sender {
    NSString* infoString = @"Fill colors.";
    self.ruleHelpLabel.text = infoString;
    [self infoAnimateView: self.fillColorsListView];
}


@end
