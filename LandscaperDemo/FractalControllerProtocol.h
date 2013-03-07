//
//  FractalControllerProtocol.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/04/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSFractal+addons.h"

@protocol FractalControllerProtocol <NSObject>

@property (nonatomic,weak) LSFractal        *fractal;
@property (nonatomic,weak) NSUndoManager    *fractalUndoManager;

@end
