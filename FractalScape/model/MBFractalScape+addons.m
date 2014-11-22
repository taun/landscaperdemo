//
//  MBFractalScape+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 11/21/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBFractalScape+addons.h"
#import "NSManagedObject+Shortcuts.h"

@implementation MBFractalScape (addons)

+ (NSString *)entityName {
    return @"MBFractalScape";
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"descriptor",
                          @"name",
                          @"size",
                          nil];
    }
    return keysToBeCopied;
}
#pragma message "TODO: not done implementing mutableCopy"

@end
