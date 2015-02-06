//
//  MBFractalColorViewContainer.m
//  FractalScape
//
//  Created by Taun Chapman on 11/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBFractalColorViewContainer.h"
#import "MBColor+addons.h"

#import "QuartzHelpers.h"

@interface MBFractalColorViewContainer ()
@property (nonatomic,strong) NSArray*               categories;
@property (nonatomic,assign) BOOL                   colorsChanged;
@property (nonatomic,strong) NSLayoutConstraint*    sourceHeightOffset;
@end

@implementation MBFractalColorViewContainer

-(NSLayoutConstraint*) sourceHeightOffset {
    if (!_sourceHeightOffset) {
        UIView* superview = [(UIView*)self.sourceListView superview];
        _sourceHeightOffset = [NSLayoutConstraint constraintWithItem: self.sourceListView
                                                           attribute: NSLayoutAttributeTop
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: superview
                                                           attribute: NSLayoutAttributeTop
                                                          multiplier: 1.0 constant: 100.0];
        [superview addConstraint: _sourceHeightOffset];
    }
    return _sourceHeightOffset;
}
-(void)viewDidLoad {
    // seems to be a bug in that the tintColor is not being used unless I re-set it.
    // this way it still takes the tintColor from IB.
    _lineColorsTemplateImageView.tintColor = _lineColorsTemplateImageView.tintColor;
    _fillColorsTemplateImageView.tintColor = _fillColorsTemplateImageView.tintColor;
    
    [super viewDidLoad];
}
#pragma message "TODO: handle scrollView contentInset's"
-(void) viewWillLayoutSubviews {
//    [self.fillColorsListView setNeedsLayout];
//    [self.pageColorDestinationTileView setNeedsLayout];
//    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];
//    [self.visualEffectView setNeedsUpdateConstraints];
    [self.visualEffectView setNeedsLayout];
    
    [super viewWillLayoutSubviews];
}
-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];
//    [self.visualEffectView setNeedsUpdateConstraints];
    [self.visualEffectView setNeedsLayout];
    [self updateViewConstraints];
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
}
-(void) updateViewConstraints {
    [super updateViewConstraints];
    [self.visualEffectView layoutIfNeeded];
    CGFloat effectHeight = self.visualEffectView.bounds.size.height;
    self.sourceHeightOffset.constant = effectHeight;
    [self.sourceListView setNeedsLayout];
    [self.sourceListView layoutIfNeeded];
}
-(void) updateFractalDependents {
    _categories = [MBColorCategory allCatetegoriesInContext: self.fractal.managedObjectContext];
    
    MDBColorCategoriesListView* categoriesView = (MDBColorCategoriesListView*) self.sourceListView;
    categoriesView.colorCategories = _categories;
    
    [self.destinationView setDefaultObjectClass: [MBColor class] inContext: self.fractal.managedObjectContext];
    [self.fillColorsListView setDefaultObjectClass: [MBColor class] inContext: self.fractal.managedObjectContext];
    
    self.destinationView.objectList = [self.fractal mutableOrderedSetValueForKey: [LSFractal lineColorsKey]];
    self.fillColorsListView.objectList = [self.fractal mutableOrderedSetValueForKey: [LSFractal fillColorsKey]];
    
    self.pageColorDestinationTileView.fractal = self.fractal;
    
    self.colorsChanged = YES;

    [self.view setNeedsUpdateConstraints];
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

- (IBAction)lineColorLongPress:(UILongPressGestureRecognizer *)sender {
    [self sourceDragLongGesture: sender];
}
- (IBAction)fillColorLongPress:(UILongPressGestureRecognizer *)sender {
    [self sourceDragLongGesture: sender];
}

- (IBAction)dismissModal:(id)sender
{
    [self dismissViewControllerAnimated: YES completion:^{
        //
    }];
}

-(void) deleteObjectIfUnreferenced: (MBColor*) color {
    if (color != nil && !color.isReferenced) {
        if ([color isKindOfClass: [NSManagedObject class]]) {
            [((NSManagedObject*)color).managedObjectContext deleteObject: color];
        }
    }
}

@end
