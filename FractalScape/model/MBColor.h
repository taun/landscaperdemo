//
//  MBColor.h
//  FractalScape
//
//  Created by Taun Chapman on 11/21/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSFractal, MBColorCategory, MBScapeBackground;

@interface MBColor : NSManagedObject

@property (nonatomic, retain) NSNumber * alpha;
@property (nonatomic, retain) NSNumber * blue;
@property (nonatomic, retain) NSNumber * green;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * imagePath;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * red;
@property (nonatomic, retain) MBColorCategory *category;
@property (nonatomic, retain) NSSet *fractalFills;
@property (nonatomic, retain) NSSet *fractalLines;
@property (nonatomic, retain) MBScapeBackground *backgrounds;
@property (nonatomic, retain) LSFractal *fractalColor;
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
