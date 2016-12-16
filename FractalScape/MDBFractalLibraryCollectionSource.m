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
        NSLog(@"Count: %lu Stack: %@",(unsigned long)count, stackString);
    }
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FractalLibraryListCell";
    MBCollectionFractalDocumentCell* reuseCell = [collectionView dequeueReusableCellWithReuseIdentifier: CellIdentifier forIndexPath: indexPath];
    reuseCell.info = nil;

    NSParameterAssert([reuseCell isKindOfClass:[MBCollectionFractalDocumentCell class]]);
    
    // Configure the cell with data from the managed object.
    [self loadItemAtIndex: indexPath forCell: reuseCell collectionView: collectionView];

    return reuseCell;
}

-(void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    for (NSIndexPath* path in indexPaths)
    {
        [self loadItemAtIndex: path forCell: nil collectionView: collectionView];
    }
}

-(void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    for (NSIndexPath* path in indexPaths)
    {
        MDBFractalInfo* fractalInfo = self.sourceInfos[path.row];
        if (fractalInfo.document && fractalInfo.document.documentState == UIDocumentStateNormal)
        {
            [fractalInfo.document closeWithCompletionHandler:^(BOOL success) {}];
        }
    }
   
}

-(void)loadItemAtIndex: (NSIndexPath*)indexPath forCell: (MBCollectionFractalDocumentCell*) documentInfoCell collectionView:(UICollectionView *)collectionView
{
//    MBCollectionFractalDocumentCell *documentInfoCell = (MBCollectionFractalDocumentCell *)cell;
    
    MDBFractalInfo* fractalInfo = self.sourceInfos[indexPath.row];
    documentInfoCell.info = fractalInfo;
    
    // Configure the cell with data from the managed object.
    if (!fractalInfo.document || fractalInfo.document.documentState == UIDocumentStateClosed)
    {
        [fractalInfo fetchDocumentWithCompletionHandler:^{
            //            dispatch_sync(dispatch_get_main_queue(), ^{
            //                // Make sure that the list info is still visible once the color has been fetched.
//            if (documentInfoCell && [documentInfoCell.info.identifier isEqualToString: fractalInfo.identifier])
//            {
//                //                    //                    NSInteger index = indexPath.row;
//                documentInfoCell.info = fractalInfo;
//                MDBFractalDocument* document = (MDBFractalDocument*)documentInfoCell.info.document;
//                [document closeWithCompletionHandler:^(BOOL success) {}];
//            }
//            [fractalInfo.document closeWithCompletionHandler:^(BOOL success) {
//                
//            }];;
//            //            });
        }];
    }
}
@end
