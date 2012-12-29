//
//  MBScapeBackground.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/20/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBFractalScape;

@interface MBScapeBackground : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *fractalScapes;
@end

@interface MBScapeBackground (CoreDataGeneratedAccessors)

- (void)addFractalScapesObject:(MBFractalScape *)value;
- (void)removeFractalScapesObject:(MBFractalScape *)value;
- (void)addFractalScapes:(NSSet *)values;
- (void)removeFractalScapes:(NSSet *)values;

@end
