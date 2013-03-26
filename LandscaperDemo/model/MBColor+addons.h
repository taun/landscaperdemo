//
//  MBColor+addons.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/02/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBColor.h"

@interface MBColor (addons)

+(NSArray*) allColorsInContext: (NSManagedObjectContext *)context;

+(MBColor*) newMBColorWithUIColor: (UIColor*) color inContext: (NSManagedObjectContext*) context;

+(MBColor*) findMBColorWithIdentifier: (NSString*) colorIdentifier inContext: (NSManagedObjectContext*) context;

+(UIColor*) newDefaultUIColor;

-(UIColor*) asUIColor;

@end
