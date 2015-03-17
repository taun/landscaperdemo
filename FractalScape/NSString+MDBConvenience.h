//
//  NSString+MDBConvenience.h
//  FractalScapes
//
//  Created by Taun Chapman on 02/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;


@interface NSString (MDBConvenience)

+(NSString*) mdbStringByAppendingOrIncrementingCount: (NSString*)originalString;

/*!
 Take the receiving string and look up the file resource with the string name in the current bundle.
 
 @return a property list object
 */
-(id) fromPListFileNameToObject;

@end
