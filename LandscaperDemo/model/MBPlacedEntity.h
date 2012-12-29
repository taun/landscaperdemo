//
//  MBPlacedEntity.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/20/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSFractal, MBFractalScape;

@interface MBPlacedEntity : NSManagedObject

@property (nonatomic, retain) NSString * boundsRectAsString;
@property (nonatomic, retain) MBFractalScape *fractalScape;
@property (nonatomic, retain) LSFractal *lsFractal;

@end
