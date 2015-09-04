//
//  MBFractalColorViewContainer.m
//  FractalScape
//
//  Created by Taun Chapman on 11/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBFractalColorViewContainer.h"
#import "MBColor.h"
#import "MDBPurchaseManager.h"

#import "QuartzHelpers.h"

@interface MBFractalColorViewContainer ()
@property (nonatomic,strong) NSArray*               categories;
@property (nonatomic,assign) BOOL                   colorsChanged;
@end

@implementation MBFractalColorViewContainer

-(void) updateFractalDependents
{
    [super updateFractalDependents];

    self.categories = self.appModel.sourceColorCategories;
    
    MDBColorCategoriesListView* categoriesView = (MDBColorCategoriesListView*) self.sourceListView;
    categoriesView.colorCategories = self.categories;
    
    [self.destinationView setDefaultObjectClass: [MBColor class]];
    self.destinationView.objectList = self.fractalDocument.fractal.lineColors;
    self.destinationView.layer.name = @"lineColors";

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
    self.allowedDestinationViews = [@[self.fillColorsListView,self.pageColorDestinationTileView] arrayByAddingObjectsFromArray: self.allowedDestinationViews];
    [super viewWillLayoutSubviews];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.getExtraColorsView.hidden = !self.appModel.purchaseManager.isColorPakAvailable;
}

- (IBAction)lineColorLongPress:(UILongPressGestureRecognizer *)sender
{
    [self sourceDragLongGesture: sender];
}
- (IBAction)fillColorLongPress:(UILongPressGestureRecognizer *)sender
{
    [self sourceDragLongGesture: sender];
}

- (IBAction)sourceTapGesture:(UITapGestureRecognizer *)sender {
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
