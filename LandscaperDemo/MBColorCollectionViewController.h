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

@interface MBColorCollectionViewController : UICollectionViewController <FractalControllerProtocol>

@property (nonatomic,weak) LSFractal        *fractal;
@property (nonatomic,weak) NSUndoManager    *fractalUndoManager;


@end
