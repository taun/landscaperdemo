//
//  MBPlacedEntity.h
//  FractalScape
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSFractal, MBFractalScape;

@interface MBPlacedEntity : NSManagedObject

@property (nonatomic, retain) NSString * boundsRectAsString;
@property (nonatomic, retain) MBFractalScape *fractalScape;
@property (nonatomic, retain) LSFractal *lsFractal;

@end
