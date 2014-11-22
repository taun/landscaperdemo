//
//  MBScapeBackground+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 11/21/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBScapeBackground+addons.h"

@implementation MBScapeBackground (addons)

+ (NSString *)entityName {
    return @"MBScapeBackground";
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"name",
                          @"color",
                          nil];
    }
    return keysToBeCopied;
}

@end
