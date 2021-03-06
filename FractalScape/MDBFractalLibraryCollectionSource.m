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

#pragma mark - FlowLayoutDelegate
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat minInset = 2.0;
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)collectionViewLayout;
    CGFloat itemWidth = layout.itemSize.width;
    CGFloat rowWidth = collectionView.bounds.size.width - (2*minInset);
    NSInteger numItems = floorf(rowWidth/itemWidth);
    CGFloat margins = floorf((rowWidth - (numItems * itemWidth))/(numItems+1.0));
//    margins = MAX(margins, 4.0);
    UIEdgeInsets oldInsets = layout.sectionInset;
    UIEdgeInsets insets = UIEdgeInsetsMake(oldInsets.top, margins, oldInsets.bottom, margins);
    return insets;
//    return 20.0;
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

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert([cell isKindOfClass:[MBCollectionFractalDocumentCell class]]);
    MBCollectionFractalDocumentCell *documentInfoCell = (MBCollectionFractalDocumentCell *)cell;
    
    MDBFractalInfo* fractalInfo = self.sourceInfos[indexPath.row];
    
    // Configure the cell with data from the managed object.
    if (fractalInfo.document && fractalInfo.document.documentState == UIDocumentStateNormal)
    {
        documentInfoCell.info = fractalInfo;
    }
    else if (!fractalInfo.document || fractalInfo.document.documentState == UIDocumentStateClosed)
    {
        [fractalInfo fetchDocumentWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // Make sure that the list info is still visible once the color has been fetched.
                if ([collectionView.indexPathsForVisibleItems containsObject: indexPath])
                {
//                    NSInteger index = indexPath.row;
                    documentInfoCell.info = fractalInfo;
                    MDBFractalDocument* document = (MDBFractalDocument*)documentInfoCell.info.document;
                    [document closeWithCompletionHandler:^(BOOL success) {}];
                } 
//                [fractalInfo.document closeWithCompletionHandler:^(BOOL success) {
                    //
//                }];;
            });
        }];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
//    MBCollectionFractalDocumentCell* fractalDocCell = (MBCollectionFractalDocumentCell*)cell;
//    MDBFractalDocument* document = (MDBFractalDocument*)fractalDocCell.document;
//    UIDocumentState docState = document.documentState;
    
//    if (docState != UIDocumentStateClosed)
//    {
//        [document closeWithCompletionHandler:^(BOOL success) {
//            //
//        }];;
//    }
    //    [fractalInfo unCacheDocument]; //should release the document and thumbnail from memory.
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewController libraryCollectionView: collectionView shouldSelectItemAtIndexPath: indexPath];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Depends on viewController being nil for the LibraryEdit instance of the dataSource. Meaning the following does nothing in that case.
    [self.viewController libraryCollectionView: collectionView didSelectItemAtIndexPath: indexPath];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.viewController libraryCollectionView: collectionView didDeselectItemAtIndexPath: indexPath];
}

@end
