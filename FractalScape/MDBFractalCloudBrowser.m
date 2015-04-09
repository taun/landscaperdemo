//  Created by Taun Chapman on 04/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalCloudBrowser.h"
#import "MDLCloudKitManager.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBCollectionFractalDocumentCell.h"
#import "MDBDocumentController.h"
#import "MDBFractalDocumentProxy.h"
#import "MBFractalLibraryViewController.h"
#import "MDBFractalInfo.h"

@interface MDBFractalCloudBrowser ()

@property(nonatomic,strong)MDLCloudKitManager           *cloudManager;
@property (nonatomic,strong) NSArray                    *publicCloudRecords;

@end

@implementation MDBFractalCloudBrowser

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIVisualEffectView* blurEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleExtraLight]];
    self.collectionView.backgroundView = blurEffectView;

    self.cloudManager = [[MDLCloudKitManager alloc] init];
    // Do any additional setup after loading the view, typically from a nib.
    //    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    //    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    //    self.navigationItem.rightBarButtonItem = addButton;
    
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.cloudManager fetchPublicFractalRecordsWithCompletionHandler:^(NSArray *records, NSError* error) {
        if (!error) {
            self.publicCloudRecords = records;
            [self.collectionView reloadData];
        } else {
            
            NSString *title = NSLocalizedString(@"Sorry", nil);
            NSString *message = NSLocalizedString(@"Was not able to connect to the Cloud Server.", nil);
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

//    [self.cloudManager requestDiscoverabilityPermission:^(BOOL discoverable) {
//        
//        if (discoverable) {
//            [self.cloudManager fetchPublicFractalRecordsWithCompletionHandler:^(NSArray *records) {
//                self.publicCloudRecords = records;
//                [self.collectionView reloadData];
//            }];
//        } else {
//            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CloudKitAtlas" message:@"Getting your name using Discoverability requires permission." preferredStyle:UIAlertControllerStyleAlert];
//            
//            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
//                [self dismissViewControllerAnimated:YES completion:nil];
//                
//            }];
//            
//            [alert addAction:action];
//            
//            [self presentViewController:alert animated:YES completion:nil];
//        }
//    }];
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    MBCollectionFractalSupplementaryLabel* rView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                                                                                      withReuseIdentifier: @"FractalLibraryCollectionHeader"
                                                                                             forIndexPath: indexPath];
    
    return rView;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)table numberOfItemsInSection:(NSInteger)section
{
    return self.publicCloudRecords.count;
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
    
    CKRecord* fractalRecord = self.publicCloudRecords[indexPath.row];
    
    MDBFractalDocumentProxy* proxy = [MDBFractalDocumentProxy new];
    CKAsset* fractalFile = fractalRecord[CKFractalRecordFractalDefinitionAssetField];
    CKAsset* thumbnailFile = fractalRecord[CKFractalRecordFractalThumbnailAssetField];
    
    NSData* fractalData = [NSData dataWithContentsOfURL: fractalFile.fileURL];
    NSData* thumbnailData = [NSData dataWithContentsOfURL: thumbnailFile.fileURL];
    
    proxy.fractal = [NSKeyedUnarchiver unarchiveObjectWithData: fractalData];
    proxy.thumbnail = [UIImage imageWithData: thumbnailData];
    
    documentInfoCell.document = proxy;
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
//    MDBFractalDocument* document = fractalDocCell.document;
//    UIDocumentState docState = document.documentState;
//    
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
    MBCollectionFractalDocumentCell *documentInfoCell = (MBCollectionFractalDocumentCell *)[collectionView cellForItemAtIndexPath: indexPath];
    MDBFractalDocumentProxy* proxy = documentInfoCell.document;
    MBFractalLibraryViewController* library = [[[[[self tabBarController]viewControllers] objectAtIndex: 0]viewControllers]objectAtIndex: 0];
    
    MDBFractalInfo* fractalInfo = [library.documentController createFractalInfoForFractal: proxy.fractal withDocumentDelegate: nil];
    
    fractalInfo.document.thumbnail = proxy.thumbnail;
    fractalInfo.changeDate = [NSDate date];
    [fractalInfo.document updateChangeCount: UIDocumentChangeDone];
    
    [library.documentController setFractalInfoHasNewContents: fractalInfo];
    
    [fractalInfo.document closeWithCompletionHandler:nil];
    
    [self.collectionView deselectItemAtIndexPath: indexPath animated: YES];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Downloaded"
                                                                   message: @"Go to your fractals"
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

@end
