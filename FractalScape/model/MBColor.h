//
//  MBColor.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSFractal;

@interface MBColor : NSManagedObject

@property (nonatomic, retain) NSNumber * alpha;
@property (nonatomic, retain) NSNumber * blue;
@property (nonatomic, retain) NSNumber * green;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * imagePath;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * red;
@property (nonatomic, retain) NSSet *fractalFills;
@property (nonatomic, retain) NSSet *fractalLines;
@end

@interface MBColor (CoreDataGeneratedAccessors)

- (void)addFractalFillsObject:(LSFractal *)value;
- (void)removeFractalFillsObject:(LSFractal *)value;
- (void)addFractalFills:(NSSet *)values;
- (void)removeFractalFills:(NSSet *)values;

- (void)addFractalLinesObject:(LSFractal *)value;
- (void)removeFractalLinesObject:(LSFractal *)value;
- (void)addFractalLines:(NSSet *)values;
- (void)removeFractalLines:(NSSet *)values;

@end
