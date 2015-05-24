//  Created by Taun Chapman on 04/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "MDBDocumentController.h"

@class MDBAppModel;


@interface MDBFractalCloudBrowser : UIViewController <UICollectionViewDataSource,
                                                        UICollectionViewDelegate ,
                                                        UISearchResultsUpdating,
                                                        UISearchControllerDelegate,
                                                        UISearchBarDelegate>

@property (nonatomic,strong) MDBAppModel                                    *appModel;

@property (weak, nonatomic) IBOutlet UICollectionView                       *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView                *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView                                 *searchBarContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint                     *searchBarContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem                        *searchButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem                        *getSelectedButton;


- (IBAction)downloadSelected:(id)sender;
- (IBAction)activateSearch:(id)sender;

@end
