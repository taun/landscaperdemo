//
//  MDBFractalLibraryCollectionSource.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalLibraryCollectionSource.h"

#import "MBCollectionFractalDocumentCell.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MDBFractalInfo.h"
#import "MBFractalLibraryViewController.h"

@implementation MDBFractalLibraryCollectionSource

@synthesize sourceInfos = _sourceInfos;

-(void)awakeFromNib
{
    [super awakeFromNib];
    _sourceInfos = [NSMutableArray arrayWithCapacity: 200];
}


#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    MBCollectionFractalSupplementaryLabel* rView = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                                                      withReuseIdentifier: kSupplementaryHeaderCellIdentifier
                                                                                             forIndexPath: indexPath];
    
    return rView;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSUInteger count = self.sourceInfos.count;

    BOOL logStack = NO;
    if (logStack)
    {
        NSArray* callStack = [NSThread callStackSymbols];
        NSMutableArray* filteredStack = [NSMutableArray new];
        for (NSString* stackEntry in callStack)
        {
            if ([stackEntry containsString: @"FractalScapes"])
            {
                [filteredStack addObject: stackEntry];
            }
        }
        NSString* stackString = [filteredStack debugDescription];
        NSLog(@"Count: %lu Stack: %@",count, stackString);
    }
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FractalLibraryListCell";
    MBCollectionFractalDocumentCell* reuseCell = [collectionView dequeueReusableCellWithReuseIdentifier: CellIdentifier forIndexPath: indexPath];
    reuseCell.info = nil;
    return reuseCell;
}

@end
