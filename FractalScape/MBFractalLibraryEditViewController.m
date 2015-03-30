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

- (void)viewDidLoad
{
    UIVisualEffectView* blurEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleExtraLight]];
    self.collectionView.backgroundView = blurEffectView;
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContentSizeCategoryDidChangeNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}


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
        if (self.presentingDocumentController) {
            [self.presentingDocumentController documentCoordinatorDidUpdateContentsWithInsertedURLs: nil removedURLs: urls updatedURLs: nil];
        }
    }
}
- (IBAction)editingIsDoneButton:(id)sender
{
    [self.navigationController popViewControllerAnimated: NO];
}
@end
