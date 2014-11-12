//
//  MBFractalColorViewContainer.h
//  FractalScape
//
//  Created by Taun Chapman on 11/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"
#import "LSFractal+addons.h"

@interface MBFractalColorViewContainer : UIViewController <FractalControllerProtocol, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic,strong) LSFractal          *fractal;
@property (nonatomic,weak) NSUndoManager        *fractalUndoManager;
@property(nonatomic,strong) NSString            *fractalPropertyKeypath;

@property (nonatomic,strong) NSArray            *cachedFractalColors;
@property (nonatomic,assign) BOOL               colorsChanged;

@property (weak, nonatomic) IBOutlet UIView *colorCollectionContainer;
@property (weak, nonatomic) IBOutlet UICollectionView *fractalDestinationCollection;

@end
