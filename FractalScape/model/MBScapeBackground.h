//
//  MBScapeBackground.h
//  FractalScape
//
//  Created by Taun Chapman on 11/21/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBColor, MBFractalScape;

@interface MBScapeBackground : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *fractalScapes;
@property (nonatomic, retain) MBColor *color;
@end

@interface MBScapeBackground (CoreDataGeneratedAccessors)

- (void)addFractalScapesObject:(MBFractalScape *)value;
- (void)removeFractalScapesObject:(MBFractalScape *)value;
- (void)addFractalScapes:(NSSet *)values;
- (void)removeFractalScapes:(NSSet *)values;

@end
