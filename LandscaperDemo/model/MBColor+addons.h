//
//  MBColor+addons.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/02/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBColor.h"

@interface MBColor (addons)

+(MBColor*) mbColorWithUIColor: (UIColor*) color inContext: (NSManagedObjectContext*) context;

+(UIColor*) defaultUIColor;

-(UIColor*) asUIColor;

@end