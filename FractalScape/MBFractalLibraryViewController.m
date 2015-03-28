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

#import "MDBFractalInfo.h"
#import "MDBFractalDocument.h"
#import "MDBDocumentController.h"
#import "MDBCloudManager.h"

#import "LSDrawingRuleType.h"
#import "MBColorCategory.h"
#import "MBColor.h"
#include "QuartzHelpers.h"

#import "MBAppDelegate.h"
#import "MBFractalLibraryViewController.h"
#import "MBFractalLibraryEditViewController.h"
#import "MBLSFractalEditViewController.h"
#import "MDBFractalLibraryCollectionSource.h"
#import "MDBNavConTransitionCoordinator.h"

#import "MBCollectionFractalDocumentCell.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBImmutableCellBackgroundView.h"
#import "NSString+MDBConvenience.h"


NSString *const kSupplementaryHeaderCellIdentifier = @"FractalLibraryCollectionHeader";

@interface MBFractalLibraryViewController () <MDBFractalDocumentControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate>

@property (nonatomic,strong) NSUserActivity                 *pendingUserActivity;
@property (nonatomic,readonly) NSURL                        *lastEditedURL;
@property (nonatomic,strong) MDBNavConTransitionCoordinator              *navConTransitionDelegate;

-(void) initControls;

@end

@implementation MBFractalLibraryViewController


#pragma mark - State handling
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIVisualEffectView* blurEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleExtraLight]];
    self.collectionView.backgroundView = blurEffectView;

    
    self.navConTransitionDelegate = [MDBNavConTransitionCoordinator new];
#pragma message "TODO fix transitions"
    self.navigationController.delegate = self.navConTransitionDelegate;
    
//    [self.collectionView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContentSizeCategoryDidChangeNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initControls];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.pendingUserActivity) {
        [self restoreUserActivityState: self.pendingUserActivity];
    }
    
//    if (self.lastEditedURL) {
//        [self restoreLastEditingSession];
//    }
    
    self.pendingUserActivity = nil;

//    [self.documentController resortFractalInfos];
//    [self.documentController.documentCoordinator startQuery];
//    [self.collectionView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear: animated];
//    [self.documentController.documentCoordinator stopQuery];
//    [_privateQueue cancelAllOperations];
}

- (void)viewDidUnload
{
    //    [self setMainFractalView:nil];
    //    [self setFractalCollectionView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

#pragma mark - custom getters -
- (void)setDocumentController:(MDBDocumentController *)documentController
{
    if (documentController != _documentController) {
        _documentController = documentController;
        _documentController.delegate = self;
        
        self.collectionSource.documentController = _documentController;
        //        [self.collectionView reloadData];
    }
}

-(NSURL*)lastEditedURL
{
    NSURL* selectedFractalURL;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    selectedFractalURL = [defaults URLForKey: kPrefLastEditedFractalURI];
    return selectedFractalURL;
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
        [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier sender:self];
    }];
    
//    documentMenu.modalInPopover = UIModalPresentationPopover;
    documentMenu.modalPresentationStyle = UIModalPresentationPopover;
    documentMenu.popoverPresentationController.barButtonItem = barButtonItem;
    
    [self presentViewController:documentMenu animated:YES completion:nil];
}

- (IBAction)pushToLibraryEditViewController:(id)sender
{
    UIStoryboard* storyBoard = self.storyboard;
    MBFractalLibraryEditViewController* libraryEditViewController = (MBFractalLibraryEditViewController *)[storyBoard instantiateViewControllerWithIdentifier: @"FractalEditLibrary"];
    libraryEditViewController.useLayoutToLayoutNavigationTransitions = NO; // sigabort with YES!

    id<MDBFractalDocumentCoordinator,NSCopying> oldDocumentCoordinator = self.documentController.documentCoordinator;
    id<MDBFractalDocumentCoordinator> newDocumentCoordinator = [oldDocumentCoordinator copyWithZone: nil];
    
//    MBFractalLibraryEditViewController *libraryEditViewController = (MBFractalLibraryEditViewController *)segue.destinationViewController;
    libraryEditViewController.presentingDocumentController = self.documentController;
    //        libraryEditController.collectionSource.rowCount = self.collectionSource.rowCount;
    libraryEditViewController.documentController = [[MDBDocumentController alloc]initWithDocumentCoordinator: newDocumentCoordinator sortComparator: self.documentController.sortComparator];

    [self.navigationController pushViewController: libraryEditViewController animated: NO];
}

#pragma mark - UIStoryboardSegue Handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier])
    {
        MBLSFractalEditViewController *editViewController = (MBLSFractalEditViewController *)segue.destinationViewController;
        editViewController.documentController = self.documentController;
        [editViewController configureWithNewBlankDocument];
    }
    else if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier] ||
             [segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier])
    {
        MBLSFractalEditViewController *editViewController = (MBLSFractalEditViewController *)segue.destinationViewController;
        editViewController.documentController = self.documentController;

        //editViewController.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
        //editViewController.navigationItem.leftItemsSupplementBackButton = YES;
        
        if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier])
        {
            NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
            NSIndexPath* infoIndex = [indexPaths firstObject];
            MDBFractalInfo* fractalInfo = self.documentController[infoIndex.row];
            if (fractalInfo.document)
            {
                editViewController.fractalInfo = fractalInfo;
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

- (void)documentController:(MDBDocumentController *)documentController didInsertFractalInfosAtIndexPaths:(NSArray*)indexPaths totalRows: (NSInteger)rows {
    if (indexPaths && indexPaths.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView numberOfItemsInSection: 0]; //force call to numItems
            self.collectionSource.rowCount = rows;
            [self.collectionView insertItemsAtIndexPaths: indexPaths];
        });
    }
}

- (void)documentController:(MDBDocumentController *)documentController didRemoveFractalInfosAtIndexPaths:(NSArray*)indexPaths totalRows: (NSInteger)rows {
    if (indexPaths && indexPaths.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView numberOfItemsInSection: 0]; //force call to numItems
            self.collectionSource.rowCount = rows;
            [self.collectionView deleteItemsAtIndexPaths: indexPaths];
        });
    }
}

- (void)documentController:(MDBDocumentController *)documentController didUpdateFractalInfosAtIndexPaths:(NSArray*)indexPaths totalRows: (NSInteger)rows {
    if (indexPaths && indexPaths.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView numberOfItemsInSection: 0]; //force call to numItems
            self.collectionSource.rowCount = rows;
            [self.collectionView reloadItemsAtIndexPaths: indexPaths];
        });
    }
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
    NSURL* lastEditedURL = self.lastEditedURL;
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
