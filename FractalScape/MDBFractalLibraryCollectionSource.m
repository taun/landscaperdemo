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

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    MBCollectionFractalSupplementaryLabel* rView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader
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
    return self.rowCount;
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
    
    MDBFractalInfo* fractalInfo = self.documentController[indexPath.row];
    
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
    [self.viewController libraryCollectionView: collectionView didSelectItemAtIndexPath: indexPath];
}

@end
