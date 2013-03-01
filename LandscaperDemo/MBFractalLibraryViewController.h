//
//  MBFractalLibraryViewController.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LSFractal;

@interface MBFractalLibraryViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *fractalCollectionView;

@property (weak, nonatomic) LSFractal                 *selectedFractal;

@end
