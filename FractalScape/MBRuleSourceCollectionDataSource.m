//
//  MBRuleSourceCollectionDataSource.m
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBRuleSourceCollectionDataSource.h"
#import "MBLSRuleCollectionViewCell.h"

@implementation MBRuleSourceCollectionDataSource

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1;
}

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MBLSRuleCollectionViewCell* newCell = [collectionView dequeueReusableCellWithReuseIdentifier: @"MBLSRuleCollectionCell" forIndexPath: indexPath];
    UIImage* cellImage = [UIImage imageNamed: @"kBIconRuleDrawLine.png"];
    newCell.imageView.image = cellImage;
    return newCell;
}

-(UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
