//
//  MBColor.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
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
@property (nonatomic, retain) MBScapeBackground *background;
@property (nonatomic, retain) MBColorCategory *category;
@property (nonatomic, retain) LSFractal *fractalColor;
@property (nonatomic, retain) LSFractal *fractalFill;
@property (nonatomic, retain) LSFractal *fractalLine;

@end
