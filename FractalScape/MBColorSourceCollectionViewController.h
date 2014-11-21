//
//  MBColorSourceCollectionViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 03/06/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"
#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "MBLSRuleDragAndDropProtocol.h"

@interface MBColorSourceCollectionViewController : UICollectionViewController <FractalControllerProtocol, NSFetchedResultsControllerDelegate, MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) LSFractal                      *fractal;
@property (nonatomic,weak) NSUndoManager                    *fractalUndoManager;

@property (nonatomic, strong) NSFetchedResultsController    *libraryColorsFetchedResultsController;
/*!
 Don't know why the app main thread context is used and not the fractal context. Probably something to do with threading. Will want to revisit sometime.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSManagedObjectContext *appManagedObjectContext;
-(void) initControls;

- (IBAction)collectionLongPress:(id)sender;

@end
