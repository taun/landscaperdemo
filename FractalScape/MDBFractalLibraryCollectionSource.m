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
#import "MDBDocumentController.h"

@implementation MDBFractalLibraryCollectionSource

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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)table numberOfItemsInSection:(NSInteger)section
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
//    NSString* stackString = [callStack debugDescription];
    
    NSUInteger count = self.documentController.fractalInfos.count;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FractalLibraryListCell";
    MBCollectionFractalDocumentCell* reuseCell = [collectionView dequeueReusableCellWithReuseIdentifier: CellIdentifier forIndexPath: indexPath];
    reuseCell.document = nil;
    return reuseCell;
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert([cell isKindOfClass:[MBCollectionFractalDocumentCell class]]);
    MBCollectionFractalDocumentCell *documentInfoCell = (MBCollectionFractalDocumentCell *)cell;
    
    MDBFractalInfo* fractalInfo = self.documentController.fractalInfos[indexPath.row];
    
    // Configure the cell with data from the managed object.
    if (fractalInfo.document && fractalInfo.document.documentState == UIDocumentStateNormal)
    {
        documentInfoCell.document = fractalInfo.document;
    }
    else if (!fractalInfo.document || fractalInfo.document.documentState == UIDocumentStateClosed)
    {
        [fractalInfo fetchDocumentWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // Make sure that the list info is still visible once the color has been fetched.
                if ([collectionView.indexPathsForVisibleItems containsObject: indexPath])
                {
//                    NSInteger index = indexPath.row;
                    documentInfoCell.document = fractalInfo.document;
                    MDBFractalDocument* document = (MDBFractalDocument*)documentInfoCell.document;
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
