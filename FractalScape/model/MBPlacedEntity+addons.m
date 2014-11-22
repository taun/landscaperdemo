//
//  MBPlacedEntity+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 11/21/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBPlacedEntity+addons.h"
#import "NSManagedObject+Shortcuts.h"

@implementation MBPlacedEntity (addons)

+ (NSString *)entityName {
    return @"MBPlacedEntity";
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"boundsRectAsString",
                          nil];
    }
    return keysToBeCopied;
}
#pragma message "TODO: not done implementing mutableCopy"

@end
