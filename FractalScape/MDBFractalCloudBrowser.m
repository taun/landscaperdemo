//  Created by Taun Chapman on 04/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalCloudBrowser.h"
#import "MDBMainLibraryTabBarController.h"
#import "MDBAppModel.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBCollectionFractalDocumentCell.h"
#import "MDBDocumentController.h"
#import "MDBFractalDocumentProxy.h"
#import "MBFractalLibraryViewController.h"
#import "MDBFractalInfo.h"
#import "MDBCloudManager.h"

#import <Crashlytics/Crashlytics.h>

@interface MDBFractalCloudBrowser ()

@property(nonatomic,assign)BOOL             handlingFetchRequestErrorWasPostponed;
@property(nonatomic,strong)NSError          *fetchRequestError;

@end



@implementation MDBFractalCloudBrowser

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cloudDownloadKeys = @[CKFractalRecordNameField,CKFractalRecordDescriptorField,CKFractalRecordFractalDefinitionAssetField,CKFractalRecordFractalThumbnailAssetField];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.activityIndicator.color = [UIColor blueColor];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [Answers logContentViewWithName: NSStringFromClass([self class]) contentType: @"Public Fractals" contentId: NSStringFromClass([self class]) customAttributes:nil];
    
    MDBAppModel* model = (MDBAppModel*)self.appModel;
    if (model.cloudDocumentManager.isCloudAvailable)
    {
        [self updateSearchResultsForSearchController: self.searchController];
    }
    else
    {
        [self showAlertActionsToAddiCloud: nil];
    }
}

- (IBAction)unwindFromWelcome:(UIStoryboardSegue *)segue
{
    UIViewController* sourceController = (UIViewController*)segue.sourceViewController;
    
    // This is necessary due to presentation being over full context, popover style
    [sourceController.presentingViewController dismissViewControllerAnimated: YES completion:^{
        MDBAppModel* model = (MDBAppModel*)self.appModel;
        [model exitWelcomeState];
        if (self.handlingFetchRequestErrorWasPostponed)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleFetchRequestError: self.fetchRequestError];
            });

        }
    }];
}

-(void)showAlertActionsToAddiCloud: (id)sender
{
    NSString* title = NSLocalizedString(@"Cloud Not Available", nil);
    NSString* message = NSLocalizedString(@"You must have your device logged into iCloud to use FractalCloud. The button below will take you to FractalScapes settings. Once there you will need to Click 'Settings' go to 'iCloud' and login with your AppleId", nil);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
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

-(void)handleFetchRequestSuccess
{
    MDBAppModel* model = self.appModel;
    
    if (model.loadDemoFiles)
    {  // permanently skip loading demo fractals if iCloud is available
        [model demoFilesLoaded];
    }
}

-(void) handleFetchRequestError: (NSError*)error
{
    if (self.presentedViewController)
    {
        // welcome screen is up or some other modally presented view and we need to defer the error box.
        self.fetchRequestError = error;
        self.handlingFetchRequestErrorWasPostponed = YES;
    }
    else
    {
        self.handlingFetchRequestErrorWasPostponed = NO;

        self.networkConnected = NO;
        BOOL giveRetryOption = NO;
        BOOL giveLoadLocalOption = NO;
        
        NSString *title;
        NSString *message;
        NSLog(@"%@ error code: %ld, %@",NSStringFromSelector(_cmd),(long)error.code,[error.userInfo debugDescription]);
        CKErrorCode code = error.code;
        
        switch (code) {
            case CKErrorInternalError: // 1
                title = NSLocalizedString(@"Network problem", nil);
                message = @"Please try again in couple of minutes";
                giveLoadLocalOption = YES;
                break;
                
            case CKErrorPartialFailure: // 2
                title = NSLocalizedString(@"Network problem", nil);
                message = @"Please try again in couple of minutes";
                giveLoadLocalOption = YES;
                break;
                
            case CKErrorNetworkUnavailable: // 3
                title = NSLocalizedString(@"No Network", nil);
                message = @"Please try again when connected to a network";
                giveLoadLocalOption = YES;
                break;
                
            case CKErrorNetworkFailure: // 4
                title = NSLocalizedString(@"Network problem", nil);
                message = @"Please try again in couple of minutes";
                giveLoadLocalOption = YES;
                break;
                
            case CKErrorServiceUnavailable: // 6
                title = NSLocalizedString(@"Cloud Unavailable", nil);
                message = @"iCloud is temporarily unavailable. Please try again in couple of minutes";
                giveLoadLocalOption = YES;
                break;
                
            case CKErrorRequestRateLimited: // 7
                title = NSLocalizedString(@"Cloud Unavailable", nil);
                message = [NSString stringWithFormat: @"iCloud is temporarily unavailable. Please try again in %@ seconds",error.userInfo[@"CKRetryAfter"]];
                giveLoadLocalOption = YES;
                break;
                
            case CKErrorZoneBusy: // 23
                title = NSLocalizedString(@"Too Much Traffic", nil);
                message = @"Please try again in couple of minutes";
                giveLoadLocalOption = YES;
                break;
                
            case CKErrorOperationCancelled: // 20
                title = NSLocalizedString(@"Cloud Timeout", nil);
                message = @"Try again later? OR";
                giveRetryOption = YES;
                giveLoadLocalOption = YES;
                break;
                
            case CKErrorQuotaExceeded: // 25
                title = NSLocalizedString(@"Cloud quota reached", nil);
                message = @"Free some cloud space";
                break;
                
            default:
                title = NSLocalizedString(@"Problem with the Cloud", nil);
                message = @"Try again later.";
                break;
        }
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                       message: message
                                                                preferredStyle: UIAlertControllerStyleAlert];
        
        UIAlertController* __weak weakAlert = alert;
        
        MDBAppModel* model = self.appModel;
        
        if (giveLoadLocalOption && model.loadDemoFiles)
        {
            NSString* actionTitle = NSLocalizedString(@"Load Local Starter Fractals", @"");
            UIAlertAction* loadAction = [UIAlertAction actionWithTitle: actionTitle style: UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                          {
                                                  [model loadInitialDocuments];
                                                  
                                                  MDBMainLibraryTabBarController* tabController = (MDBMainLibraryTabBarController*) self.tabBarController;
                                                  tabController.selectedViewController = [tabController getTabLibraryBrowserNav];
                                          }];
            
            [alert addAction: loadAction];
        }
        
        if (giveRetryOption)
        {
            NSString* actionTitle = NSLocalizedString(@"Retry Cloud Now", @"Try the action again now");
            UIAlertAction* retryAction = [UIAlertAction actionWithTitle: actionTitle style: UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                          {
                                              [self updateSearchResultsForSearchController: self.searchController];
                                          }];
            
            [alert addAction: retryAction];
        }
        
        NSString *okActionTitle = NSLocalizedString(@"Ok, Try later", nil);
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: okActionTitle style: UIAlertActionStyleCancel handler:^(UIAlertAction * action)
                                        {
                                        }];
        
        [alert addAction: defaultAction];
        
#pragma message "TODO how to include additional options from subclass?"
        [self.navigationController presentViewController: weakAlert animated: YES completion:^{
            //
        }];
    }
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

    NSArray* descriptors;
    
    if ((NO)) {
        descriptors = @[byModDate];
    }
    else
    {
        descriptors = @[byModDate, byName];
    }

    [self fetchCloudRecordsWithPredicate: predicate sortDescriptors: descriptors timeout: 12.0];
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
                
                [Answers logCustomEventWithName: @"FractalDownload" customAttributes: @{@"Name" : proxy.fractal.name}];
                
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
