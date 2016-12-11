//
//  MBFractalLibraryViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "FractalControllerProtocol.h"
#import "MDBFractalLibraryCollectionSource.h"
#import "MDBNavConTransitionCoordinator.h"

@class MDBAppModel;
@class MDBFractalInfo;
@class MDBFractalDocument;
@class MDBDocumentController;

extern NSString *const kSupplementaryHeaderCellIdentifier;

/*!
 Facilitates the selection of a MDBFractalDocumentInfo and passes it to the MBLSFractalEditViewController.
 */
@interface MBFractalLibraryViewController : UIViewController <  UICollectionViewDelegate,
                                                                UICollectionViewDelegateFlowLayout,
                                                                MDBNavConTransitionProtocol,
                                                                MDBFractalLibraryCollectionDelegate>

/*!
 The collection of MDBFractalDocumentInfo objects from the local filesystem or cloud.
 */
@property (nonatomic,strong) MDBAppModel                                    *appModel;
/*!
 The collectionView for showing the records
 */
@property (weak, nonatomic) IBOutlet UICollectionView                       *collectionView;
/*!
 The library collection source
 */
@property (nonatomic,strong) IBOutlet MDBFractalLibraryCollectionSource      *collectionSource;
/*!
 Add a new document
 */
@property (weak, nonatomic) IBOutlet UIBarButtonItem                        *addDocumentButton;
/*!
 The fractlInfo currently being edited for when view unwinds back
 */
@property (nonatomic,weak) MDBFractalInfo                                   *fractalInfoBeingEdited;
/*!
 For when transitioning and wanting to pre-set a scroll location.
 */
@property(nonatomic,assign)CGPoint                                          initialContentOffset;
@property(readonly)NSString                                                 *libraryTitle;
/*!
 Startup sequence used when it is not the first startup and there is no need for the intro.
 
 Public so it can be overriden in subclasses.
 */
-(void)regularStartupSequence;

#pragma mark - Segue Actions
//- (IBAction)unwindToLibraryFromEditor:(UIStoryboardSegue *)segue;
//- (IBAction)unwindToLibraryFromEditMode:(UIStoryboardSegue *)segue;
- (IBAction)newDocumentButtonTapped:(UIBarButtonItem *)sender;
- (IBAction)pushToLibraryEditViewController:(id)sender;
- (IBAction)unwindFromWelcome:(UIStoryboardSegue *)segue;
- (IBAction)unwindFromLibraryEditController:(UIStoryboardSegue*)segue;
- (IBAction)unwindFromPurchaseController:(UIStoryboardSegue *)segue;
- (IBAction)unwindFromEditor:(UIStoryboardSegue *)segue;

-(IBAction) upgradeToProSelected:(id)sender;

#pragma mark - MDBFractalLibraryCollectionDelegate

-(void)libraryCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;


#pragma mark - NavConTransitionProtocol
@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      pushTransition;
@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      popTransition;
@property (nonatomic,assign) CGRect                                         transitionDestinationRect;
@property (nonatomic,assign) CGRect                                         transitionSourceRect;

@end
