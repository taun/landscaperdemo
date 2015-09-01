//
//  MBColorCategory.m
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBColorCategory.h"
#import "MBColor.h"


@implementation MBColorCategory

+(NSString*) colorsKey {
    static NSString* categoryColorsKeyString = @"colors";
    return categoryColorsKeyString;
}

+(NSArray*)loadAllDefaultCategories
{
    NSString* plistFileName = @"MBColorsList_default";
    
    id plistObject = [plistFileName fromPListFileNameToObject];
    
    if (![plistObject isKindOfClass: [NSArray class]] || ([plistObject count] == 0))
    {
        NSLog(@"Error plistObject should be an array with size > 1. is: %@", plistObject);
        return nil;
    }
    
    
    NSArray* colorCategoriesPListArray = (NSArray*) plistObject;
    NSMutableArray* colorCategoriesObjectsReturnArray = [NSMutableArray new];
    
    if (colorCategoriesPListArray)
    {
        for (NSDictionary* colorCategoryDict in colorCategoriesPListArray)
        {
            if ([colorCategoryDict isKindOfClass: [NSDictionary class]])
            {
                MBColorCategory* colorCategory = [MBColorCategory newCategoryFromPListDict: colorCategoryDict];
                [colorCategoriesObjectsReturnArray addObject: colorCategory];
            }
        }
    }
    return colorCategoriesObjectsReturnArray;
}

+(instancetype)newCategoryFromPListDict:(NSDictionary *)colorCategoryDict
{
    MBColorCategory* newCategory = [[self class] new];
    newCategory.identifier = colorCategoryDict[@"identifier"];
    newCategory.name = colorCategoryDict[@"name"];
    newCategory.descriptor = colorCategoryDict[@"descriptor"];
    
    NSArray* colorsArray = colorCategoryDict[[MBColorCategory colorsKey]];
    
    if (newCategory && colorsArray.count > 0) {
        [newCategory loadColorsFromPListColorsArray: colorsArray];
    }
    
    return newCategory;
}

-(NSInteger)loadColorsFromPListColorsArray:(NSArray *)colorsArray {
    NSInteger addedColorsCount = 0;
    
    if (colorsArray) {
        
        NSMutableArray* currentColors = [NSMutableArray new];
        
        [currentColors addObjectsFromArray: self.colors];
        
        NSMutableSet* colorIdentifiers = [NSMutableSet setWithCapacity: currentColors.count];
        for (MBColor* color in currentColors) {
            [colorIdentifiers addObject: color.identifier];
        }
        
        
        for (NSDictionary* colorDict in colorsArray) {
            // iterate each color definition dictionary in the category
            if ([colorDict isKindOfClass: [NSDictionary class]]) {
                
                NSString* colorIdentifier = colorDict[@"identifier"];
                
                // don't add if no identifier or identifier already exists
                if (colorIdentifier && ![colorIdentifiers containsObject: colorIdentifier])
                {
                    MBColor* newColor = [MBColor newMBColorFromPListDictionary: colorDict];
                    newColor.index = addedColorsCount;
                    [currentColors addObject: newColor];
                    addedColorsCount++;
                }
                
            }
        }
        
        self.colors = currentColors;
    }
    return addedColorsCount;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _identifier = [aDecoder decodeObjectForKey: @"identifier"];
        _name = [aDecoder decodeObjectForKey: @"name"];
        _descriptor = [aDecoder decodeObjectForKey: @"descriptor"];
        _colors = [aDecoder decodeObjectForKey: @"colors"];
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject: self.identifier forKey: @"identifier"];
    [aCoder encodeObject: self.name forKey: @"name"];
    [aCoder encodeObject: self.descriptor forKey: @"descriptor"];
    [aCoder encodeObject: self.colors forKey: @"colors"];
}

@end
