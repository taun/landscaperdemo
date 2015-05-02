//
//  NSString+ABXURLEncoding.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "NSString+ABXURLEncoding.h"

@implementation NSString (ABXURLEncoding)

- (NSString *)urlEncodedString
{
    CFStringRef ref = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                              (__bridge CFStringRef)self,
                                                              NULL,
                                                              (CFStringRef)@":!*();@/&?#[]+$,='%’\"",
                                                              kCFStringEncodingUTF8);
    return (__bridge_transfer NSString *)(ref);
}

- (NSString *)urlDecodedString
{
    CFStringRef ref = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                              (__bridge CFStringRef)self,
                                                                              CFSTR(""),
                                                                              kCFStringEncodingUTF8);
    return (__bridge_transfer NSString *)(ref);
}

@end
