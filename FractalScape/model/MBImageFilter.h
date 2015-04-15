//  Created by Taun Chapman on 03/30/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//


@import CoreImage;
@import Foundation;

#import "MDBTileObjectProtocol.h"

@interface MBImageFilter : NSObject <MDBTileObjectProtocol, NSCopying, NSCoding>

/*!
 The CIFilter CIAttributeFilterName
 */
@property (nonatomic, copy) NSString                *identifier;

/*
  CIFilter CIAttributeFilterDisplayName
 */
@property (nonatomic,copy) NSString                 *name;

/*
 Most values will be NSNumber, CIVector values are stored as NSString.
 Use vectorWithString: & stringRepresentation
 */
@property (nonatomic,strong) NSMutableDictionary    *inputValues;

/*!
 Return the CIFilter retrieved instantiated using the filter name property
 and with the values set from the input values.
 */
@property (nonatomic,readonly) CIFilter             *ciFilter;


+(instancetype) newFilterWithIdentifier: (NSString*)ciFilterName;

+(NSString*) defaultIdentifierString;

+(NSSortDescriptor*) sortDescriptor;

-(UIImage*) thumbnailImageSize: (CGSize) size;

-(void)setGoodDefaultsOnCIFilter: (CIFilter*)ciFilter forImage: (CIImage*)image bounds: (CGRect)bounds;

-(UIImage*)filterImage: (UIImage*)inputImage withContext: (CIContext*)context;

@end
