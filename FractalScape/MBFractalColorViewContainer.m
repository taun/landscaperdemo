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
-(void)setFractal:(LSFractal *)fractal {
    _fractal = fractal;
    self.colorsChanged = YES;
    [self.fractalDestinationCollection reloadData];
}
-(NSArray*)cachedFractalColors {
    if (_fractal && (!_cachedFractalColors || self.colorsChanged)) {
        NSSet* colors = [self.fractal valueForKey: self.fractalPropertyKeypath];
        NSSortDescriptor* indexSort = [NSSortDescriptor sortDescriptorWithKey: @"index" ascending: YES];
        _cachedFractalColors = [colors sortedArrayUsingDescriptors: @[indexSort]];
    }
    return _cachedFractalColors;
}

-(void)viewWillLayoutSubviews {
    UIView* containerView = self.colorCollectionContainer;
    UIView* collectionViewWrapper = [containerView.subviews firstObject];
    UIView* collectionView = [collectionViewWrapper.subviews firstObject];
    
    NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:collectionView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:collectionViewWrapper
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1.0
                                                                        constant:0.0
                                           ];
    
    NSLayoutConstraint* heightConstraint1 = [NSLayoutConstraint constraintWithItem:collectionView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:collectionViewWrapper
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:50.0
                                             ];
    NSLayoutConstraint* heightConstraint2 = [NSLayoutConstraint constraintWithItem:collectionView
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:collectionViewWrapper
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0
                                                                          constant:0.0
                                             ];
    [collectionViewWrapper addConstraints:@[widthConstraint,heightConstraint1,heightConstraint2]];
    [collectionView setTranslatesAutoresizingMaskIntoConstraints: NO];
    
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.cachedFractalColors.count;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ColorSwatchCell";
    
    MBCollectionColorCell *cell = (MBCollectionColorCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    //    }
    UIImageView* strongCellImageView = cell.imageView;
    
    MBColor* managedObjectColor = self.cachedFractalColors[indexPath.row];
    
    strongCellImageView.image = [managedObjectColor thumbnailImageSize: cell.bounds.size];
    strongCellImageView.highlightedImage = strongCellImageView.image;
    
    //    MBColor* currentColor = [self.fractal valueForKey: [[self class] fractalPropertyKeypath]];
    //    if (currentColor == managedObject) {
    //        cell.selected = YES;
    //    }
    
    return cell;
}
@end
