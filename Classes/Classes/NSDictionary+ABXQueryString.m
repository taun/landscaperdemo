//
//  NSDictionary+ABXQueryString.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "NSDictionary+ABXQueryString.h"

#import "NSString+ABXURLEncoding.h"

@implementation NSDictionary (ABXQueryString)

- (NSString *)queryStringValue
{
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in [self keyEnumerator])
    {
        id value = [self objectForKey:key];
        NSString *escapedValue = [value urlEncodedString];
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escapedValue]];
    }
    
    return [pairs componentsJoinedByString:@"&"];
}

@end
