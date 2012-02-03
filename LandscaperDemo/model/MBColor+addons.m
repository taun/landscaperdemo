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

-(UIColor*) asUIColor {
        
    return [UIColor colorWithRed:[self.red floatValue] 
                           green:[self.green floatValue] 
                            blue:[self.blue floatValue] 
                           alpha:[self.alpha floatValue]];
}

@end
