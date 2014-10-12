//
//  MBRuleCollectionDataSource.m
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBRuleCollectionDataSource.h"
#import "MBLSRuleCollectionViewCell.h"
#import "LSDrawingRule+addons.h"

#import "FractalScapeIconSet.h"

@interface MBRuleCollectionDataSource ()
@end


@implementation MBRuleCollectionDataSource

+(instancetype)newWithRules:(NSMutableArray *)rules {
    return [[[self class] alloc] initWithRules: rules];
}
-(instancetype)initWithRules:(NSMutableArray *)rules {
    self = [super init];
    if (self) {
        _rules = rules;
    }
    return self;
}
-(void) setRules:(NSMutableArray *)rules {
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
    
//    CGFloat deviceScaleFactor = collectionView.contentScaleFactor;
    
    LSDrawingRule* rule = (LSDrawingRule*)self.rules[indexPath.row];
    UIImage* cellImage = [rule asImage];
    
//    CGFloat cellWidth = newCell.bounds.size.width;
//    CGFloat imageWidth = cellImage.size.width;
    
//    CGRect ivBounds = newCell.imageView.bounds;
//    newCell.imageView.bounds = CGRectMake(ivBounds.origin.x, ivBounds.origin.y, imageWidth, imageWidth);
    newCell.imageView.image = cellImage;
//    newCell.imageView.bounds = CGRectMake(ivBounds.origin.x, ivBounds.origin.y, cellWidth-6, cellWidth-6);
    
//    if (cellWidth < 35) {
//        newCell.imageView.contentScaleFactor = deviceScaleFactor*2;
//    } else {
//        newCell.imageView.contentScaleFactor = deviceScaleFactor;
//    }
    [newCell setNeedsUpdateConstraints];
#pragma message "TODO have cell class monitor properties and call setNeedsUpdateConstraints as needed?"
    return newCell;
}

-(UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
