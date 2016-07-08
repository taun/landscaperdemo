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

@property (weak, nonatomic) IBOutlet UIBarButtonItem    *deleteButton;

- (IBAction)deleteCurrentSelections:(id)sender;

@end

@implementation MBFractalLibraryEditViewController

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

-(void)dealloc
{
    
}

-(void) rightButtonsEnabledState: (BOOL)state
{
    self.deleteButton.enabled = state;
}


-(NSString*)libraryTitle
{
    NSString* title = NSLocalizedString(@"Select to Delete", @"To select an item to delete");
    
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
        
        NSString* localizedDelete = NSLocalizedString(@"Delete", @"Delete a file");
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle: localizedDelete
                                                                       message: message
                                                                preferredStyle: UIAlertControllerStyleAlert];
        
        UIAlertAction* deleteAction = [UIAlertAction actionWithTitle: localizedDelete
                                                               style: UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction * action)
                                        {
                                            [self performDeletionOfSelectedItems: fractalInfos];
                                        }];
        [alert addAction: deleteAction];

        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel an action") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){ }];
        [alert addAction: cancelAction];
        
        [self.navigationController presentViewController: alert animated: YES completion: nil];
    }
}

-(void) performDeletionOfSelectedItems: (NSArray*)items
{
    for (MDBFractalInfo* fractalInfo in items) {
        if ([fractalInfo isKindOfClass:[MDBFractalInfo class]]) {
            [self.appModel.documentController removeFractalInfo: fractalInfo];
        }
    }
}

@end
