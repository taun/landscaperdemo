//
//  MDBHelpRulesCollectionViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/07/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MDBHelpRulesCollectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

@property (nonatomic,strong) IBOutlet UICollectionView      *collectionView;

@end
