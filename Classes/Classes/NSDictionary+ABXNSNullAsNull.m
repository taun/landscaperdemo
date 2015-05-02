//
//  NSDictionary+ABXNSNullAsNull.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "NSDictionary+ABXNSNullAsNull.h"

@implementation NSDictionary (ABXNSNullAsNull)

- (id)objectForKeyNulled:(id)aKey
{
    id value = [self objectForKey:aKey];
    if (!value || [value isKindOfClass:[NSNull class]]) {
        return nil;
    }
    return value;
}

@end
