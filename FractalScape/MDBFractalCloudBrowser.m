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

@property(nonatomic,assign) BOOL                                    initialLoad;
@property(nonatomic,strong) NSMutableDictionary                     *cachedFractalsByRecordNameKey;

@end



@implementation MDBFractalCloudBrowser

-(NSMutableDictionary *)cachedFractalsByRecordNameKey
{
    if (!_cachedFractalsByRecordNameKey) {
        _cachedFractalsByRecordNameKey = [NSMutableDictionary dictionaryWithCapacity: 50];
    }
    
    return _cachedFractalsByRecordNameKey;
}

-(void)viewDidLoad
{
    self.cloudDownloadKeys = @[CKFractalRecordNameField,
                               CKFractalRecordDescriptorField,
                               CKFractalRecordFractalDefinitionAssetField];
    
    self.cloudThumbnailKey = CKFractalRecordFractalThumbnailAssetField;
    
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.activityIndicator.color = [UIColor blueColor];
    
    _initialLoad = YES;

    [super viewDidLoad];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [Answers logContentViewWithName: NSStringFromClass([self class]) contentType: @"Public Fractals" contentId: NSStringFromClass([self class]) customAttributes:nil];
    
    if (self.searchController.active || self.publicCloudRecords.count == 0)
    {
        [self updateSearchResultsForSearchController: self.searchController];
    }
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self setCachedFractalsByRecordNameKey: nil];
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

-(void)presentFetchErrorAlertTitle:(NSString *)title message:(NSString *)message withActions:(NSMutableArray<UIAlertAction *> *)alertActions
{
    MDBAppModel* model = self.appModel;
    
    if (model.loadDemoFiles)
    {
        NSString* actionTitle = NSLocalizedString(@"Load Local Starter Fractals", @"");
        UIAlertAction* loadAction = [UIAlertAction actionWithTitle: actionTitle style: UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                     {
                                         [model loadInitialDocuments];
                                         
                                         MDBMainLibraryTabBarController* tabController = (MDBMainLibraryTabBarController*) self.tabBarController;
                                         tabController.selectedViewController = [tabController getTabLibraryBrowserNav];
                                     }];
        [alertActions insertObject: loadAction atIndex: 0];
    }
    [super presentFetchErrorAlertTitle: title message: message withActions: alertActions];
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

    [self fetchCloudRecordsWithPredicate: predicate sortDescriptors: descriptors timeout: 30.0];
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
    reuseCell.info = nil;
    return reuseCell;
}

//-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
//{
//    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
//    
//    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
//        
//        
//    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
//        //
//        [self.collectionView.collectionViewLayout invalidateLayout];
//    }];
//    //    subLayer.position = self.fractalView.center;
//}

#pragma mark - FlowLayoutDelegate

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Should have a test for layout type
//    
//    UICollectionViewFlowLayout* flowLayout;
//    
//    if ([collectionViewLayout isKindOfClass: [UICollectionViewFlowLayout class]])
//    {
//        flowLayout = (UICollectionViewFlowLayout*) collectionViewLayout;
//    }
//    
//    int minWidth = 150;
//    int maxWidth = 200;
//    
//    int viewWidth = (int)self.collectionView.bounds.size.width;
//    
//    int totalRemainderSpace = viewWidth % minWidth;
//    int totalItems = viewWidth / minWidth;
//    
//    int itemMarginTotal = (totalItems - 1) * (int)flowLayout.minimumInteritemSpacing;
//    int extraSpace = totalRemainderSpace - itemMarginTotal;
//    
//    int width = MAX(minWidth, minWidth + (extraSpace / totalItems) - (int)(flowLayout.sectionInset.left + flowLayout.sectionInset.right));
//    
//    CGSize newSize = CGSizeMake(width, 258);
//    
//    NSLog(@"Width %@", NSStringFromCGSize(newSize));
//    
//    return newSize;
//}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.publicCloudRecords) {
        NSParameterAssert([cell isKindOfClass:[MBCollectionFractalDocumentCell class]]);
        MBCollectionFractalDocumentCell *documentInfoCell = (MBCollectionFractalDocumentCell *)cell;
        
        CKRecord* fractalRecord = self.publicCloudRecords[indexPath.row];
        NSString* recordName = fractalRecord.recordID.recordName;
        
        MDBFractalInfo* info = self.cachedFractalsByRecordNameKey[recordName];
        
        if (!info && recordName)
        {
            MDBFractalDocumentProxy* proxy = [MDBFractalDocumentProxy new];
            CKAsset* fractalFile = fractalRecord[CKFractalRecordFractalDefinitionAssetField];
            
            NSData* fractalData = [NSData dataWithContentsOfURL: fractalFile.fileURL];
            
            proxy.fractal = [NSKeyedUnarchiver unarchiveObjectWithData: fractalData];
            if (proxy.thumbnail == nil)
            {
                [self.appModel.cloudKitManager fetchImageAsset: self.cloudThumbnailKey forRecordWithID: fractalRecord.recordID.recordName completionHandler:^(UIImage *image) {
                    // get cached or cloud image and set
                    proxy.thumbnail = image;
                }];
            }
            proxy.loadResult = MDBFractalDocumentLoad_SUCCESS;
            
            info = [[MDBFractalInfo alloc]init];
            [info setProxyDocument: proxy];
            
            self.cachedFractalsByRecordNameKey[recordName] = info;
        }
        
        
        documentInfoCell.info = info;
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
    fractalDocCell.info = nil;
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
                MDBFractalDocumentProxy* proxy = documentInfoCell.info.document;
                
                if (proxy.fractal.name != nil) [Answers logCustomEventWithName: @"FractalDownload" customAttributes: @{@"Name" : proxy.fractal.name}];
                
                MDBAppModel* appModel = (MDBAppModel*)self.appModel;
                
                MDBFractalInfo* fractalInfo = [appModel.documentController createFractalInfoForFractal: proxy.fractal withImage: [proxy.thumbnail copy] withDocumentDelegate: nil];
                
//                [appModel.documentController setFractalInfoHasNewContents: fractalInfo];
                
                [fractalInfo closeDocument];
                
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
