//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;

#import "MDBTileObjectProtocol.h"

typedef struct {
    CGFloat h,s,l,a;
} ColorHSLA;

typedef struct {
    CGFloat h,s,v;
} HSV;

typedef struct {
    CGFloat r,g,b,a;
} ColorRGBA;

typedef struct {
    BOOL isColorRef;
    ColorRGBA rgba;
    CGColorRef colorRef;
} ColorRgbaOrColorRef;

@class LSFractal, MBColorCategory, MBScapeBackground;

/*!
 AN MBColor can be either pure RGBA or an image used as a pattern. If it is a pure RGBA, 
 the RGBA values may be manipulated.
 */
@interface MBColor : NSObject <MDBTileObjectProtocol, NSCopying, NSCoding>

@property (nonatomic, copy) NSString        *identifier;
@property (nonatomic, copy) NSString        *name;
@property (nonatomic, assign) NSInteger     index;
@property (nonatomic, assign) CGFloat       alpha;
@property (nonatomic, assign) CGFloat       red;
@property (nonatomic, assign) CGFloat       green;
@property (nonatomic, assign) CGFloat       blue;
@property (nonatomic, copy) NSString        *imagePath;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) UIColor    *UIColor;
@property (NS_NONATOMIC_IOSONLY, readonly, assign) BOOL     isPattern;
@property (nonatomic,readonly) NSDictionary             *asPListDictionary;

+(instancetype) newMBColorFromPListDictionary: (NSDictionary*) colorDict;

/*!
 Convenience instantiator. Note, identifier will be defaultIdentifier. Should replce the 
 identifier if you want the color to stay in the list during drag and drop.
 
 @param color a UIColor source color
 
 @return a new MBColor
 */
+(instancetype) newMBColorWithUIColor: (UIColor*) color;

/*!
 A class method for a system wide default UIColor.
 
 @return a UIColor
 */
+(UIColor*) newDefaultUIColor;
/*!
 This string is assigned by default in the model definition for the MBColor property identifier.
 
 @return The class default identifier string used to identify placeholder object.
 */
+(NSString*) defaultIdentifierString;

+(NSSortDescriptor*) sortDescriptor;

-(UIImage*) thumbnailImageSize: (CGSize) size;
/*!
 Returns the CGColor version of the UIColor property.
 
 @return CGColorRef is retained and released by this objects UIColor property..
 */
-(CGColorRef)CGColor;

-(void)rotateHueByDegrees: (CGFloat)degreeRotation;

-(ColorRgbaOrColorRef)asColorRgbaOrColorRefStruct;

@end
