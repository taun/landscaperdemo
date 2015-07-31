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
#import "MBLSFractalEditViewController.h"
#import "MDBWelcomeViewController.h"
#import "MDBFractalLibraryCollectionSource.h"
#import "MDBNavConTransitionCoordinator.h"
#import "MDBCustomTransition.h"
#import "MDBFractalDocumentLocalCoordinator.h"

#import "MBCollectionFractalDocumentCell.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBImmutableCellBackgroundView.h"
#import "NSString+MDKConvenience.h"


NSString *const kSupplementaryHeaderCellIdentifier = @"FractalLibraryCollectionHeader";


@interface MBFractalLibraryViewController () <MDBFractalDocumentControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate>

@property (nonatomic,strong) NSUserActivity                         *pendingUserActivity;
@property (nonatomic,strong) MDBNavConTransitionCoordinator         *navConTransitionDelegate;
@property (nonatomic,weak) MDBFractalInfo                           *fractalInfoBeingEdited;

-(void) initControls;

@end

@implementation MBFractalLibraryViewController


#pragma mark - State handling
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navConTransitionDelegate = [MDBNavConTransitionCoordinator new];

    self.navigationController.delegate = self.navConTransitionDelegate;
    self.popTransition = [MDBZoomPopBounceTransition new];
    self.pushTransition = [MDBZoomPushBounceTransition new];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    [self initControls];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContentSizeCategoryDidChangeNotification:) name: UIContentSizeCategoryDidChangeNotification object: nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.pendingUserActivity) {
        [self restoreUserActivityState: self.pendingUserActivity];
    }
    
    self.pendingUserActivity = nil;

//    [self.documentController resortFractalInfos];
    
    if (!self.appModel.firstLaunchState || self.appModel.welcomeDone)
    {
        /*
         need to handle getting here by change in cloud identity
         */
        [self regularStartupSequence];
    }
    else
    {
        if (self.appModel.firstLaunchState) // way to let the intro be played again without reloading the demo fractals
        {
            [self.appModel loadInitialDocuments];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self firstStartupSequence];
        });
    }
}

/*
 firstLaunch, we want to
 load initialDocuments
 raise an intro modal
 set cloud state.
 */
-(void)firstStartupSequence
{
    UIStoryboard* storyBoard = self.storyboard;
    MDBWelcomeViewController* welcomeController = (MDBWelcomeViewController *)[storyBoard instantiateViewControllerWithIdentifier: @"WelcomeViewController"];
    welcomeController.appModel = self.appModel;
    welcomeController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    welcomeController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController: welcomeController animated: YES completion: nil];
    
    [self regularStartupSequence];
}

-(void)regularStartupSequence
{
    [self.appModel setupUserStoragePreferences];
    [self.appModel.documentController.documentCoordinator startQuery];
    [self.collectionView reloadData];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: UIContentSizeCategoryDidChangeNotification object: nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear: animated];
    
    
//    [self.documentController.documentCoordinator stopQuery];
//    [_privateQueue cancelAllOperations];
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
-(void)updatePremiumFeaturesState
{
    if (!_appModel.allowPremium)
    {
        self.navigationItem.leftBarButtonItem.enabled = NO; // remove ability to add new fractal
    }
    else
    {
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
}
-(void)addAppModelObservers{
    if (_appModel)
    {
        [_appModel addObserver: self forKeyPath: @"allowPremium" options: NSKeyValueObservingOptionOld context: NULL];
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
        [_appModel removeObserver: self forKeyPath: @"allowPremium"];
        [_appModel removeObserver: self forKeyPath: @"documentController"];
        if (_appModel.documentController)
        {
            [self removeDocumentControllerObserversFor: _appModel.documentController];
        }
    }
}
-(void)addDocumentControllerObservers
{
    if (_appModel.documentController) {
        [_appModel.documentController addObserver: self forKeyPath: @"fractalInfos" options: 0 context: NULL];
    }
}
-(void)removeDocumentControllerObserversFor: (MDBDocumentController*)oldController
{
    if (oldController && oldController != [NSNull null]) {
        [oldController removeObserver: self forKeyPath: @"fractalInfos"];
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
    else if ([keyPath isEqualToString: @"allowPremium"])
    {
        [self updatePremiumFeaturesState];
    }
    else if ([keyPath isEqualToString: @"fractalInfos"])
    {
        NSUInteger changeKind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        NSIndexSet *changes = change[NSKeyValueChangeIndexesKey];;
        
        NSMutableArray* indexPaths = [NSMutableArray array];
        
        [changes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [indexPaths addObject: [NSIndexPath indexPathForRow: idx inSection: 0]];
        }];
        
        if (changeKind == NSKeyValueChangeInsertion) {
            //
            [self.collectionView insertItemsAtIndexPaths: indexPaths];
            [self.collectionView scrollToItemAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0] atScrollPosition: UICollectionViewScrollPositionTop animated: YES];
        }
        else if (changeKind == NSKeyValueChangeRemoval)
        {
            [self.collectionView deleteItemsAtIndexPaths: indexPaths];
        }
        else if (changeKind == NSKeyValueChangeReplacement)
        {
#pragma message "TODO: need to separate status updates due to uploading progess from actual changes"
            if ([self.collectionView cellForItemAtIndexPath: [indexPaths firstObject]]) {
                [self.collectionView reloadItemsAtIndexPaths: indexPaths];
            }
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
        self.navigationItem.title = [self->_appModel.documentController.documentCoordinator isMemberOfClass: [MDBFractalDocumentLocalCoordinator class]] ? @"Local Library" : @"Cloud Library";
        [self->_appModel.documentController.documentCoordinator startQuery];
//    });
}

#pragma mark - IBActions

/*!
 * Note that the document picker requires that code signing, entitlements, and provisioning for
 * the project have been configured before you run Lister. If you run the app without configuring
 * entitlements correctly, an exception when this method is invoked (i.e. when the "+" button is
 * clicked).
 */
- (IBAction)pickDocument:(UIBarButtonItem *)barButtonItem {
    UIDocumentMenuViewController *documentMenu = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[kMDBFractalDocumentFileUTI] inMode: UIDocumentPickerModeImport];
    documentMenu.delegate = self;
    
    NSString *newDocumentTitle = NSLocalizedString(@"New Fractal", nil);
    [documentMenu addOptionWithTitle: newDocumentTitle image: nil order: UIDocumentMenuOrderFirst handler:^{
        // Show the MBLSFractalEditViewController.
//        [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier sender:self];
        LSFractal* newFractal = [LSFractal new];
        MDBFractalInfo* newInfo = [self.appModel.documentController createFractalInfoForFractal: newFractal withDocumentDelegate: nil];
        if (self.collectionView.indexPathsForVisibleItems.count > 0) {
            [self.collectionView scrollToItemAtIndexPath: [NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition: UICollectionViewScrollPositionTop animated: YES];
        }
  }];
    
//    documentMenu.modalInPopover = UIModalPresentationPopover;
    documentMenu.modalPresentationStyle = UIModalPresentationPopover;
    documentMenu.popoverPresentationController.barButtonItem = barButtonItem;
    
    [self presentViewController:documentMenu animated:YES completion:nil];
}

- (IBAction)pushToLibraryEditViewController:(id)sender
{
    if (self.presentedViewController)
    {
        [self.presentedViewController dismissViewControllerAnimated: NO completion: nil];
    }
    
    UIStoryboard* storyBoard = self.storyboard;
    MBFractalLibraryEditViewController* libraryEditViewController = (MBFractalLibraryEditViewController *)[storyBoard instantiateViewControllerWithIdentifier: @"FractalEditLibrary"];
    libraryEditViewController.useLayoutToLayoutNavigationTransitions = NO; // sigabort with YES!
    libraryEditViewController.appModel = self.appModel;
    CGPoint scrollOffset = self.collectionView.contentOffset;
    libraryEditViewController.initialContentOffset = scrollOffset;
//    id<MDBFractalDocumentCoordinator,NSCopying> oldDocumentCoordinator = self.documentController.documentCoordinator;
//    id<MDBFractalDocumentCoordinator> newDocumentCoordinator = [oldDocumentCoordinator copyWithZone: nil];
    
//    MBFractalLibraryEditViewController *libraryEditViewController = (MBFractalLibraryEditViewController *)segue.destinationViewController;
//    libraryEditViewController.presentingDocumentController = self.documentController;
    //        libraryEditController.collectionSource.rowCount = self.collectionSource.rowCount;
//    libraryEditViewController.documentController = [[MDBDocumentController alloc]initWithDocumentCoordinator: newDocumentCoordinator sortComparator: self.documentController.sortComparator];

    [self.navigationController pushViewController: libraryEditViewController animated: NO];
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
    if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier] ||
        [segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier])
    {
        MBLSFractalEditViewController *editViewController = (MBLSFractalEditViewController *)segue.destinationViewController;
        editViewController.appModel = self.appModel;

        //editViewController.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
        //editViewController.navigationItem.leftItemsSupplementBackButton = YES;
        
        if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier])
        {
            NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
            NSIndexPath* infoIndex = [indexPaths firstObject];
            MDBFractalInfo* fractalInfo = self.appModel.documentController.fractalInfos[infoIndex.row];
            if (fractalInfo.document)
            {
                [editViewController setFractalInfo: fractalInfo andShowEditor: NO];
            }
        }
        else if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier])
        {
            MDBFractalInfo *userActivityDocumentInfo = sender;
            editViewController.fractalInfo = userActivityDocumentInfo;
        }
    }
//    else if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToEditDocumentListControllerSegueIdentifier])
//    {
//        
//        id<MDBFractalDocumentCoordinator,NSCopying> oldDocumentCoordinator = self.documentController.documentCoordinator;
//        id<MDBFractalDocumentCoordinator> newDocumentCoordinator = [oldDocumentCoordinator copyWithZone: nil];
//        
//        MBFractalLibraryEditViewController *libraryEditController = (MBFractalLibraryEditViewController *)segue.destinationViewController;
//        libraryEditController.presentingDocumentController = self.documentController;
//        libraryEditController.collectionSource.rowCount = self.collectionSource.rowCount;
//        libraryEditController.documentController = [[MDBDocumentController alloc]initWithDocumentCoordinator: newDocumentCoordinator sortComparator: self.documentController.sortComparator];
//        libraryEditController.documentController = newDocumentController;
//    }
}
///*!
// Save thumbnail, close document and clean up.
// 
// @param segue
// */
//- (IBAction)unwindToLibraryFromEditor:(UIStoryboardSegue *)segue
//{
//    [segue.sourceViewController dismissViewControllerAnimated: YES completion:^{
////        //
////        [self appearanceControllerWasDismissed];
//    }];
//}
//
//- (IBAction)unwindToLibraryFromEditMode:(UIStoryboardSegue *)segue
//{
//    [segue.sourceViewController dismissViewControllerAnimated: YES completion:^{
//        //
////        [self appearanceControllerWasDismissed];
//    }];
//}

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

- (void)documentControllerWillChangeContent:(MDBDocumentController *)documentController {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.collectionView beginUpdates];
//    });
}

- (void)documentControllerDidChangeContent:(MDBDocumentController *)documentController {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.tableView endUpdates];
//    });
}

- (void)documentController:(MDBDocumentController *)documentController didFailCreatingFractalInfo:(MDBFractalInfo *)fractalInfo withError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = NSLocalizedString(@"Failed to Create Document", nil);
        NSString *message = error.localizedDescription;
        NSString *okActionTitle = NSLocalizedString(@"OK", nil);
        
        UIAlertController *errorOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [errorOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:errorOutController animated:YES completion:nil];
    });
}

- (void)documentController:(MDBDocumentController *)documentController didFailRemovingFractalInfo:(MDBFractalInfo *)fractalInfo withError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title = NSLocalizedString(@"Failed to Delete Document", nil);
        NSString *message = error.localizedDescription;
        NSString *okActionTitle = NSLocalizedString(@"OK", nil);
        
        UIAlertController *errorOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [errorOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:errorOutController animated:YES completion:nil];
    });
}



-(void) initControls {
    // need to set current selection
    // use selectItemAtIndexPath:animated:scrollPosition:
    // need to determine index of selectedFractal
    // perhaps make part of selectedFractal setter?
    
//    [self.documentController resortFractalInfos];
}


#pragma mark - UIResponder

-(void)restoreLastEditingSession
{
    NSURL* lastEditedURL = self.appModel.lastEditedURL;
    if (lastEditedURL) {
        MDBFractalInfo *lastEditedDocumentInfo = [[MDBFractalInfo alloc] initWithURL: lastEditedURL];
        [lastEditedDocumentInfo fetchDocumentWithCompletionHandler:^{
            //
            [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier sender: lastEditedDocumentInfo];
        }];
    }
}

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
