//
//  MBColor+addons.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/02/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBColor+addons.h"

@implementation MBColor (addons)

+(UIColor*) defaultUIColor {
    return [UIColor colorWithRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];
}

+(MBColor*) mbColorWithUIColor:(UIColor *)color inContext:(NSManagedObjectContext *)context {
    
    MBColor *newColor = [NSEntityDescription
                         insertNewObjectForEntityForName:@"MBColor"
                         inManagedObjectContext: context];
    
    if (newColor) {
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        
        BOOL success = [color getRed: &red green: &green blue: &blue alpha: &alpha];
        
        if (success) {
            newColor.red = [NSNumber numberWithDouble: red];
            newColor.blue = [NSNumber numberWithDouble: blue];
            newColor.green = [NSNumber numberWithDouble: green];
            newColor.alpha = [NSNumber numberWithDouble: alpha];
        }
    }
    return newColor;
}

-(UIColor*) asUIColor {
        
    return [UIColor colorWithRed:[self.red floatValue] 
                           green:[self.green floatValue] 
                            blue:[self.blue floatValue] 
                           alpha:[self.alpha floatValue]];
}

@end
