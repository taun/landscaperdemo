//
//  MBFractalScape.h
//  FractalScape
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBPlacedEntity, MBScapeBackground;

@interface MBFractalScape : NSManagedObject

@property (nonatomic, retain) NSString * descriptor;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id size;
@property (nonatomic, retain) MBScapeBackground *background;
@property (nonatomic, retain) NSSet *placedEntities;
@end

@interface MBFractalScape (CoreDataGeneratedAccessors)

- (void)addPlacedEntitiesObject:(MBPlacedEntity *)value;
- (void)removePlacedEntitiesObject:(MBPlacedEntity *)value;
- (void)addPlacedEntities:(NSSet *)values;
- (void)removePlacedEntities:(NSSet *)values;

@end
