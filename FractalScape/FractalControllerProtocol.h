//
//  FractalControllerProtocol.h
//  FractalScape
//
//  Created by Taun Chapman on 03/04/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//


#import "LSFractal.h"
#import "MDBFractalDocument.h"
#import "MDBAppModel.h"

@protocol FractalControllerDelegate <NSObject>
-(void) setFractalDocument: (MDBFractalDocument*) fractalDocument;
-(void) presentPurchaseOptions;
@end

@protocol FractalControllerProtocol <NSObject>

@property (nonatomic,strong) MDBAppModel                                  *appModel;
@property (nonatomic,strong) MDBFractalDocument                         *fractalDocument;
@property (nonatomic,weak) NSUndoManager                                *fractalUndoManager;
@property (nonatomic,weak) id<FractalControllerDelegate>                 fractalControllerDelegate;
//@property(nonatomic,assign) CGSize                                      portraitSize;
//@property(nonatomic,assign) CGSize                                      landscapeSize;

@end

