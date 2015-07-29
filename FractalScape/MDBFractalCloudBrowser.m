//  Created by Taun Chapman on 04/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalCloudBrowser.h"
#import "MDBAppModel.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBCollectionFractalDocumentCell.h"
#import "MDBDocumentController.h"
#import "MDBFractalDocumentProxy.h"
#import "MBFractalLibraryViewController.h"
#import "MDBFractalInfo.h"
#import "MDBCloudManager.h"


@interface MDBFractalCloudBrowser ()


@end

@implementation MDBFractalCloudBrowser

-(void)viewDidLoad
{
    self.cloudDownloadKeys = @[CKFractalRecordNameField,CKFractalRecordDescriptorField,CKFractalRecordFractalDefinitionAssetField,CKFractalRecordFractalThumbnailAssetField];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.activityIndicator.color = [UIColor blueColor];
    
    [super viewDidLoad];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    MDBAppModel* model = (MDBAppModel*)self.appModel;
    if (model.cloudDocumentManager.isCloudAvailable)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: YES];
        [self.activityIndicator startAnimating];
        [self updateSearchResultsForSearchController: self.searchController];
    }
    else
    {
        [self showAlertActionsToAddiCloud: nil];
    }
}

-(void)showAlertActionsToAddiCloud: (id)sender
{
    NSString* title = NSLocalizedString(@"FractalCloud Not Available", nil);
    NSString* message = NSLocalizedString(@"You must have your device logged into iCloud to use FractalCloud. The button below will take you to FractalScapes settings. Once there you will need to Click 'Settings' go to 'iCloud' and login with your AppleId", nil);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    
    //    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Go to iCloud Settings" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [self sendUserToSystemiCloudSettings: sender];
                                   }];
    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Later Maybe" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    [alert addAction: defaultAction];
    
//    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
//    ppc.barButtonItem = sender;
//    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController: alert animated:YES completion:nil];
}

-(void)sendUserToSystemiCloudSettings: (id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: UIApplicationOpenSettingsURLString]];
}

-(void)setupSearchController
{
    [super setupSearchController];
    UISearchBar* searchBar = self.searchController.searchBar;
    searchBar.scopeButtonTitles = @[@"Name",@"Whole Words"];
    searchBar.scopeBarBackgroundImage = [UIImage imageNamed: @"sky"];
    [searchBar sizeToFit];
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
                
                MDBAppModel* appModel = (MDBAppModel*)self.appModel;
                
                MDBFractalInfo* fractalInfo = [appModel.documentController createFractalInfoForFractal: proxy.fractal withDocumentDelegate: nil];
                
                fractalInfo.document.thumbnail = proxy.thumbnail;
                fractalInfo.changeDate = [NSDate date];
                [fractalInfo.document updateChangeCount: UIDocumentChangeDone];
                
                [appModel.documentController setFractalInfoHasNewContents: fractalInfo];
                
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
