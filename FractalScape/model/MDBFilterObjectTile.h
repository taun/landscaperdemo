//  Created by Taun Chapman on 03/30/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBTileObjectProtocol.h"

@import CoreImage;
@import Foundation;

@interface MDBFilterObjectTile : NSObject <MDBTileObjectProtocol>

/*
 Official CIFilter name for use in
 */
@property (nonatomic,copy) NSString                 *filterName;

/*
 Most values will be NSNumber, CIVector values are stored as NSString.
 Use vectorWithString: & stringRepresentation
 */
@property (nonatomic,strong) NSMutableDictionary    *inputValues;

@end
