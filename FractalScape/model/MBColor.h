//
//  MBColor.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;

#import "MDBTileObjectProtocol.h"

@class LSFractal, MBColorCategory, MBScapeBackground;

@interface MBColor : NSObject <MDBTileObjectProtocol, NSCopying, NSCoding>

@property (nonatomic, copy) NSString        *identifier;
@property (nonatomic, copy) NSString        *name;
@property (nonatomic, assign) NSInteger     index;
@property (nonatomic, assign) CGFloat       alpha;
@property (nonatomic, assign) CGFloat       red;
@property (nonatomic, assign) CGFloat       green;
@property (nonatomic, assign) CGFloat       blue;
@property (nonatomic, copy) NSString        *imagePath;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) UIColor *asUIColor;
@property (nonatomic,readonly) NSDictionary           *asPListDictionary;

+(instancetype) newMBColorFromPListDictionary: (NSDictionary*) colorDict;

+(instancetype) newMBColorWithUIColor: (UIColor*) color;

+(UIColor*) newDefaultUIColor;
/*!
 This string is assigned by default in the CoreData model definition for the MBColor property identifier.
 
 
 @return The class default identifier string used to identify placeholder object.
 */
+(NSString*) defaultIdentifierString;

+(NSSortDescriptor*) sortDescriptor;

-(UIImage*) thumbnailImageSize: (CGSize) size;

@end
