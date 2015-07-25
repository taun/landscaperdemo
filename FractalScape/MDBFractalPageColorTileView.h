//
//  MDBFractalPageColorTileView.h
//  FractalScape
//
//  Created by Taun Chapman on 12/10/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import UIKit;

#import "MDBFractalDocument.h"
#import "MBColor.h"

#import "MBLSRuleDragAndDropProtocol.h"
#import "MDBTileObjectProtocol.h"
#import "MDBLSObjectTileView.h"

#import "FractalControllerProtocol.h"

IB_DESIGNABLE


@interface MDBFractalPageColorTileView : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) MDBFractalDocument              *fractalDocument;

@property (nonatomic,assign) IBInspectable CGFloat      tileCornerRadius;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;

-(void) startBlinkOutline;
-(void) endBlinkOutline;

@end
