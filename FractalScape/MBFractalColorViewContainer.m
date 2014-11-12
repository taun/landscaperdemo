//
//  MBFractalColorViewContainer.m
//  FractalScape
//
//  Created by Taun Chapman on 11/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBFractalColorViewContainer.h"
#import "MBCollectionColorCell.h"
#import "MBColor+addons.h"

@implementation MBFractalColorViewContainer

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _colorsChanged = YES;
    }
    return self;
}
-(void)awakeFromNib {
    [super awakeFromNib];
    _colorsChanged = YES;
}
-(void)viewDidLoad {
    // seems to be a bug in that the tintColor is not being used unless I re-set it.
    // this way it still takes the tintColor from IB.
    _lineColorsTemplateImageView.tintColor = _lineColorsTemplateImageView.tintColor;
    _fillColorsTemplateImageView.tintColor = _fillColorsTemplateImageView.tintColor;
    [super viewDidLoad];
}
-(void)setFractal:(LSFractal *)fractal {
    _fractal = fractal;
    self.colorsChanged = YES;
    [self.fractalLineColorsDestinationCollection reloadData];
    [self.fractalFillColorsDestinationCollection reloadData];

}
-(NSArray*)cachedFractalColors {
    if (_fractal && (!_cachedFractalColors || self.colorsChanged)) {
        NSSortDescriptor* indexSort = [NSSortDescriptor sortDescriptorWithKey: @"index" ascending: YES];

        NSSet* lineColors = [self.fractal valueForKey: @"lineColors"];
        NSArray* cachedFractalLineColors = [lineColors sortedArrayUsingDescriptors: @[indexSort]];

        NSSet* fillColors = [self.fractal valueForKey: @"fillColors"];
        NSArray* cachedFractalFillColors = [fillColors sortedArrayUsingDescriptors: @[indexSort]];
        
        _cachedFractalColors = @[cachedFractalLineColors,cachedFractalFillColors];
    }
    return _cachedFractalColors;
}

-(void)viewWillLayoutSubviews {
    UIView* containerView = self.colorCollectionContainer;
    UIView* collectionViewWrapper = [containerView.subviews firstObject];
    UIView* collectionView = [collectionViewWrapper.subviews firstObject];
    
    NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:collectionView
                                                                       attribute:NSLayoutAttributeLeft
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:collectionViewWrapper
                                                                       attribute:NSLayoutAttributeLeft
                                                                      multiplier:1.0
                                                                        constant:0.0
                                           ];
    NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:collectionView
                                                                       attribute:NSLayoutAttributeRight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:collectionViewWrapper
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1.0
                                                                        constant:0.0
                                           ];
    
    NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:collectionView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:collectionViewWrapper
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:116.0
                                             ];
    NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:collectionView
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:collectionViewWrapper
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0
                                                                          constant:0.0
                                             ];
    [collectionViewWrapper addConstraints:@[leftConstraint,rightConstraint,topConstraint,bottomConstraint]];
    [collectionView setTranslatesAutoresizingMaskIntoConstraints: NO];
    
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (collectionView == self.fractalLineColorsDestinationCollection) {
        section = 0;
    } else {
        section = 1;
    }
    
    return [self.cachedFractalColors[section] count] + 1;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section;
    
    if (collectionView == self.fractalLineColorsDestinationCollection) {
        section = 0;
    } else {
        section = 1;
    }
    
    static NSString *CellIdentifier = @"ColorSwatchCell";
    MBCollectionColorCell *cell = (MBCollectionColorCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    

    UIImageView* strongCellImageView = cell.imageView;
    
    if (indexPath.row < [self.cachedFractalColors[section] count]) {
        // we have a color
        MBColor* managedObjectColor = self.cachedFractalColors[section][indexPath.row];
        strongCellImageView.image = [managedObjectColor thumbnailImageSize: cell.bounds.size];
    } else {
        // use a placeholder
        UIImage* placeholder = [UIImage imageNamed: @"kBIconRulePlaceEmpty"];
        strongCellImageView.image = placeholder;
    }
    
    strongCellImageView.highlightedImage = strongCellImageView.image;
    
    
    return cell;
}
@end
