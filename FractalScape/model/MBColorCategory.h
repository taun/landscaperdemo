//
//  MBColorCategory.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;
#import <MDUiKit/NSString+MDKConvenience.h>


@class MBColor;

@interface MBColorCategory : NSObject <NSCoding>

@property (nonatomic, copy) NSString        *descriptor;
@property (nonatomic, copy) NSString        *identifier;
@property (nonatomic, copy) NSString        *name;
@property (nonatomic, strong) NSArray       *colors;


+(NSString*) colorsKey;
+(NSArray*)loadAllDefaultCategories;
+(instancetype)newCategoryFromPListDict: (NSDictionary*) colorCategoryDict;
/*!
 The order of the colors definition in the array is the order in which they are added to the NSOrderedSet
 of the [MBColorCategory colors] property.
 
 @warning If a color with the same identifier property already exists, the new one is not added.
 
 @param colorsArray the PList array of color definitions.
 
 @return an NSInteger representing the count of added colors. If this is different from the array count, then something was not added.
 */
-(NSInteger)loadColorsFromPListColorsArray: (NSArray*) colorsArray;

@end