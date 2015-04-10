//
//  MDBFractalLibraryCollectionSource.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;
#import "MDBNavConTransitionCoordinator.h"

@class MDBDocumentController;


@protocol MDBFractalLibraryCollectionDelegate <NSObject>

-(void)libraryCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface MDBFractalLibraryCollectionSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property(nonatomic,weak) IBOutlet UIViewController<MDBFractalLibraryCollectionDelegate>     *viewController;
@property(nonatomic,weak) MDBDocumentController                                             *documentController;
@property(nonatomic,assign) NSInteger                                                       rowCount;


@end
