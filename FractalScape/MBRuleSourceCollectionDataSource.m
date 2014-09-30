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
@property (nonatomic,strong) NSArray*   cachedOrderedRules;
@end


@implementation MBRuleSourceCollectionDataSource

-(void) setRules:(NSSet *)rules {
    if (_rules != rules) {
        _rules = rules;
        NSSortDescriptor* ruleIndexSorting = [NSSortDescriptor sortDescriptorWithKey: @"displayIndex" ascending: YES];
        NSSortDescriptor* ruleAlphaSorting = [NSSortDescriptor sortDescriptorWithKey: @"iconIdentifierString" ascending: YES];
        _cachedOrderedRules = [rules sortedArrayUsingDescriptors: @[ruleIndexSorting,ruleAlphaSorting]];
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
    
    LSDrawingRule* rule = (LSDrawingRule*)self.cachedOrderedRules[indexPath.row];
    NSString* iconImageMethod = [NSString stringWithFormat: @"imageOf%@",rule.iconIdentifierString];
    
    if ([FractalScapeIconSet respondsToSelector: NSSelectorFromString(iconImageMethod)]) {
        UIImage* cellImage = [FractalScapeIconSet performSelector: NSSelectorFromString(iconImageMethod)];
        newCell.imageView.image = cellImage;
    }
    return newCell;
}

-(UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
