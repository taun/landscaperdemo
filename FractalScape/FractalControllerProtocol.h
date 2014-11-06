//
//  FractalControllerProtocol.h
//  FractalScape
//
//  Created by Taun Chapman on 03/04/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSFractal+addons.h"

@protocol FractalControllerProtocol <NSObject>

@property (nonatomic,strong) LSFractal        *fractal;
@property (nonatomic,weak) NSUndoManager    *fractalUndoManager;

@end
