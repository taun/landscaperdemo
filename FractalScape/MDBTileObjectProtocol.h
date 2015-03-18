//
//  MDBTileObjectProtocol.h
//  FractalScape
//
//  Created by Taun Chapman on 12/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//




@import Foundation;
@import UIKit;


/*!
 This class serves two goals. 1) A placeholder tile for IB_Designable view layouts in IB.
 2) A placeholder when a tileView or tileListView does not have an object to show. This placeholder
 is used to show the availability of the position to the user, maintain autolayout constraints and be 
 replaced when a new object shows up by drag and drop. 
 */
@protocol MDBTileObjectProtocol <NSObject>

/*!
 Used to determine if this instance is a placeholder to be replaced by a drag and drop.
 If YES, replace this instance with the new dropped instance. If NO, insert the new object.
 */
@property (nonatomic,readonly) BOOL     isDefaultObject;

-(UIImage*) asImage;
-(instancetype) copy;

@end
