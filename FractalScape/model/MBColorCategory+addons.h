//
//  MBColorCategory+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 11/10/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBColorCategory.h"

@interface MBColorCategory (addons)

+(NSArray*) allCatetegoriesInContext: (NSManagedObjectContext *)context;
+(MBColorCategory*) findCategoryWithIdentifier:(NSString *)identifier inContext: (NSManagedObjectContext*) context;

-(NSInteger)loadColorsFromPListColorsArray: (NSArray*) colorsArray;

@end
