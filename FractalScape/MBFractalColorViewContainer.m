//
//  MBFractalColorViewContainer.m
//  FractalScape
//
//  Created by Taun Chapman on 11/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBFractalColorViewContainer.h"
#import "MBLSRuleBaseCollectionViewCell.h"
#import "MBColor+addons.h"

#import "QuartzHelpers.h"

@interface MBFractalColorViewContainer ()
@property (nonatomic,strong) NSArray*   categories;
@property (nonatomic,assign) BOOL       colorsChanged;
@end

@implementation MBFractalColorViewContainer

-(void)viewDidLoad {
    // seems to be a bug in that the tintColor is not being used unless I re-set it.
    // this way it still takes the tintColor from IB.
    _lineColorsTemplateImageView.tintColor = _lineColorsTemplateImageView.tintColor;
    _fillColorsTemplateImageView.tintColor = _fillColorsTemplateImageView.tintColor;
    _pageColorTemplateImage.tintColor = _pageColorTemplateImage.tintColor;
    
    [super viewDidLoad];
}

-(void) updateFractalDependents {
    _categories = [MBColorCategory allCatetegoriesInContext: self.fractal.managedObjectContext];
    
    MDBColorCategoriesListView* categoriesView = (MDBColorCategoriesListView*) self.sourceListView;
    categoriesView.colorCategories = _categories;
    
    [self.destinationView setDefaultObjectClass: [MBColor class] inContext: self.fractal.managedObjectContext];
    [self.fillColorsListView setDefaultObjectClass: [MBColor class] inContext: self.fractal.managedObjectContext];
    
    self.destinationView.objectList = [self.fractal mutableOrderedSetValueForKey: [LSFractal lineColorsKey]];
    self.fillColorsListView.objectList = [self.fractal mutableOrderedSetValueForKey: [LSFractal fillColorsKey]];
    
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

-(void) deleteObjectIfUnreferenced: (MBColor*) color {
    if (color != nil && !color.isReferenced) {
        [color.managedObjectContext deleteObject: color];
    }
}

@end
