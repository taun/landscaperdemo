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
@class MDBFractalDocument;
@class MDBDocumentController;

extern NSString *const kSupplementaryHeaderCellIdentifier;

/*!
 Facilitates the selection of a MDBFractalDocumentInfo and passes it to the MBLSFractalEditViewController.
 */
@interface MBFractalLibraryViewController : UICollectionViewController <MDBNavConTransitionProtocol,MDBFractalLibraryCollectionDelegate>

/*!
 The collection of MDBFractalDocumentInfo objects from the local filesystem or cloud.
 */
@property (nonatomic,strong) MDBAppModel                                    *appModel;
@property (nonatomic,strong) IBOutlet MDBFractalLibraryCollectionSource      *collectionSource;

-(void)regularStartupSequence;

#pragma mark - Segue Actions
//- (IBAction)unwindToLibraryFromEditor:(UIStoryboardSegue *)segue;
//- (IBAction)unwindToLibraryFromEditMode:(UIStoryboardSegue *)segue;
- (IBAction)pickDocument:(UIBarButtonItem *)sender;
- (IBAction)pushToLibraryEditViewController:(id)sender;
- (IBAction)unwindToLibraryFromWelcome:(UIStoryboardSegue *)segue;

#pragma mark - MDBFractalLibraryCollectionDelegate

-(void)libraryCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;


#pragma mark - NavConTransitionProtocol
@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      pushTransition;
@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      popTransition;
@property (nonatomic,assign) CGRect                                         transitionDestinationRect;
@property (nonatomic,assign) CGRect                                         transitionSourceRect;

@end
