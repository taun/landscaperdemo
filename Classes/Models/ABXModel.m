//
//  ABXModel.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXModel.h"

#import "NSDictionary+ABXNSNullAsNull.h"

@implementation ABXModel

+ (id)createWithAttributes:(NSDictionary*)attributes
{
    // Virtual
    assert(false);
}

+ (NSURLSessionDataTask*)fetchList:(NSString*)path
                            params:(NSDictionary*)params
                          complete:(void(^)(NSArray *objects, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    // Generic list fetch
    return [[ABXApiClient instance] GET:path
                                 params:params
                               complete:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error, id JSON) {
                                   if (responseCode == ABXResponseCodeSuccess) {
                                       NSArray *results = [JSON objectForKeyNulled:@"results"];
                                       if (results && [results isKindOfClass:[NSArray class]]) {
                                           // Convert into objects
                                           NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[results count]];
                                           for (NSDictionary *attrs in results) {
                                               if ([attrs isKindOfClass:[NSDictionary class]]) {
                                                   [objects addObject:[self createWithAttributes:attrs]];
                                               }
                                           }
                                           
                                           // Success!
                                           if (complete) {
                                               complete(objects, responseCode, httpCode, error);
                                           }
                                       }
                                       else {
                                           // Decoding error, pass the values through
                                           if (complete) {
                                               complete(nil, ABXResponseCodeErrorDecoding, httpCode, error);
                                           }
                                       }
                                   }
                                   else {
                                       // Error, pass the values through
                                       if (complete) {
                                           complete(nil, responseCode, httpCode, error);
                                       }
                                   }
                               }];
}

@end
