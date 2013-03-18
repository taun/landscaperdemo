//
//  MBColorCollectionViewController.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/06/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"
#import "LSFractal+addons.h"

#import "MBColor+addons.h"

@interface MBColorCollectionViewController : UICollectionViewController <FractalControllerProtocol,NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *colorCollectionView;

@property (nonatomic,weak) LSFractal        *fractal;
@property (nonatomic,weak) NSUndoManager    *fractalUndoManager;


@property (nonatomic, strong) NSFetchedResultsController*   fetchedResultsController;

+(NSString*) fractalPropertyKeypath;

-(NSManagedObjectContext*)         appManagedObjectContext;
-(void) initControls;


@end
