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

#import "MBCollectionFractalCell.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBImmutableCellBackgroundView.h"
#import "NSString+MDBConvenience.h"


static NSString *kSupplementaryHeaderCellIdentifier = @"FractalLibraryCollectionHeader";

@interface MBFractalLibraryViewController () <FractalControllerProtocol, FractalControllerDelegate, MDBFractalDocumentControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate>
{
    CGSize _cachedThumbnailSize;
}

@property (nonatomic,strong) NSUserActivity                 *pendingUserActivity;

@property (nonatomic,strong) UIImage                        *cachedPlaceholderImage;

-(void) initControls;
-(CGSize) cachedThumbnailSizeForCell: (MBCollectionFractalCell*) cell;
-(UIImage*) placeHolderImageSized: (CGSize)size background: (UIColor*) color;

@end

@implementation MBFractalLibraryViewController


#pragma mark - State handling
- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    UIVisualEffectView* blurEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleLight]];
//    self.collectionView.backgroundView = blurEffectView;
    
    [self.collectionView reloadData];
    
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
        [self restoreUserActivityState:self.pendingUserActivity];
    }
    
    self.pendingUserActivity = nil;

    [self.collectionView reloadData];
    /*!
     With the cell images being set in the background, the selectItemIndexPath:... may be called too soon.
     We call it again in cell background operation of cellForItemAtIndexPath:.
     */
#pragma message "TODO uidocument fix"
//    NSIndexPath* selectIndex = [self.fetchedResultsController indexPathForObject: self.selectedFractal];
//    [self.collectionView selectItemAtIndexPath: selectIndex animated: animated scrollPosition: UICollectionViewScrollPositionCenteredVertically];
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear: animated];
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

#pragma mark - UIStoryboardSegue Handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier])
    {
        UINavigationController* navCon = (UINavigationController *)segue.destinationViewController;
        MBLSFractalEditViewController *newDocumentController = (MBLSFractalEditViewController *)navCon.topViewController;
        newDocumentController.documentController = self.documentController;
        
        [newDocumentController configureWithNewBlankDocument];
    }
    else if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier] ||
             [segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier])
    {
        UINavigationController* navCon = (UINavigationController *)segue.destinationViewController;
        MBLSFractalEditViewController *editViewController = (MBLSFractalEditViewController *)navCon.topViewController;
        editViewController.documentController = self.documentController;
        
        //editViewController.navigationItem.leftBarButtonItem = [self.splitViewController displayModeButtonItem];
        //editViewController.navigationItem.leftItemsSupplementBackButton = YES;
        
        if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier])
        {
            NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
            NSIndexPath* infoIndex = [indexPaths firstObject];
            MDBFractalInfo* fractalInfo = self.documentController[infoIndex.row];
            if (fractalInfo)
            {
                [editViewController configureWithFractalInfo: fractalInfo];
            }
        }
        else if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier])
        {
            MDBFractalInfo *userActivityDocumentInfo = sender;
            [editViewController configureWithFractalInfo: userActivityDocumentInfo];
        }
    }
    else if ([segue.identifier isEqualToString: kMDBAppDelegateMainStoryboardDocumentsViewControllerToEditDocumentListControllerSegueIdentifier])
    {
        UINavigationController* navCon = (UINavigationController *)segue.destinationViewController;
        MBFractalLibraryEditViewController *newDocumentController = (MBFractalLibraryEditViewController *)navCon.topViewController;
        newDocumentController.documentController = self.documentController;
    }
}
/*!
 Save thumbnail, close document and clean up.
 
 @param segue
 */
- (IBAction)unwindToLibraryFromEditor:(UIStoryboardSegue *)segue
{
    [segue.sourceViewController dismissViewControllerAnimated: YES completion:^{
//        //
//        [self appearanceControllerWasDismissed];
    }];
}

- (IBAction)unwindToLibraryFromEdit:(UIStoryboardSegue *)segue
{
    [segue.sourceViewController dismissViewControllerAnimated: YES completion:^{
        //
//        [self appearanceControllerWasDismissed];
    }];
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
    [documentMenu addOptionWithTitle: newDocumentTitle image:nil order: UIDocumentMenuOrderFirst handler:^{
        // Show the AAPLNewListDocumentController.
        [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier sender:self];
    }];
    
    documentMenu.modalInPopover = UIModalPresentationPopover;
    documentMenu.popoverPresentationController.barButtonItem = barButtonItem;
    
    [self presentViewController:documentMenu animated:YES completion:nil];
}
#pragma mark - UIPickerViewDelegate

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

- (void)documentController:(MDBDocumentController *)documentController didInsertFractalInfo:(MDBFractalInfo *)fractalInfo atIndex:(NSInteger)index {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.collectionView reloadData];
        // doesn't work due to items being added to controller faster than this is called.
//        [self.collectionView insertItemsAtIndexPaths: @[indexPath]];
    });
}

- (void)documentController:(MDBDocumentController *)documentController didremoveFractalInfo:(MDBFractalInfo *)fractalInfo atIndex:(NSInteger)index {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        [self.collectionView deleteItemsAtIndexPaths: @[indexPath]];
    });
}

- (void)documentController:(MDBDocumentController *)documentController didUpdateFractalInfo:(MDBFractalInfo *)fractalInfo atIndex:(NSInteger)index {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        MBCollectionFractalCell* documentInfoCell = (MBCollectionFractalCell*)[self.collectionView cellForItemAtIndexPath: indexPath];

        documentInfoCell.fractalInfo = fractalInfo;
        
        [fractalInfo fetchInfoWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // Make sure that the list info is still visible once the color has been fetched.
                if ([self.collectionView.indexPathsForVisibleItems containsObject: indexPath]) {
                    documentInfoCell.fractalInfo = fractalInfo;
                }
            });
        }];
    });
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
}

#pragma mark - custom getters -
- (void)setDocumentController:(MDBDocumentController *)documentController
{
    if (documentController != _documentController) {
        _documentController = documentController;
        _documentController.delegate = self;
    }
}

#pragma message "TODO: uidocument fix needed"
//-(NSFetchedResultsController*) fetchedResultsController {
//    if (self.fractal != nil && _fetchedResultsController == nil) {
//        // instantiate
//        _selectedFractal = self.fractal;
//        
//        
//        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
//        NSEntityDescription* entity = [LSFractal entityDescriptionForContext: fractalContext];
//        [fetchRequest setEntity: entity];
//        [fetchRequest setFetchBatchSize: 20];
//        NSSortDescriptor* nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
//        NSSortDescriptor* catSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"category" ascending: YES];
//        NSArray* sortDescriptors = @[catSortDescriptor, nameSortDescriptor];
//        [fetchRequest setSortDescriptors: sortDescriptors];
//        
//        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: fractalContext sectionNameKeyPath: @"category" cacheName: nil];
//
//        _fetchedResultsController.delegate = self;
//        
//        NSError* error = nil;
//        
//        if (![_fetchedResultsController performFetch: &error]) {
//            NSLog(@"Fetched Results Error %@, %@", error, [error userInfo]);
//            abort();
//        }
//    }
//    
//    return _fetchedResultsController;
//}

#pragma mark - UIResponder

- (void)restoreUserActivityState:(NSUserActivity *)activity {
    /**
     If there is a list currently displayed; pop to the root view controller (this controller) and
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
        
        NSString *fractalInfoIdentifier = activity.userInfo[kMDBCloudManagerUserActivityFractalIdentifierUserInfoKey];
        //        activityDocumentInfo.name = fractalInfoName;
        
        [self performSegueWithIdentifier: kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier sender:activityDocumentInfo];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#pragma message "TODO: uidocument fix needed"
//    return [[self.fetchedResultsController sections] count];
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)table numberOfItemsInSection:(NSInteger)section {
#pragma message "TODO: uidocument fix needed"
//    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
//    return [sectionInfo numberOfObjects];
    return self.documentController ? self.documentController.count : 0;
}

-(UIImage*) placeHolderImageSized: (CGSize)size background: (UIColor*) uiColor {
    if (self.cachedPlaceholderImage && CGSizeEqualToSize(self.cachedPlaceholderImage.size, size)) {
        return self.cachedPlaceholderImage;
    } else {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(context);
        [uiColor setFill];
        CGContextFillRect(context, viewRect);
        CGContextRestoreGState(context);
        
        UIImage* thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.cachedPlaceholderImage = thumbnail;
        return thumbnail;
    }
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FractalLibraryListCell";
    return [collectionView dequeueReusableCellWithReuseIdentifier: CellIdentifier forIndexPath: indexPath];
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert([cell isKindOfClass:[MBCollectionFractalCell class]]);
    MBCollectionFractalCell *documentInfoCell = (MBCollectionFractalCell *)cell;

#pragma message "TODO: uidocument fix needed"
    
//    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    NSManagedObjectID* objectID = managedObject.objectID;
//    NSAssert(objectID, @"Fractal objectID should not be nil. Maybe it wasn't saved?");
    
    MDBFractalInfo* fractalInfo = self.documentController[indexPath.row];
    
    // Configure the cell with data from the managed object.
    documentInfoCell.fractalInfo = fractalInfo;

    if (!fractalInfo.name) {
        [fractalInfo fetchInfoWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // Make sure that the list info is still visible once the color has been fetched.
                if ([self.collectionView.indexPathsForVisibleItems containsObject: indexPath]) {
                    documentInfoCell.fractalInfo = fractalInfo;
                }
            });
        }];
    }

//    LSFractalRenderer* generator;// = (self.fractalToThumbnailGenerators)[objectID];
//    
//    CGSize thumbnailSize = [self cachedThumbnailSizeForCell: cell];
//    
//    UIColor* thumbNailBackground = [UIColor colorWithWhite: 1.0 alpha: 0.8];
//    
//    if (generator.image && cellFractal.fractal.levelUnchanged && cellFractal.fractal.rulesUnchanged) {
//        cell.imageView.image = generator.image;
//    } else {
//        if (!generator) {
//            // No generator yet
//            generator = [LSFractalRenderer newRendererForFractal: cellFractal];
//            generator.name = cellFractal.fractal.name;
//            generator.imageView = cell.imageView;
//            generator.flipY = YES;
//            generator.margin = 10.0;
//            generator.showOrigin = NO;
//            generator.autoscale = YES;
//            UIColor* backgroundColor = [cellFractal.fractal.backgroundColor asUIColor];
//            if (!backgroundColor) backgroundColor = [UIColor clearColor];
//            generator.backgroundColor = backgroundColor;
//#pragma message "TODO move generateLevelData to a privateQueue in case of large levels or just limit level?"
//            
////            (self.fractalToThumbnailGenerators)[objectID] = generator;
//        }
//        [cellFractal.fractal generateLevelData];
//        generator.levelData = cellFractal.fractal.levelNRulesCache;
//        
//        NSBlockOperation* operation = generator.operation;
//        
//        // if the operation exists and is finished
//        //      remove and queue a new operation
//        // if the operation exists and is not finished
//        //      let finish
//        // if no operation exists
//        //      queue new operation
//        
//        if (operation && operation.isFinished) {
//            generator.operation = nil;
//            operation = nil;
//        }
//        
//        if (!operation) {
//            operation = [NSBlockOperation new];
//            generator.operation = operation;
//            
//            [operation addExecutionBlock: ^{
//                //code
//                if (!generator.operation.isCancelled) {
//                    [generator generateImage];
//                    
//                    if (generator.imageView && generator.image) {
//                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                            MBCollectionFractalCell* fractalCell = (MBCollectionFractalCell*)[collectionView cellForItemAtIndexPath: indexPath];
//                            [fractalCell.imageView setImage: generator.image];
//#pragma message "TODO: uidocument fix needed"
////                            if (fractalCell.fractal == self.selectedFractal) {
////                                NSIndexPath* selectIndex = [self.fetchedResultsController indexPathForObject: self.selectedFractal];
////                                [self.collectionView selectItemAtIndexPath: selectIndex animated: NO scrollPosition: UICollectionViewScrollPositionNone];
////                            }
//                        }];
//                    }
//                }
//            }];
//            [self.privateQueue addOperation: operation];
//        }
//    
//        cell.imageView.image = [self placeHolderImageSized: thumbnailSize background: thumbNailBackground];
//    }
//    
//    MBImmutableCellBackgroundView* newBackground =  [MBImmutableCellBackgroundView new];
//    newBackground.readOnlyView = cellFractal.fractal.isImmutable;
//    cell.backgroundView = newBackground;
    
//    if (cellFractal == self.selectedFractal) {
//        cell.selected = YES;
//    } else {
//        cell.selected = NO;
//    }
    
    //    return cell;
}

- (UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    MBCollectionFractalSupplementaryLabel* rView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                                                                                      withReuseIdentifier: kSupplementaryHeaderCellIdentifier
                                                                                             forIndexPath: indexPath];
    
#pragma message "TODO: uidocument fix needed"
//    rView.textLabel.text = [[self.fetchedResultsController sections][indexPath.section] name];

    return rView;
}

#pragma mark - UICollectionViewDelegate
//-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
#pragma message "TODO: uidocument fix needed"
//    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    self.selectedFractal = (LSFractal*)managedObject;
//    LSFractal* selectedFractal = (LSFractal*)managedObject;
//    [self.fractalControllerDelegate setFractal: selectedFractal];

//    [self.presentingViewController dismissViewControllerAnimated: YES completion:^{
        //
        //        [self.fractalControllerDelegate libraryControllerWasDismissed];
        //    }];
        //}
-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
#pragma message "TODO: uidocument fix needed"
//    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    NSManagedObjectID* objectID = managedObject.objectID;
//    
//    NSOperation* operation = (self.fractalToGeneratorOperations)[objectID];
//    if (operation) {
//        [operation cancel];
//        [self.fractalToGeneratorOperations removeObjectForKey: objectID];
//    }
}

@end
