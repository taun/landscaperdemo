//
//  MBColorCategory+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 11/10/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBColorCategory.h"

@interface MBColorCategory (addons)
/*!
 Convenience class method to return all of the Color Categories in the persistent store.
 Due to the design of the model, this is the only way to access all of the categories. 
 THe categories can only be traversed to from an individual color referencing a category.
 
 @param context the persistent store context
 
 @return an array of all available categories.
 */
+(NSArray*) allCatetegoriesInContext: (NSManagedObjectContext *)context;
/*!
 Primarily used during PList loading of colors to add the color to a particular category.
 
 @param identifier the category identifier string
 @param context    the persistent store context
 
 @return the MBColorCategory for the identifier
 */
+(MBColorCategory*) findCategoryWithIdentifier:(NSString *)identifier inContext: (NSManagedObjectContext*) context;

+(NSString*) colorsKey;
/*!
 The order of the colors definition in the array is the order in which they are added to the NSOrderedSet 
 of the [MBColorCategory colors] property.
 
 @warning If a color with the same identifier property already exists, the new one is not added.
 
 @param colorsArray the PList array of color definitions.
 
 @return an NSInteger representing the count of added colors. If this is different from the array count, then something was not added. 
 */
-(NSInteger)loadColorsFromPListColorsArray: (NSArray*) colorsArray;


@end
