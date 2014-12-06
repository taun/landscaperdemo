//
//  MBPlacedEntity.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSFractal, MBFractalScape;

@interface MBPlacedEntity : NSManagedObject

@property (nonatomic, retain) NSString * boundsRectAsString;
@property (nonatomic, retain) MBFractalScape *fractalScape;
@property (nonatomic, retain) LSFractal *lsFractal;

@end
