//
//  MBFractalLibraryViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"
@class LSFractal;

@interface MBFractalLibraryViewController : UICollectionViewController <FractalControllerProtocol>

@property (weak, nonatomic) IBOutlet UICollectionView *fractalCollectionView;

/* if set, make the initial selection in the collection.
 There must always be a fractal or there is no managedObjectContext. */
@property (strong, nonatomic) LSFractal                   *fractal;

@property (nonatomic,weak) NSUndoManager                *fractalUndoManager;

/* internally set to the current selection */
@property (strong, nonatomic) LSFractal                 *selectedFractal;

@end
