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

#import <Crashlytics/Crashlytics.h>


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

-(NSString*)libraryTitle
{
    NSString* title = NSLocalizedString(@"Select to Share", @"To select an item to share to the cloud");
    
    return title;
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
        [self.appModel showAlertActionsToAddiCloud: sender onController: self];
    }
}

-(void)showAlertActionsToShare: (id)sender
{
    NSString* title = NSLocalizedString(@"iCloud Share", nil);
    NSString* message = NSLocalizedString(@"How would you like to share the fractal?", nil);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle: NSLocalizedString(@"FractalCloud",nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [Answers logCustomEventWithName: @"LibraryShare" customAttributes: @{@"Action": @"FractalCloud"}];
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [self shareCurrentSelections: sender];
                                   }];
    [alert addAction: fractalCloud];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Maybe Later",nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [Answers logCustomEventWithName: @"LibraryShare" customAttributes: @{@"Action": @"SkipShowPremiumUpgradeOption"}];
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
        
        NSMutableSet* fractalInfos = [NSMutableSet setWithCapacity: selectedIndexPaths.count];
        
        for (NSIndexPath* path in selectedIndexPaths)
        {
            
            MDBFractalInfo* fractalInfo = self.appModel.documentController.fractalInfos[path.row];
            if (fractalInfo && fractalInfo.document)
            {
                [fractalInfos addObject: fractalInfo];
            }

            [self.collectionView deselectItemAtIndexPath: path animated: YES];
        }
        
        [self.appModel pushToPublicCloudFractalInfos: [fractalInfos copy] onController: self];
        
        [self rightButtonsEnabledState: NO];
    }
}


@end
