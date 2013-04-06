//
//  MBFractalAppearanceEditorViewController.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/05/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"
#import "LSFractal+addons.h"

@interface MBFractalAppearanceEditorViewController : UITabBarController <FractalControllerProtocol,UITabBarControllerDelegate>

@property (nonatomic,weak) LSFractal        *fractal;
@property (nonatomic,weak) NSUndoManager    *fractalUndoManager;

@end
