//
//  MBFractalAppearanceEditorViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 03/05/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"
#import "LSFractal+addons.h"

/*!
 A TabBarController used to contain all of the fractal edit controls/pages. The custom class
 was created to adhere to the FractalControllerProtocol, to pass on the LSFractal property
 and to overrides the nib size and handle the sizing internally based on the device rotation.
 At some point this could be replaced with the new device independent sizing.
 */
@interface MBFractalAppearanceEditorViewController : UITabBarController <FractalControllerProtocol,UITabBarControllerDelegate>

@property (nonatomic,weak) LSFractal        *fractal;
@property (nonatomic,weak) NSUndoManager    *fractalUndoManager;

@end
