//
//  MBFractalLibraryEditViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/16/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MBFractalLibraryEditViewController.h"

#import "MDBFractalInfo.h"
#import "MDBDocumentController.h"


@interface MBFractalLibraryEditViewController ()


- (IBAction)deleteCurrentSelections:(id)sender;

@end

@implementation MBFractalLibraryEditViewController

- (IBAction)editDone:(UIBarButtonItem *)sender
{
    self.documentController.delegate = self.presentingViewController;
    [self.presentingViewController dismissViewControllerAnimated: YES completion:^{
        //
    }];
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
#pragma message "TODO: uidocument fix needed"
//    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    self.selectedFractal = (LSFractal*)managedObject;
//    LSFractal* selectedFractal = (LSFractal*)managedObject;
//    [self.fractalControllerDelegate setFractal: selectedFractal];

//    [self.presentingViewController dismissViewControllerAnimated: YES completion:^{
//
//        [self.fractalControllerDelegate libraryControllerWasDismissed];
//    }];
}

- (IBAction)deleteCurrentSelections:(id)sender
{
    NSArray* selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
    if (selectedIndexPaths.count > 0) {
        
        for (NSIndexPath* path in selectedIndexPaths) {
            MDBFractalInfo* fractalInfo = self.documentController[path.row];
            if (fractalInfo) {
                [self.documentController removeFractalInfo: fractalInfo];
            }
        }
        
    }
}
@end
