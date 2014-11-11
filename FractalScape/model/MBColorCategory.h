//
//  MBColorCategory.h
//  FractalScape
//
//  Created by Taun Chapman on 11/10/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBColor;

@interface MBColorCategory : NSManagedObject

@property (nonatomic, retain) NSString * descriptor;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *colors;
@end

@interface MBColorCategory (CoreDataGeneratedAccessors)

- (void)addColorsObject:(MBColor *)value;
- (void)removeColorsObject:(MBColor *)value;
- (void)addColors:(NSSet *)values;
- (void)removeColors:(NSSet *)values;

@end
