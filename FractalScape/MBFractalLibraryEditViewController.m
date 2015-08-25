//
//  MBFractalLibraryEditViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/16/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import AssetsLibrary;

#import "MBFractalLibraryEditViewController.h"

#import "MDBAppModel.h"
#import "MDBFractalInfo.h"
#import "MDBDocumentController.h"
#import "MDBFractalDocumentCoordinator.h"
#import "MDLCloudKitManager.h"
#import "MDBCloudManager.h"

@interface MBFractalLibraryEditViewController ()

@property (nonatomic,strong) UIBarButtonItem            *shareButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem    *deleteButton;

- (IBAction)deleteCurrentSelections:(id)sender;

@end

@implementation MBFractalLibraryEditViewController

/*!
 Purposefully missing [super viewDidLoad] don't want the super class version called.
 Needs refactoring to avoid this problem.
 */
- (void)viewDidLoad
{
//    UIVisualEffectView* blurEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleExtraLight]];
//    self.collectionView.backgroundView = blurEffectView;
    
    
    _shareButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem: UIBarButtonSystemItemAction
                                                                                target: self
                                                                                action: @selector(shareButtonPressed:)];
    
    _shareButton.enabled = NO;
    
    NSMutableArray* items;
    //    [items addObject: backButton];
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace target:nil action:NULL];
    space.width = 20.0;
    
    items = [self.navigationItem.rightBarButtonItems mutableCopy];
    [items addObject: space];
    [items addObject: _shareButton];
    [self.navigationItem setRightBarButtonItems: items];

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContentSizeCategoryDidChangeNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil];
// Purposefully missing [super viewDidLoad] don't want the super class version called.
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
    self.deleteButton.enabled = state;
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

#pragma message "TODO: implement Are You Sure? alert before deleting"
- (IBAction)deleteCurrentSelections:(id)sender
{
    if (self.presentedViewController)
    {
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }

    NSArray* selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
    if (selectedIndexPaths.count > 0)
    {
        NSMutableArray* fractalInfos = [NSMutableArray arrayWithCapacity: selectedIndexPaths.count];
        
        for (NSIndexPath* path in selectedIndexPaths)
        {
            MDBFractalInfo* fractalInfo = self.appModel.documentController.fractalInfos[path.row];
            if (fractalInfo)
            {
                [fractalInfos addObject: fractalInfo];
            }
        }
        
        NSString* message = [NSString stringWithFormat: @"Are you sure you want to delete %lu fractal(s)?", (unsigned long)fractalInfos.count];
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Delete?"
                                                                       message: message
                                                                preferredStyle: UIAlertControllerStyleAlert];
        
        UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction * action)
                                        {
                                            [self performDeletionOfSelectedItems: fractalInfos];
                                        }];
        [alert addAction: deleteAction];

        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){ }];
        [alert addAction: cancelAction];
        
        [self presentViewController: alert animated: YES completion: nil];
    }
}

-(void) performDeletionOfSelectedItems: (NSArray*)items
{
    NSMutableArray* urls = [NSMutableArray arrayWithCapacity: items.count];
    
    for (MDBFractalInfo* fractalInfo in items) {
        if ([fractalInfo isKindOfClass:[MDBFractalInfo class]]) {
            [urls addObject: fractalInfo.URL];
            [self.appModel.documentController removeFractalInfo: fractalInfo];
        }
    }
    // removal notifications go to the current controller, needs to pass the changes back to the presentingView documentController
//    MDBDocumentController* strongRefController = self.presentingDocumentController;
//    if (strongRefController)
//    {
//        [strongRefController documentCoordinatorDidUpdateContentsWithInsertedURLs: nil removedURLs: urls updatedURLs: nil];
//    }
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
    
    //    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Go to iCloud Settings" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [self sendUserToSystemiCloudSettings: sender];
                                   }];
    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Maybe Later" style:UIAlertActionStyleCancel
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
    
    //    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    if (self.appModel.allowPremium)
    {
        UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"FractalCloud" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
                                       {
                                           [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                           [self shareCurrentSelections: sender];
                                       }];
        [alert addAction: fractalCloud];
    }
    else
    {
        UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Upgrade to Share" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
                                       {
                                           [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                           [self upgradeToProSelected: sender];
                                       }];
        [alert addAction: fractalCloud];
    }
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Maybe Later" style:UIAlertActionStyleCancel
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

-(IBAction) upgradeToProSelected:(id)sender
{
    
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
    //
    
    //        }
    //        else
    //        {
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
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style: UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    
    [alert addAction: defaultAction];
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
//    ppc.barButtonItem = sender;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (IBAction)editingIsDoneButton:(id)sender
{
    self.appModel = nil;
    [self.navigationController popViewControllerAnimated: NO];
}


@end
