//
//  MBColorCollectionViewController.h
//  FractalScape
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

@property (nonatomic,strong) LSFractal          *fractal;
@property (nonatomic,weak) NSUndoManager        *fractalUndoManager;
@property (nonatomic,strong) NSArray            *cachedFractalColors;
@property (nonatomic,assign) BOOL               colorsChanged;

@property (nonatomic, strong) NSFetchedResultsController*   libraryColorsFetchedResultsController;
/*!
 Same baseclass is used for showing the line color and fill color. Each subclass just overrides the requisite property keypath.
 Probably overkill. Could have just set a property when passing the fractal in the first place.
 
 @return the fractal keypath corresponding to the desired color type (fill, stroke)
 */
+(NSString*) fractalPropertyKeypath;
/*!
 Don't know why the app main thread context is used and not the fractal context. Probably something to do with threading. Will want to revisit sometime.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSManagedObjectContext *appManagedObjectContext;
-(void) initControls;


@end
