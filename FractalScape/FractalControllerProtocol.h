//
//  FractalControllerProtocol.h
//  FractalScape
//
//  Created by Taun Chapman on 03/04/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSFractal+addons.h"

@protocol FractalControllerDelegate <NSObject>
-(void) setFractal: (LSFractal*) fractal;
-(void) libraryControllerWasDismissed; // temporary hack
@end

@protocol FractalControllerProtocol <NSObject>

@property (nonatomic,strong) LSFractal                                  *fractal;
@property (nonatomic,weak) NSUndoManager                                *fractalUndoManager;
@property (nonatomic,weak) id<FractalControllerDelegate>                 delegate;
@property(nonatomic,assign) CGSize                                      portraitSize;
@property(nonatomic,assign) CGSize                                      landscapeSize;

@end

