//
//  Created by Taun Chapman on 03/16/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import AssetsLibrary;

#import "MBFractalLibraryShareViewController.h"

#import "MDBAppModel.h"
#import "MDBFractalInfo.h"
#import "MDBDocumentController.h"
#import "MDBFractalDocumentCoordinator.h"
#import "MDLCloudKitManager.h"
#import "MDBCloudManager.h"

@interface MBFractalLibraryShareViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem    *shareButton;

- (IBAction)shareButtonPressed:(id)sender;

@end

@implementation MBFractalLibraryShareViewController

/*!

 */
- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!CGPointEqualToPoint(self.initialContentOffset, CGPointZero)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.collectionView.contentOffset = self.initialContentOffset;
        });
    }
}

-(void) rightButtonsEnabledState: (BOOL)state
{
    self.shareButton.enabled = state;
}

#pragma mark - MDBFractalLibraryCollectionDelegate
-(void)libraryCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.indexPathsForSelectedItems.count > 0)
    {
        [self rightButtonsEnabledState: YES];
    }
}

-(void)libraryCollectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.indexPathsForSelectedItems.count == 0)
    {
        [self rightButtonsEnabledState: NO];
    }
}

- (IBAction)shareButtonPressed:(id)sender
{
    if (self.presentedViewController)
    {
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }
    
    if (self.appModel.cloudDocumentManager.isCloudAvailable)
    {
        [self showAlertActionsToShare: sender];
    }
    else
    {
        [self showAlertActionsToAddiCloud: sender];
    }
}

-(void)showAlertActionsToAddiCloud: (id)sender
{
    NSString* title = NSLocalizedString(@"For iCloud Share", nil);
    NSString* message;
    if (self.appModel.allowPremium)
    {
        message = NSLocalizedString(@"You must have your device logged into iCloud", nil);
    }
    else
    {
        message = NSLocalizedString(@"You must have your device logged into iCloud AND Upgrade to Pro", nil);
    }
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle: NSLocalizedString(@"Go to iCloud Settings",nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [self sendUserToSystemiCloudSettings: sender];
                                   }];
    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Maybe Later",nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    [alert addAction: defaultAction];
    
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)sendUserToSystemiCloudSettings: (id)sender
{
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"prefs:root=iCloud"]];
}

-(void)showAlertActionsToShare: (id)sender
{
    NSString* title = NSLocalizedString(@"iCloud Share", nil);
    NSString* message = NSLocalizedString(@"How would you like to share the fractal?", nil);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    
    if (self.appModel.allowPremium)
    {
        UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle: NSLocalizedString(@"FractalCloud",nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
                                       {
                                           [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                           [self shareCurrentSelections: sender];
                                       }];
        [alert addAction: fractalCloud];
    }
    else if (self.appModel.userCanMakePayments)
    {
        UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle: NSLocalizedString(@"Upgrade to Share",nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
                                       {
                                           [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                           [self upgradeToProSelected: sender];
                                       }];
        [alert addAction: fractalCloud];
    }
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Maybe Later",nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    [alert addAction: defaultAction];
    
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction) shareCurrentSelections:(id)sender
{
    // check for iCloud account
    // check for discovery
    [self.appModel.cloudKitManager requestDiscoverabilityPermission:^(BOOL discoverable) {
        [self sendSelectedRecordsToTheCloud];
    }];
}

-(void)sendSelectedRecordsToTheCloud
{
    NSArray* selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
    if (selectedIndexPaths.count > 0)
    {
        
        NSMutableArray* records = [NSMutableArray arrayWithCapacity: selectedIndexPaths.count];
        
        for (NSIndexPath* path in selectedIndexPaths)
        {
            
            MDBFractalInfo* fractalInfo = self.appModel.documentController.fractalInfos[path.row];
            if (fractalInfo)
            {
                MDBFractalDocument* fractalDocument = fractalInfo.document;
                LSFractal* fractal = fractalDocument.fractal;
                
                CKRecord* record;
                record = [[CKRecord alloc] initWithRecordType: CKFractalRecordType];
                record[CKFractalRecordNameField] = fractal.name;
                record[CKFractalRecordNameInsensitiveField] = [fractal.name lowercaseString];
                record[CKFractalRecordDescriptorField] = fractal.descriptor;
                
                
                NSURL* fractalURL = [fractalDocument.fileURL URLByAppendingPathComponent: kMDBFractalFileName];
                record[CKFractalRecordFractalDefinitionAssetField] = [[CKAsset alloc] initWithFileURL: fractalURL];
                
                NSURL* thumbnailURL = [fractalDocument.fileURL URLByAppendingPathComponent: kMDBThumbnailFileName];
                record[CKFractalRecordFractalThumbnailAssetField] = [[CKAsset alloc] initWithFileURL: thumbnailURL];
                
                [records addObject: record];
                [self.collectionView deselectItemAtIndexPath: path animated: YES];
            }
        }
        
        [self.appModel.cloudKitManager savePublicRecords: records withCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Saved Records: %@; Error:%@", records, error);
            }
            [self sharingStatusAlert: nil];
        }];
        
        [self rightButtonsEnabledState: NO];
    }
}

-(void) shareToPublicCloudDocument: (MDBFractalDocument*)fractalDocument
{
    NSError* readError;
    NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc]initWithFilePresenter: fractalDocument];
    
    [fileCoordinator prepareForReadingItemsAtURLs: @[fractalDocument.fileURL]
                                          options: 0
                               writingItemsAtURLs: nil
                                          options: 0
                                            error: &readError
                                       byAccessor:^(void (^completionHandler)(void)) {
                                           //
                                           LSFractal* fractal = fractalDocument.fractal;
                                           CKRecord* record;
                                           record = [[CKRecord alloc] initWithRecordType: CKFractalRecordType];
                                           record[CKFractalRecordNameField] = fractal.name;
                                           record[CKFractalRecordNameInsensitiveField] = [fractal.name lowercaseString];
                                           record[CKFractalRecordDescriptorField] = fractal.descriptor;
                                           
                                           
                                           NSURL* fractalURL = [fractalDocument.fileURL URLByAppendingPathComponent: kMDBFractalFileName];
                                           
                                           [fileCoordinator coordinateReadingItemAtURL: fractalURL options: NSFileCoordinatorReadingForUploading error: nil byAccessor:^(NSURL *newURL) {
                                               record[CKFractalRecordFractalDefinitionAssetField] = [[CKAsset alloc] initWithFileURL: newURL];
                                           }];
                                           
                                           NSURL* thumbnailURL = [fractalDocument.fileURL URLByAppendingPathComponent: kMDBThumbnailFileName];
                                           
                                           [fileCoordinator coordinateReadingItemAtURL: thumbnailURL options: NSFileCoordinatorReadingForUploading error: nil byAccessor:^(NSURL *newURL) {
                                               record[CKFractalRecordFractalThumbnailAssetField] = [[CKAsset alloc] initWithFileURL: newURL];
                                           }];
                                           
                                           [self.appModel.cloudKitManager savePublicRecord: record withCompletionHandler:^(NSError *ckError) {
                                               //
                                               [self sharingStatusAlert: ckError];
                                           }];
                                           
                                           completionHandler();
                                       }];
    
}


-(void) sharingStatusAlert: (NSError*)error
{
    NSString* title;
    NSString* message;
    
    if (!error)
    {
        title = @"Thanks for sharing!";
    }
    else
    {
        title = error.localizedDescription;
        message = error.localizedRecoverySuggestion;
    }
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"OK",nil)
                                                            style: UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    
    [alert addAction: defaultAction];
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;

    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}


@end
