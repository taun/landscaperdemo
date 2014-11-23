//
//  MBRuleCollectionDataSource.m
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBRuleCollectionDataSource.h"
#import "MBLSRuleBaseCollectionViewCell.h"
#import "LSDrawingRule+addons.h"

@interface MBRuleCollectionDataSource ()
@end


@implementation MBRuleCollectionDataSource

+(instancetype)newWithRules:(NSOrderedSet *)rules {
    return [[[self class] alloc] initWithRules: rules];
}
-(instancetype)initWithRules:(NSOrderedSet *)rules {
    self = [super init];
    if (self) {
        _rules = rules;
    }
    return self;
}
-(void) setRules:(NSOrderedSet *)rules {
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
    MBLSRuleBaseCollectionViewCell* newCell = [collectionView dequeueReusableCellWithReuseIdentifier: @"MBLSRuleCollectionCell" forIndexPath: indexPath];
    
//    CGFloat deviceScaleFactor = collectionView.contentScaleFactor;
    
    newCell.cellItem = (LSDrawingRule*)self.rules[indexPath.row];
    [newCell setNeedsUpdateConstraints];
#pragma message "TODO have cell class monitor properties and call setNeedsUpdateConstraints as needed?"
    return newCell;
}

-(UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
