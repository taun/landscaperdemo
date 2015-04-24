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

@interface MBFractalLibraryEditViewController ()


- (IBAction)deleteCurrentSelections:(id)sender;

@end

@implementation MBFractalLibraryEditViewController

- (void)viewDidLoad
{
//    UIVisualEffectView* blurEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleExtraLight]];
//    self.collectionView.backgroundView = blurEffectView;
    
    
    UIBarButtonItem* shareButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem: UIBarButtonSystemItemAction
                                                                                target: self
                                                                                action: @selector(shareButtonPressed:)];
    
    
    NSMutableArray* items;
    //    [items addObject: backButton];
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFixedSpace target:nil action:NULL];
    space.width = 20.0;
    
    items = [self.navigationItem.rightBarButtonItems mutableCopy];
    [items addObject: space];
    [items addObject: shareButton];
    [self.navigationItem setRightBarButtonItems: items];

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContentSizeCategoryDidChangeNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil];
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
    
    //    [self.shareActionsSheet showFromBarButtonItem: sender animated: YES];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Share"
                                                                   message: @"How would you like to share the image?"
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    
//    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Public Cloud" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [self shareCurrentSelections: sender];
                                   }];
    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
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
    NSArray* selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
    if (selectedIndexPaths.count > 0)
    {
        for (NSIndexPath* path in selectedIndexPaths)
        {
            MDBFractalInfo* fractalInfo = self.appModel.documentController.fractalInfos[path.row];
            if (fractalInfo)
            {
                [self shareToPublicCloudDocument: fractalInfo.document];
                [self.collectionView deselectItemAtIndexPath: path animated: YES];
            }
        }
    }
}

-(void) shareToPublicCloudDocument: (MDBFractalDocument*)fractalDocument
{
    NSLog(@"Unimplemented sharing to public cloud.");
    
    MDLCloudKitManager* ckManager = [MDLCloudKitManager new];
    
    //    [ckManager requestDiscoverabilityPermission:^(BOOL discoverable) {
    //
    //        if (discoverable)
    //        {
    
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
                                           record[CKFractalRecordDescriptorField] = fractal.descriptor;
                                           
                                           
                                           NSURL* fractalURL = [fractalDocument.fileURL URLByAppendingPathComponent: kMDBFractalFileName];
                                           
                                           [fileCoordinator coordinateReadingItemAtURL: fractalURL options: NSFileCoordinatorReadingForUploading error: nil byAccessor:^(NSURL *newURL) {
                                               record[CKFractalRecordFractalDefinitionAssetField] = [[CKAsset alloc] initWithFileURL: newURL];
                                           }];
                                           
                                           NSURL* thumbnailURL = [fractalDocument.fileURL URLByAppendingPathComponent: kMDBThumbnailFileName];
                                           
                                           [fileCoordinator coordinateReadingItemAtURL: thumbnailURL options: NSFileCoordinatorReadingForUploading error: nil byAccessor:^(NSURL *newURL) {
                                               record[CKFractalRecordFractalThumbnailAssetField] = [[CKAsset alloc] initWithFileURL: newURL];
                                           }];
                                           
                                           [ckManager savePublicRecord: record withCompletionHandler:^(NSError *ckError) {
                                               //
                                               
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

- (IBAction)editingIsDoneButton:(id)sender
{
    [self.navigationController popViewControllerAnimated: NO];
}
@end
