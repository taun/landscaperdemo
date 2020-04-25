//
//  MBFractalLibraryViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//
@import Foundation;
@import UIKit;
@import QuartzCore;
#include <math.h>

#import "MBFractalLibraryViewController.h"
#import "MDKUICollectionViewResizingFlowLayout.h"
#import "MDBResizingWidthFlowLayoutDelegate.h"

#import "MDBAppModel.h"
#import "MDBFractalInfo.h"
#import "MDBFractalDocument.h"
#import "MDBDocumentController.h"
#import "MDBCloudManager.h"

#import "LSDrawingRuleType.h"
#import "MBColorCategory.h"
#import "MBColor.h"
#include "QuartzHelpers.h"

#import "MBAppDelegate.h"
#import "MBFractalLibraryEditViewController.h"
#import "MBFractalLibraryShareViewController.h"
#import "MBLSFractalEditViewController.h"
#import "MDBFractalLibraryCollectionSource.h"
#import "MDBNavConTransitionCoordinator.h"
#import "MDBCustomTransition.h"
#import "MDBFractalDocumentLocalCoordinator.h"

#import "MBCollectionFractalDocumentCell.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBImmutableCellBackgroundView.h"
#import "NSString+MDKConvenience.h"
#import "MDBPurchaseViewController.h"
#import "FBKVOController.h"
#import "MDBURLPlusMetaData.h"


NSString *const kSupplementaryHeaderCellIdentifier = @"FractalLibraryCollectionHeader";


@interface MBFractalLibraryViewController () <MDBFractalDocumentControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate>

@property (nonatomic,strong) NSUserActivity                         *pendingUserActivity;
@property (nonatomic,strong) MDBNavConTransitionCoordinator         *navConTransitionDelegate;
@property (nonatomic,strong,readonly) FBKVOController               *kvoController;
@property (nonatomic,assign) CGSize                                 baseCellSize;

@end

@implementation MBFractalLibraryViewController

@synthesize kvoController = _kvoController;

-(void)regularStartupSequence
{
    
}

#pragma mark - State handling
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self isMemberOfClass: [MBFractalLibraryViewController class]])
    {
        // only use this transition for base class
        self.navConTransitionDelegate = [MDBNavConTransitionCoordinator new];
        
        self.navigationController.delegate = self.navConTransitionDelegate;
        self.popTransition = [MDBZoomPopBounceTransition new];
        self.pushTransition = [MDBZoomPushBounceTransition new];
    }

    if ([UICollectionView instancesRespondToSelector: @selector(prefetchDataSource)])
    {
        self.collectionView.prefetchingEnabled = YES;
        self.collectionView.prefetchDataSource = self.collectionSource;
    }
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    self.baseCellSize = CGSizeMake(layout.itemSize.width, layout.itemSize.height);
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContentSizeCategoryDidChangeNotification:) name: UIContentSizeCategoryDidChangeNotification object: nil];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

/*!
 AppModel not set until viewDidAppear
 
 @param animated 
 */
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.pendingUserActivity) {
        [self restoreUserActivityState: self.pendingUserActivity];
    }
    
    self.pendingUserActivity = nil;
    
    self.addDocumentButton.enabled = self.appModel.allowPremium || self.appModel.userCanMakePayments;
}

- (IBAction)unwindFromWelcome:(UIStoryboardSegue *)segue
{
    UIViewController* sourceController = (UIViewController*)segue.sourceViewController;
    
    // This is necessary due to presentation being over full context, popover style
    [sourceController.presentingViewController dismissViewControllerAnimated: YES completion:^{
        [self.appModel exitWelcomeState];
    }];
}

- (IBAction)unwindFromLibraryEditController:(UIStoryboardSegue*)segue
{
    
}

-(void)unwindFromPurchaseController:(UIStoryboardSegue *)segue
{
    UIViewController* sourceController = (UIViewController*)segue.sourceViewController;
    
    // This is necessary due to presentation being over full context, popover style
    [sourceController.presentingViewController dismissViewControllerAnimated: YES completion:^{

    }];
}

-(void)unwindFromEditor:(UIStoryboardSegue *)segue
{
    UIViewController *sourceViewController = segue.sourceViewController;
    if ([sourceViewController isKindOfClass: [MBLSFractalEditViewController class]])
    { // which it always should be
        
        MBLSFractalEditViewController* editor = (MBLSFractalEditViewController*)sourceViewController;
        id<MDBFractaDocumentProtocol> tempDocument = editor.fractalInfo.document;
        editor.fractalInfo = nil;
        
        [tempDocument closeWithCompletionHandler:^(BOOL success) {
            //
            NSLog(@"Fractal Closed");
            NSUInteger index = [[self.appModel.documentController fractalInfos] indexOfObject: editor.fractalInfo];
            
            [self.collectionView reloadItemsAtIndexPaths: @[[NSIndexPath indexPathForItem: index inSection: 0]]];
        }];

//        [editor setFractalInfo: nil];
    }
}

-(void)pushToLibraryEditViewController:(id)sender {
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: UIContentSizeCategoryDidChangeNotification object: nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Notifications

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    [self.view setNeedsLayout];
}

#pragma mark - custom getters -

-(FBKVOController *)kvoController
{
    if (!_kvoController)
    {
        _kvoController = [FBKVOController controllerWithObserver: self];
    }
    return _kvoController;
}

-(void)setAppModel:(MDBAppModel *)appModel
{
    if (_appModel != appModel)
    {
        if (_appModel.documentController)  [self.kvoController unobserve: _appModel.documentController];
        if (_appModel) [self.kvoController unobserve: _appModel];
        
        _appModel = appModel;

        [self.kvoController observe: _appModel
                            keyPath: @"documentController"
                            options: NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                             action: @selector(propertyAppDocumentControllerDidChange:object:)];
    }
}

-(void) propertyAppDocumentControllerDidChange: (NSDictionary*)change object: (id)object
{
    id oldController = change[NSKeyValueChangeOldKey];
    id newController = change[NSKeyValueChangeNewKey];
    
    if (oldController != nil && oldController != [NSNull null])
    {
        [self.kvoController unobserve: oldController];
    }
    
    if (newController != nil && newController != [NSNull null])
    {
        [self.collectionSource.sourceInfos  removeAllObjects];
        
        [self.kvoController observe: newController
                            keyPath: @"fractalInfos"
                            options: 0
                             action: @selector(propertyDocumentControllerInfosDidChange:object:)];
        
        [self.kvoController observe: newController
                            keyPath: @"documentCoordinator"
                            options: NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                             action: @selector(propertyAppDocumentCoordinatorDidChange:object:)];
    }
}

-(void) propertyAppDocumentCoordinatorDidChange: (NSDictionary*)change object: (id)object
{
    id oldCoordinator = change[NSKeyValueChangeOldKey];
    id newCoordinator = change[NSKeyValueChangeNewKey];
    
    if (oldCoordinator != nil && oldCoordinator != [NSNull null])
    {
        [self.kvoController unobserve: oldCoordinator];
        [oldCoordinator stopQuery];
    }
    
    if (newCoordinator != nil && newCoordinator != [NSNull null])
    {
        NSString* title = [self libraryTitle];
        if (title != nil)
        {
            self.navigationItem.title = title;
        }
        
        if ((YES))
        {
            [self.collectionView reloadData];
            [self->_appModel.documentController.documentCoordinator startQuery];
        }
    }
}

-(NSString*)libraryTitle
{
    NSString* title = [self->_appModel.documentController.documentCoordinator isMemberOfClass: [MDBFractalDocumentLocalCoordinator class]] ? @"Local Library" : @"Cloud Library";
    
    return title;
}

-(void) propertyDocumentControllerInfosDidChange: (NSDictionary*)change object: (id)object
{
    NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
    NSIndexSet *changes = change[NSKeyValueChangeIndexesKey];
    
    NSMutableArray* indexPaths = [NSMutableArray array];
    
    [changes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject: [NSIndexPath indexPathForRow: idx inSection: 0]];
    }];
    
//    NSInteger currentItems;// = [self.collectionView numberOfItemsInSection: 0];
    NSUInteger changeCount = indexPaths.count;
    
    @try {
        if (changeKind == NSKeyValueChangeInsertion) {
            //
            //                [self.collectionView reloadItemsAtIndexPaths: indexPaths];
            [self.collectionView performBatchUpdates:^{
                NSArray* infoSource = self.appModel.documentController.fractalInfos;
                MDBFractalLibraryCollectionSource* source = (MDBFractalLibraryCollectionSource*)self.collectionView.dataSource;
                NSMutableArray* infoDestination = source.sourceInfos;
                
                [infoDestination insertObjects: [infoSource objectsAtIndexes: changes] atIndexes: changes];
                
                [self.collectionView insertItemsAtIndexPaths: indexPaths];
            } completion:^(BOOL finished) {
                NSIndexPath* firstPath = [indexPaths firstObject];
                if (firstPath && firstPath.row == 0)
                {
                    [self.collectionView scrollToItemAtIndexPath: firstPath atScrollPosition: UICollectionViewScrollPositionTop animated: YES];
                }
            }];
        }
        else if (changeKind == NSKeyValueChangeRemoval)
        {
            [self.collectionView performBatchUpdates:^{
                MDBFractalLibraryCollectionSource* source = (MDBFractalLibraryCollectionSource*)self.collectionView.dataSource;
                NSMutableArray* infoDestination = source.sourceInfos;
                
                [infoDestination removeObjectsAtIndexes: changes];
                
                [self.collectionView deleteItemsAtIndexPaths: indexPaths];
            } completion:^(BOOL finished) {
                //
            }];
        }
        else if (changeKind == NSKeyValueChangeReplacement)
        {
            if ([self.collectionView cellForItemAtIndexPath: [indexPaths firstObject]])
            {
                [self.collectionView performBatchUpdates:^{
                    NSArray* infoSource = self.appModel.documentController.fractalInfos;
                    MDBFractalLibraryCollectionSource* source = (MDBFractalLibraryCollectionSource*)self.collectionView.dataSource;
                    NSMutableArray* infoDestination = source.sourceInfos;
                    
                    [infoDestination replaceObjectsAtIndexes: changes withObjects: [infoSource objectsAtIndexes: changes]];
                    
                    [self.collectionView reloadItemsAtIndexPaths: indexPaths];
                } completion:^(BOOL finished) {
                    //
                }];
            }
        }
    }
    @catch (NSException *exception) {
        //
        NSLog(@"[%@ %@], %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd), exception);
        NSLog(@"[%@ %@], changeKind: %lu count: %lu",NSStringFromClass([self class]),NSStringFromSelector(_cmd), (unsigned long)changeKind, (unsigned long)changeCount);
        [self.collectionView reloadData];
    }
    @finally {
        //
    }
}

//-(void)dealloc
//{
//    if (_appModel)
//    {
//        // trigger observer removal
//        [self setAppModel: nil];
//    }
//}


#pragma mark - IBActions

/*!
 * Note that the document picker requires that code signing, entitlements, and provisioning for
 * the project have been configured before you run Lister. If you run the app without configuring
 * entitlements correctly, an exception when this method is invoked (i.e. when the "+" button is
 * clicked).
 */
- (IBAction)newDocumentButtonTapped:(UIBarButtonItem *)barButtonItem
{
    if (self.appModel.allowPremium)
    {
        BOOL iCloudDriveEnabled = NO;
        if (iCloudDriveEnabled)
        {
            [self showDocumentPickerWithNewFractalDocument: barButtonItem];
        }
        else
        {
            [self createAndScrollToNewFractal];
        }
    }
    else
    {
        [self showUpgradeAlert: barButtonItem];
    }
}

-(void)showUpgradeAlert:(UIBarButtonItem*)barButtonItem
{
    NSString* title = NSLocalizedString(@"New Fractal", nil);
    NSString* message = NSLocalizedString(@"When editing, you can copy a sample fractal to make a new fractal. Upgrade required for new rules.", nil);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    UIAlertController* __weak weakAlert = alert;
    
    //    ALAuthorizationStatus cameraAuthStatus = [ALAssetsLibrary authorizationStatus];
    UIAlertAction* fractalCloud = [UIAlertAction actionWithTitle:@"Upgrade to create a new Fractal" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                       [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                       [self upgradeToProSelected: barButtonItem];
                                   }];
    [alert addAction: fractalCloud];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Maybe Later" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated:YES completion:nil]; // because of popover mode
                                    }];
    [alert addAction: defaultAction];
    
    UIPopoverPresentationController* ppc = alert.popoverPresentationController;
    ppc.barButtonItem = barButtonItem;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}
-(IBAction) upgradeToProSelected:(id)sender
{
    [self performSegueWithIdentifier: @"ShowPurchaseControllerSegue" sender: nil];
}
-(void)showDocumentPickerWithNewFractalDocument:(UIBarButtonItem*)barButtonItem
{
    UIDocumentMenuViewController *documentMenu = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[kMDBFractalDocumentFileUTI] inMode: UIDocumentPickerModeImport];
    documentMenu.delegate = self;
    
    MBFractalLibraryViewController* __weak weakSelf = self;
    
    NSString *newDocumentTitle = NSLocalizedString(@"New Fractal", nil);
    [documentMenu addOptionWithTitle: newDocumentTitle image: nil order: UIDocumentMenuOrderFirst handler:^{
        [weakSelf createAndScrollToNewFractal];
    }];
    
    //    documentMenu.modalInPopover = UIModalPresentationPopover;
    documentMenu.modalPresentationStyle = UIModalPresentationPopover;
    documentMenu.popoverPresentationController.barButtonItem = barButtonItem;
    
    [self presentViewController:documentMenu animated:YES completion:nil];
}

-(void)createAndScrollToNewFractal
{
    // Show the MBLSFractalEditViewController.
    //        [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier sender:self];
    LSFractal* newFractal = [LSFractal new];
    MDBFractalInfo* newInfo = [self.appModel.documentController createFractalInfoForFractal: newFractal withImage: nil withDocumentDelegate: nil];
    NSLog(@"FractalScapes new fractal info created: %@",newInfo);
    if (self.collectionView.indexPathsForVisibleItems.count > 0) {
        [self.collectionView scrollToItemAtIndexPath: [NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition: UICollectionViewScrollPositionTop animated: YES];
    }
}

#pragma mark - FlowLayoutDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Should have a test for layout type
//    NSLog(@"FlowDelegate %s", __PRETTY_FUNCTION__);
    return [MDBResizingWidthFlowLayoutDelegate collectionView: collectionView layout: collectionViewLayout sizeForItemAtIndexPath: indexPath withBaseSize: self.baseCellSize];
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    //    MBCollectionFractalDocumentCell* fractalDocCell = (MBCollectionFractalDocumentCell*)cell;
    //    MDBFractalDocument* document = (MDBFractalDocument*)fractalDocCell.document;
    //    UIDocumentState docState = document.documentState;
    
    //    if (docState != UIDocumentStateClosed)
    //    {
    //        [document closeWithCompletionHandler:^(BOOL success) {
    //            //
    //        }];;
    //    }
    //    [fractalInfo unCacheDocument]; //should release the document and thumbnail from memory.
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self libraryCollectionView: collectionView shouldSelectItemAtIndexPath: indexPath];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Depends on viewController being nil for the LibraryEdit instance of the dataSource. Meaning the following does nothing in that case.
    [self libraryCollectionView: collectionView didSelectItemAtIndexPath: indexPath];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self libraryCollectionView: collectionView didDeselectItemAtIndexPath: indexPath];
}

#pragma mark - MDBFractalLibraryCollectionDelegate
-(BOOL)libraryCollectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MBCollectionFractalDocumentCell* cell = (MBCollectionFractalDocumentCell*)[collectionView cellForItemAtIndexPath: indexPath];
    return !cell.info.isDownloading;
}

-(void)libraryCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MBCollectionFractalDocumentCell* cell = (MBCollectionFractalDocumentCell*)[collectionView cellForItemAtIndexPath: indexPath];
    self.fractalInfoBeingEdited = self.appModel.documentController.fractalInfos[indexPath.row];
    CGRect cellFrame = cell.frame;
    CGRect cellSquareFrame = CGRectMake(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.width);
    self.transitionSourceRect = [self.collectionView.window convertRect: cellSquareFrame fromView: self.collectionView];
    [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier sender: self];
    [self.collectionView deselectItemAtIndexPath: indexPath animated: YES];
}

-(void)libraryCollectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - UIStoryboardSegue Handling

-(CGRect)transitionDestinationRect
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow: [self.appModel.documentController.fractalInfos indexOfObject: self.fractalInfoBeingEdited] inSection: 0];
    MBCollectionFractalDocumentCell* cell = (MBCollectionFractalDocumentCell*)[self.collectionView cellForItemAtIndexPath: indexPath];
    CGRect cellSquareFrame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.width);
    CGRect cellRect = [self.collectionView.window convertRect: cellSquareFrame fromView: self.collectionView];
    return cellRect;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier])
//    {
//        MBLSFractalEditViewController *editViewController = (MBLSFractalEditViewController *)segue.destinationViewController;
//        editViewController.documentController = self.documentController;
//        [editViewController configureWithNewBlankDocument];
//    }
//    else
    
    if (self.presentedViewController)
    {
        [self dismissViewControllerAnimated: YES completion: nil];
    }
    
    if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier] ||
        [segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier])
    {
        MBLSFractalEditViewController *editViewController = (MBLSFractalEditViewController *)segue.destinationViewController;
        editViewController.appModel = self.appModel;
        editViewController.libraryViewController = self;

        //editViewController.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
        //editViewController.navigationItem.leftItemsSupplementBackButton = YES;
        
        if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier])
        {
            NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
            NSIndexPath* infoIndex = [indexPaths firstObject];
            MDBFractalInfo* fractalInfo = self.appModel.documentController.fractalInfos[infoIndex.row];
            if (fractalInfo.document)
            {
                [editViewController setFractalInfo: fractalInfo andShowCopiedAlert: NO];
            }
        }
        else if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier])
        {
            MDBFractalInfo *userActivityDocumentInfo = sender;
            editViewController.fractalInfo = userActivityDocumentInfo;
        }
    }
    else if ([segue.identifier isEqualToString: @"showEditFractalDocumentsList"] || [segue.identifier isEqualToString: @"showShareFractalDocumentsList"])
    {
        MBFractalLibraryViewController* libraryViewController = (MBFractalLibraryViewController *)segue.destinationViewController;
        libraryViewController.collectionView = (UICollectionView*)libraryViewController.view;
        libraryViewController.appModel = self.appModel;
        MDBFractalLibraryCollectionSource* dataSource = (MDBFractalLibraryCollectionSource*)libraryViewController.collectionView.dataSource;
        MDBFractalLibraryCollectionSource* mySource = (MDBFractalLibraryCollectionSource*)self.collectionView.dataSource;
        dataSource.sourceInfos = [mySource.sourceInfos mutableCopy];
        
        CGPoint scrollOffset = self.collectionView.contentOffset;
        libraryViewController.initialContentOffset = scrollOffset;
    }
    else if ([segue.identifier isEqualToString: @"WelcomeSegue"])
    {
        
    }
    else if ([segue.identifier isEqualToString: @"ShowPurchaseControllerSegue"])
    {
        UINavigationController* navCon = (UINavigationController*)segue.destinationViewController;
        MDBPurchaseViewController* pvc = [navCon.viewControllers firstObject];
        pvc.purchaseManager = self.appModel.purchaseManager;
    }
}

#pragma mark - UIDocumentMenuDelegate

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate = self;
    
    [self presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentMenuWasCancelled:(UIDocumentMenuViewController *)documentMenu {
    // The user cancelled interacting with the document menu. In your own app, you may want to
    // handle this with other logic.
}

#pragma mark - UIDocumentPickerViewDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    // The user selected the document and it should be picked up by the \c MDBDocumentController.
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    // The user cancelled interacting with the document picker. In your own app, you may want to
    // handle this with other logic.
}

#pragma mark - MDBDocumentControllerDelegate

- (void)documentControllerWillChangeContent:(MDBDocumentController *)documentController
{
    // this protocol replaced by using observers
}

- (void)documentControllerDidChangeContent:(MDBDocumentController *)documentController
{
    // this protocol replaced by using observers
}

- (void)documentController:(MDBDocumentController *)documentController didFailCreatingFractalInfo:(MDBFractalInfo *)fractalInfo withError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = NSLocalizedString(@"Failed to Create Document", nil);
        NSString *message = error.localizedDescription;
        NSString *okActionTitle = NSLocalizedString(@"OK", nil);
        
        UIAlertController *errorOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [errorOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:errorOutController animated:YES completion:nil];
    });
}

- (void)documentController:(MDBDocumentController *)documentController didFailRemovingFractalInfo:(MDBFractalInfo *)fractalInfo withError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = NSLocalizedString(@"Failed to Delete Document", nil);
        NSString *message = error.localizedDescription;
        NSString *okActionTitle = NSLocalizedString(@"OK", nil);
        
        UIAlertController *errorOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [errorOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:errorOutController animated:YES completion:nil];
    });
}

-(void)documentController:(MDBDocumentController *)documentController didMoveFractalInfoAtIndexPath:(NSIndexPath *)fromIndex toIndexPath:(NSIndexPath *)toIndex
{
    // this protocol replaced by using observers
}

- (void)documentController:(MDBDocumentController *)documentController didInsertFractalInfosAtIndexPaths:(NSArray *)index totalRows:(NSInteger)rows { 
    //
}


- (void)documentController:(MDBDocumentController *)documentController didRemoveFractalInfosAtIndexPaths:(NSArray *)index totalRows:(NSInteger)rows { 
    //
}


- (void)documentController:(MDBDocumentController *)documentController didUpdateFractalInfosAtIndexPaths:(NSArray *)index totalRows:(NSInteger)rows { 
    //
}


#pragma mark - UIResponder


- (void)restoreUserActivityState:(NSUserActivity *)activity {
    /**
     If there is a Fractal currently displayed; pop to the root view controller (this controller) and
     continue the activity from there. Otherwise, continue the activity directly.
     */
    if ([self.navigationController.topViewController isKindOfClass:[UINavigationController class]]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        self.pendingUserActivity = activity;
        return;
    }
    
    NSURL *activityURL = activity.userInfo[NSUserActivityDocumentURLKey];
    
    if (activityURL != nil) {
        MDBFractalInfo *activityDocumentInfo = [[MDBFractalInfo alloc] initWithURLPlusMeta: [MDBURLPlusMetaData urlPlusMetaWithFileURL: activityURL metaData: nil]];
        [activityDocumentInfo fetchDocumentWithCompletionHandler:^{
            //
            [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier sender: activityDocumentInfo];
        }];
    }
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder { 
    //
    [super encodeWithCoder: aCoder];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection { 
    //
    [super traitCollectionDidChange: previousTraitCollection];
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container { 
    //
    [super preferredContentSizeDidChangeForChildContentContainer: container];
}

- (CGSize)sizeForChildContentContainer:(nonnull id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize { 
    //
    return [super sizeForChildContentContainer: container withParentContainerSize: parentSize];
}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container { 
    //
    [super systemLayoutFittingSizeDidChangeForChildContentContainer: container];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator { 
    //
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
}

- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator { 
    //
    [super willTransitionToTraitCollection: newCollection  withTransitionCoordinator: coordinator];
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator { 
    //
    [super didUpdateFocusInContext: context withAnimationCoordinator: coordinator];
}

- (void)setNeedsFocusUpdate { 
    //
    [super setNeedsFocusUpdate];
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context { 
    //
    return [super shouldUpdateFocusInContext: context];
}

- (void)updateFocusIfNeeded { 
    //
    [super updateFocusIfNeeded];
}

@end
