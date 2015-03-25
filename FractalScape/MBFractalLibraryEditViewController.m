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
#import "MDBFractalDocumentCoordinator.h"

@interface MBFractalLibraryEditViewController ()


- (IBAction)deleteCurrentSelections:(id)sender;

@end

@implementation MBFractalLibraryEditViewController


- (IBAction)deleteCurrentSelections:(id)sender
{
    NSArray* selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
    if (selectedIndexPaths.count > 0) {
        
        NSMutableArray* urls = [NSMutableArray arrayWithCapacity: selectedIndexPaths.count];
        
        for (NSIndexPath* path in selectedIndexPaths) {
            MDBFractalInfo* fractalInfo = self.documentController[path.row];
            if (fractalInfo) {
                [urls addObject: fractalInfo.URL];
                [self.documentController removeFractalInfo: fractalInfo];
            }
        }
        // removal notifications go to the current controller, needs to pass the changes back to the presentingView documentController
        NSArray* controllers = [self.navigationController viewControllers];
        MBFractalLibraryViewController* callingController = (MBFractalLibraryViewController*)[controllers objectAtIndex: controllers.count-2];
        if (callingController && [callingController isKindOfClass: [MBFractalLibraryViewController class]]) {
            [callingController.documentController documentCoordinatorDidUpdateContentsWithInsertedURLs: nil removedURLs: urls updatedURLs: nil];
        }
    }
}
@end
