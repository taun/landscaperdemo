//  Created by Taun Chapman on 04/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalCloudBrowser.h"
#import "MDBAppModel.h"
#import "MDLCloudKitManager.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBCollectionFractalDocumentCell.h"
#import "MDBDocumentController.h"
#import "MDBFractalDocumentProxy.h"
#import "MBFractalLibraryViewController.h"
#import "MDBFractalInfo.h"

#import <MDUiKit/NSString+MDKConvenience.h>

@interface MDBFractalCloudBrowser ()

@property (nonatomic,strong) NSArray                        *publicCloudRecords;
@property (nonatomic,strong) UISearchController             *searchController;
@property(nonatomic,assign,getter=isNetworkConnected) BOOL  networkConnected;

@end

@implementation MDBFractalCloudBrowser

-(void) fetchCloudRecordsWithPredicate: (NSPredicate*)predicate andSortDescriptors: (NSArray*)descriptors
{
    self.getSelectedButton.enabled = NO;
    
    [self.appModel.cloudManager fetchPublicRecordsWithType: CKFractalRecordType predicate: predicate sortDescriptor: descriptors completionHandler:^(NSArray *records, NSError* error)
     {
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: NO];
         [self.activityIndicator stopAnimating];
         
         if (!error)
         {
             self.publicCloudRecords = records;
             self.networkConnected = YES;
             
             if (self.collectionView.numberOfSections >= 1)
             {
                 [self.collectionView reloadSections: [NSIndexSet indexSetWithIndex: 0]];
             } else
             {
                 [self.collectionView reloadData];
             }
             
             if (self.publicCloudRecords.count > 0)
             {
                 self.searchButton.enabled = YES;
             }
             
         } else
         {
             self.networkConnected = NO;
             NSString *title;
             NSString *message;
             
             if (error.code == 4)
             {
                 title = NSLocalizedString(@"Can't Browse", nil);
                 message = error.localizedDescription;
             } else
             {
                 title = NSLocalizedString(@"Can't Browse", nil);
                 message = error.localizedDescription;
             }
             
             NSString *okActionTitle = NSLocalizedString(@"OK", nil);
             
             UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                            message: message
                                                                     preferredStyle: UIAlertControllerStyleAlert];
             
             [alert addAction:[UIAlertAction actionWithTitle: okActionTitle style: UIAlertActionStyleCancel handler:nil]];
             
             [self presentViewController: alert animated: YES completion:^{
                 //
             }];
         }
     }];
}

-(void)setupSearchController
{
    _searchController = [[UISearchController alloc] initWithSearchResultsController: nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    //    _searchController.searchBar.prompt = @"Search by name";
    UISearchBar* searchBar = _searchController.searchBar;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.scopeButtonTitles = @[@"Name",@"Whole Words"];
    searchBar.showsScopeBar = NO;
    searchBar.showsCancelButton = NO;
    searchBar.tintColor = self.view.tintColor;
    searchBar.scopeBarBackgroundImage = [UIImage imageNamed: @"sky"];
    [searchBar sizeToFit];
    [self.searchBarContainer addSubview: searchBar];
    self.searchBarContainerHeightConstraint.constant = 0;
    searchBar.delegate = self;
    _searchController.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupSearchController];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: YES];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.activityIndicator.color = [UIColor blueColor];
    [self.activityIndicator startAnimating];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateCollectionViewOffsetForNavAndSearch];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateSearchResultsForSearchController: self.searchController];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        [self.collectionView.collectionViewLayout invalidateLayout];
        if (self.searchController.active)
        {
            [self.searchController.searchBar setNeedsLayout];
            [self.searchController.searchBar layoutIfNeeded];
        }
        [self updateCollectionViewOffsetForNavAndSearch];
        
     }];
}

-(void)updateCollectionViewOffsetForNavAndSearch
{
    CGFloat padding = 0;
    if (self.searchController.active)
    {
        padding = self.searchController.searchBar.bounds.size.height;
    }
    self.searchBarContainerHeightConstraint.constant = padding;

    CGRect navFrame = self.navigationController.navigationBar.frame;
    CGFloat navHeight = CGRectGetMaxY(navFrame) + padding;
    self.collectionView.contentInset = UIEdgeInsetsMake(navHeight, 0, 0, 0);
    [self.collectionView setContentOffset: CGPointMake(0, -navHeight) animated: YES] ;
}

#pragma mark - UISearchControllerDelegate

-(void)willPresentSearchController:(UISearchController *)searchController
{
}

-(void)presentSearchController:(UISearchController *)searchController
{
}
-(void)didPresentSearchController:(UISearchController *)searchController
{
//    searchController.searchBar.showsCancelButton = NO;
    [self updateCollectionViewOffsetForNavAndSearch];
    
    self.tabBarController.tabBar.hidden = YES;
}

-(void)didDismissSearchController:(UISearchController *)searchController
{
    [self updateCollectionViewOffsetForNavAndSearch];
    self.tabBarController.tabBar.hidden = NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchController.active = NO;
}

- (IBAction)activateSearch:(id)sender
{
    self.searchController.active = !self.searchController.active;
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString* nameMatchString;
    
    if (searchController.active)
    {
        NSString* searchText =  [searchController.searchBar.text lowercaseString];
        nameMatchString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    NSPredicate* predicate;
    
    if ([nameMatchString isNonEmptyString])
    {
        if (searchController.searchBar.selectedScopeButtonIndex == 0)
        {
            predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH %@", CKFractalRecordNameInsensitiveField, nameMatchString];
        }
        else
        {
            predicate = [NSPredicate predicateWithFormat:@"allTokens TOKENMATCHES[cdl] %@", nameMatchString]; // works for full works=tokens
        }
        
    }
    else
    {
        predicate = [NSPredicate predicateWithValue: YES];
    }

    NSSortDescriptor* byModDate = [NSSortDescriptor sortDescriptorWithKey: @"modificationDate" ascending: NO];
    NSSortDescriptor* byName = [NSSortDescriptor sortDescriptorWithKey: CKFractalRecordNameField ascending: YES];
    NSArray* descriptors = @[byModDate, byName];

    [self fetchCloudRecordsWithPredicate: predicate andSortDescriptors: descriptors];
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
//- (UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
//    
//    UICollectionReusableView* rView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader
//                                                                                      withReuseIdentifier: @"FractalLibrarySearchHeader"
//                                                                                             forIndexPath: indexPath];
//    //rView.backgroundColor = [UIColor clearColor];
//    if ([[rView subviews] count] == 0)
//    {
//        [self.searchController.searchBar sizeToFit];
//        [rView addSubview: self.searchController.searchBar];
//    }
//    return rView;
//}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.isNetworkConnected ? 1 : 0;
}

- (NSInteger)collectionView:(UICollectionView *)table numberOfItemsInSection:(NSInteger)section
{
    if (self.publicCloudRecords)
    {
        return self.publicCloudRecords.count;
    }
    else
    {
        return 1;
    }
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
    if (self.publicCloudRecords) {
        NSParameterAssert([cell isKindOfClass:[MBCollectionFractalDocumentCell class]]);
        MBCollectionFractalDocumentCell *documentInfoCell = (MBCollectionFractalDocumentCell *)cell;
        
        CKRecord* fractalRecord = self.publicCloudRecords[indexPath.row];
        
        MDBFractalDocumentProxy* proxy = [MDBFractalDocumentProxy new];
        CKAsset* fractalFile = fractalRecord[CKFractalRecordFractalDefinitionAssetField];
        CKAsset* thumbnailFile = fractalRecord[CKFractalRecordFractalThumbnailAssetField];
        
        NSData* fractalData = [NSData dataWithContentsOfURL: fractalFile.fileURL];
        NSData* thumbnailData = [NSData dataWithContentsOfURL: thumbnailFile.fileURL];
        
        proxy.fractal = [NSKeyedUnarchiver unarchiveObjectWithData: fractalData];
        proxy.thumbnail = [UIImage imageWithData: thumbnailData];
        proxy.loadResult = MDBFractalDocumentLoad_SUCCESS;
        
        documentInfoCell.document = proxy;
    }
    // Configure the cell with data from the managed object.
//    if (fractalInfo.document && fractalInfo.document.documentState == UIDocumentStateNormal)
//    {
//        documentInfoCell.document = fractalInfo.document;
//    }
//    else if (!fractalInfo.document || fractalInfo.document.documentState == UIDocumentStateClosed)
//    {
//        [fractalInfo fetchDocumentWithCompletionHandler:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                // Make sure that the list info is still visible once the color has been fetched.
//                if ([collectionView.indexPathsForVisibleItems containsObject: indexPath])
//                {
//                    documentInfoCell.document = fractalInfo.document;
//                }
//                [fractalInfo.document closeWithCompletionHandler:^(BOOL success) {
//                    //
//                }];;
//            });
//        }];
//    }
}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    MBCollectionFractalDocumentCell* fractalDocCell = (MBCollectionFractalDocumentCell*)cell;
    fractalDocCell.document = nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.getSelectedButton.enabled = YES;
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.collectionView indexPathsForSelectedItems] count] == 0) {
        self.getSelectedButton.enabled = NO;
    }
}

- (IBAction)downloadSelected:(id)sender
{
    if (self.presentedViewController)
    {
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }
    
    NSArray* selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
    if (selectedIndexPaths.count > 0)
    {
        if (self.publicCloudRecords)
        {
            for (NSIndexPath* path in selectedIndexPaths)
            {
                MBCollectionFractalDocumentCell *documentInfoCell = (MBCollectionFractalDocumentCell *)[self.collectionView cellForItemAtIndexPath: path];
                MDBFractalDocumentProxy* proxy = documentInfoCell.document;
                
                MDBFractalInfo* fractalInfo = [self.appModel.documentController createFractalInfoForFractal: proxy.fractal withDocumentDelegate: nil];
                
                fractalInfo.document.thumbnail = proxy.thumbnail;
                fractalInfo.changeDate = [NSDate date];
                [fractalInfo.document updateChangeCount: UIDocumentChangeDone];
                
                [self.appModel.documentController setFractalInfoHasNewContents: fractalInfo];
                
                [fractalInfo.document closeWithCompletionHandler:nil];
                
                [self.collectionView deselectItemAtIndexPath: path animated: YES];
            }
            
            UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Downloaded"
                                                                           message: @"Go to 'My Fractals' tab"
                                                                    preferredStyle: UIAlertControllerStyleAlert];
            
            UIAlertController* __weak weakAlert = alert;
            
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action)
                                            {
                                                [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                            }];
            
            [alert addAction: defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

@end
