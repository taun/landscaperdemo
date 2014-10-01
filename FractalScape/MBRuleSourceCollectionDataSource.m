//
//  MBRuleSourceCollectionDataSource.m
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBRuleSourceCollectionDataSource.h"
#import "MBLSRuleCollectionViewCell.h"
#import "LSDrawingRule+addons.h"

#import "FractalScapeIconSet.h"

@interface MBRuleSourceCollectionDataSource ()
@end


@implementation MBRuleSourceCollectionDataSource

-(void) setRules:(NSArray *)rules {
    if (_rules != rules) {
        _rules = rules;
    }
}

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.rules.count;
}

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MBLSRuleCollectionViewCell* newCell = [collectionView dequeueReusableCellWithReuseIdentifier: @"MBLSRuleCollectionCell" forIndexPath: indexPath];
    
    LSDrawingRule* rule = (LSDrawingRule*)self.rules[indexPath.row];
    UIImage* cellImage = [UIImage imageNamed: rule.iconIdentifierString];
    
    CGFloat cellWidth = newCell.bounds.size.width;
    
    newCell.imageView.image = cellImage;
    
    if (cellWidth < 35) {
        newCell.imageView.contentScaleFactor = 4.0;
    }
    
    return newCell;
}

-(UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
