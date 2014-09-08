//
//  LSReplacementRule+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSReplacementRule+addons.h"

@implementation LSReplacementRule (addons)

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"contextString",
                          @"replacementString",
                          nil];
    }
    return keysToBeCopied;
}

-(id) mutableCopy {
    LSReplacementRule *copy = (LSReplacementRule*)[NSEntityDescription
                                                   insertNewObjectForEntityForName:@"LSReplacementRule"
                                                   inManagedObjectContext: self.managedObjectContext];
    
    if (copy) {
        for ( NSString* aKey in [LSReplacementRule keysToBeCopied]) {
            id value = [self valueForKey: aKey];
            [copy setValue: value forKey: aKey];
        }
    }
    return copy;
}

@end
