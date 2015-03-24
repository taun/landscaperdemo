//
//  MDBFractalLibraryCollectionSource.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

@class MDBDocumentController;

@interface MDBFractalLibraryCollectionSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegate>

@property(nonatomic,weak) MDBDocumentController     *documentController;
@property(nonatomic,assign) NSInteger               rowCount;

@end
