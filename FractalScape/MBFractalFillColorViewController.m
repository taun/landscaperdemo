//
//  MBFractalFillColorViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/05/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalFillColorViewController.h"

@interface MBFractalFillColorViewController ()

@end

@implementation MBFractalFillColorViewController

+(NSString*) fractalPropertyKeypath {
    return @"fillColors";
}

#pragma mark - UICollectionViewDelegate
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [super collectionView: collectionView didSelectItemAtIndexPath: indexPath];
    
//    if (![self.fractal.fill boolValue]) {
//        self.fractal.fill = @(YES);
//    }
}


@end
