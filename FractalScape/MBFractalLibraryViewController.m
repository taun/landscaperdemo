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

#import <Crashlytics/Crashlytics.h>

NSString *const kSupplementaryHeaderCellIdentifier = @"FractalLibraryCollectionHeader";


@interface MBFractalLibraryViewController () <MDBFractalDocumentControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate>

@property (nonatomic,strong) NSUserActivity                         *pendingUserActivity;
@property (nonatomic,strong) MDBNavConTransitionCoordinator         *navConTransitionDelegate;
/*!
 Used to make sure queries and loads aren't done twice. Once when properties change and once when the view appears.
 */
@property (nonatomic,assign) BOOL                                   isAppeared;

@end

@implementation MBFractalLibraryViewController


#pragma mark - State handling
- (void)viewDidLoad
{
    _isAppeared = NO;
    
    [super viewDidLoad];
    
    if ([self isMemberOfClass: [MBFractalLibraryViewController class]])
    {
        // only use this transition for base class
        self.navConTransitionDelegate = [MDBNavConTransitionCoordinator new];
        
        self.navigationController.delegate = self.navConTransitionDelegate;
        self.popTransition = [MDBZoomPopBounceTransition new];
        self.pushTransition = [MDBZoomPushBounceTransition new];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    _isAppeared = NO;
    
    [super viewWillAppear:animated];
    
    [Answers logContentViewWithName: NSStringFromClass([self class]) contentType: @"FractalDocuments" contentId: NSStringFromClass([self class]) customAttributes: nil];
    
    [self.appModel setupUserStoragePreferences];
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContentSizeCategoryDidChangeNotification:) name: UIContentSizeCategoryDidChangeNotification object: nil];
}

/*!
 AppModel not set until viewDidAppear
 
 @param animated 
 */
-(void)viewDidAppear:(BOOL)animated
{
    _isAppeared = NO;
    
    [super viewDidAppear:animated];

    if (self.pendingUserActivity) {
        [self restoreUserActivityState: self.pendingUserActivity];
    }
    
    self.pendingUserActivity = nil;
    
    self.addDocumentButton.enabled = self.appModel.allowPremium || self.appModel.userCanMakePayments;
    
    [self.appModel.documentController.documentCoordinator startQuery];
    
    _isAppeared = YES;

//    [self.collectionView reloadData];
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
//        MBLSFractalEditViewController* editor = (MBLSFractalEditViewController*)sourceViewController;
//        [editor setFractalInfo: nil];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: UIContentSizeCategoryDidChangeNotification object: nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
//    NSArray* visibleCells = self.collectionView.visibleCells;
//    for (MBCollectionFractalDocumentCell* cell in visibleCells)
//    {
//        [cell purgeImage];
//    }
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

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        [self.collectionViewLayout invalidateLayout];
    }];
}

#pragma mark - Notifications

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    [self.view setNeedsLayout];
}

#pragma mark - custom getters -
-(void)setAppModel:(MDBAppModel *)appModel
{
    if (_appModel != appModel)
    {
        [self removeAppModelObservers];
        _appModel = appModel;
        [self addAppModelObservers];
    }
}
-(void)addAppModelObservers{
    if (_appModel)
    {
        [_appModel addObserver: self forKeyPath: @"documentController" options: NSKeyValueObservingOptionOld context: NULL];
        if (_appModel.documentController) {
            [self documentControllerChanged];
        }
    }

}
-(void)removeAppModelObservers
{
    if (_appModel)
    {
        [_appModel removeObserver: self forKeyPath: @"documentController"];
        if (_appModel.documentController)
        {
            [self removeDocumentControllerObserversFor: _appModel.documentController];
        }
    }
}
-(void)addDocumentControllerObservers
{
    if (_appModel.documentController)
    {
        [_appModel.documentController addObserver: self forKeyPath: @"fractalInfos" options: 0 context: NULL];
    }
}
-(void)removeDocumentControllerObserversFor: (MDBDocumentController*)oldController
{
    if (oldController && oldController != [NSNull null])
    {
        [oldController removeObserver: self forKeyPath: @"fractalInfos"];
    }
}

-(void)dealloc
{
    if (_appModel)
    {
        // trigger observer removal
        [self setAppModel: nil];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString: @"documentController"]) {
        MDBDocumentController* oldController = change[NSKeyValueChangeOldKey];
        if (oldController && oldController != [NSNull null])
        {
            [self removeDocumentControllerObserversFor: oldController];
        }
        [self documentControllerChanged];
    }
    else if ([keyPath isEqualToString: @"fractalInfos"])
    {
        NSNumber *changeKind = change[NSKeyValueChangeKindKey];
        NSIndexSet *changes = change[NSKeyValueChangeIndexesKey];
        
        NSMutableArray* indexPaths = [NSMutableArray array];
        
        [changes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [indexPaths addObject: [NSIndexPath indexPathForRow: idx inSection: 0]];
        }];
        
        NSInteger currentItems;// = [self.collectionView numberOfItemsInSection: 0];
        NSUInteger changeCount = indexPaths.count;
        
        @try {
            if ([changeKind longValue] == NSKeyValueChangeInsertion) {
                //
//                [self.collectionView reloadItemsAtIndexPaths: indexPaths];
                [self.collectionView insertItemsAtIndexPaths: indexPaths];
                [self.collectionView scrollToItemAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0] atScrollPosition: UICollectionViewScrollPositionTop animated: YES];
            }
            else if ([changeKind longValue] == NSKeyValueChangeRemoval)
            {
                [self.collectionView deleteItemsAtIndexPaths: indexPaths];
            }
            else if ([changeKind longValue] == NSKeyValueChangeReplacement)
            {
#pragma message "TODO: need to separate status updates due to uploading progess from actual changes"
                if ([self.collectionView cellForItemAtIndexPath: [indexPaths firstObject]]) {
                    [self.collectionView reloadItemsAtIndexPaths: indexPaths];
                }
            }
        }
        @catch (NSException *exception) {
            //
            NSLog(@"[%@ %@], %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd), exception);
            NSLog(@"[%@ %@], changeKind: %@, %ld, %lu",NSStringFromClass([self class]),NSStringFromSelector(_cmd), changeKind, (long)currentItems, (unsigned long)changeCount);
            [self.collectionView reloadData];
        }
        @finally {
            //
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)documentControllerChanged
{
    //    dispatch_async(dispatch_get_main_queue(), ^{
    [self addDocumentControllerObservers];
    self.collectionSource.documentController = self->_appModel.documentController;
    //        [self.collectionView numberOfItemsInSection: 0]; //force call to numItems
    //        [self.collectionView reloadData];
    if ([self isMemberOfClass: [MBFractalLibraryViewController class]])
    {
        // only use this title change if it is the root class.
        // let the other classes assign their own titles.
        self.navigationItem.title = [self->_appModel.documentController.documentCoordinator isMemberOfClass: [MDBFractalDocumentLocalCoordinator class]] ? @"Local Library" : @"Cloud Library";
        if (self.navigationItem.title != nil) [Answers logCustomEventWithName: @"AppSession" customAttributes: @{@"Session Type": self.navigationItem.title}];
    }
    if (_isAppeared) [self->_appModel.documentController.documentCoordinator startQuery];
    //    });
}

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
        [self showDocumentPickerWithNewFractalDocument: barButtonItem];
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
    
    NSString *newDocumentTitle = NSLocalizedString(@"New Fractal", nil);
    [documentMenu addOptionWithTitle: newDocumentTitle image: nil order: UIDocumentMenuOrderFirst handler:^{
        // Show the MBLSFractalEditViewController.
        //        [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier sender:self];
        LSFractal* newFractal = [LSFractal new];
        MDBFractalInfo* newInfo = [self.appModel.documentController createFractalInfoForFractal: newFractal withDocumentDelegate: nil];
        NSLog(@"FractalScapes new fractal info created: %@",newInfo);
        if (self.collectionView.indexPathsForVisibleItems.count > 0) {
            [self.collectionView scrollToItemAtIndexPath: [NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition: UICollectionViewScrollPositionTop animated: YES];
        }
    }];
    
    //    documentMenu.modalInPopover = UIModalPresentationPopover;
    documentMenu.modalPresentationStyle = UIModalPresentationPopover;
    documentMenu.popoverPresentationController.barButtonItem = barButtonItem;
    
    [self presentViewController:documentMenu animated:YES completion:nil];
}


#pragma mark - MDBFractalLibraryCollectionDelegate
-(void)libraryCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MBCollectionFractalDocumentCell* cell = (MBCollectionFractalDocumentCell*)[collectionView cellForItemAtIndexPath: indexPath];
    self.fractalInfoBeingEdited = self.appModel.documentController.fractalInfos[indexPath.row];
    CGRect cellFrame = cell.frame;
    CGRect cellSquareFrame = CGRectMake(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.width);
    self.transitionSourceRect = [self.collectionView.window convertRect: cellSquareFrame fromView: self.collectionView];
    [self performSegueWithIdentifier: @"showFractalDocument" sender: self];
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
        libraryViewController.useLayoutToLayoutNavigationTransitions = NO; // sigabort with YES!
        libraryViewController.appModel = self.appModel;
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
        MDBFractalInfo *activityDocumentInfo = [[MDBFractalInfo alloc] initWithURL: activityURL];
        [activityDocumentInfo fetchDocumentWithCompletionHandler:^{
            //
            [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier sender: activityDocumentInfo];
        }];
    }
}

@end
