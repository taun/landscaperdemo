//
//  ABXFaq.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXFaq.h"

#import "NSDictionary+ABXNSNullAsNull.h"

PROTECTED_ABXMODEL

@implementation ABXFaq

- (id)initWithAttributes:(NSDictionary*)attributes
{
    self = [super init];
    if (self) {
        self.identifier = [attributes objectForKeyNulled:@"id"];
        
        // Look for a matching localisation
        if ([NSLocale preferredLanguages].count > 0) {
            NSString *language = [[NSLocale preferredLanguages] firstObject];
            
            // Make sure we don't match the default language code
            NSString *defaultLanguage = [attributes valueForKeyPath:@"language.code"];
            if (!defaultLanguage || ![language caseInsensitiveCompare:defaultLanguage] == NSOrderedSame) {
                // Look for an exact match
                [self lookForLocalisation:attributes language:language];
                
                // Look for a partial match (e.g. match en to en-au)
                if (self.question == nil || self.answer == nil) {
                    NSArray *parts = [language componentsSeparatedByString:@"-"];
                    if (parts.count > 1) {
                        language = [parts firstObject];
                        [self lookForLocalisation:attributes language:language];
                    }
                }
            }
        }
        
        // Fall back to the default if we have nothing
        if (self.question == nil || self.answer == nil) {
            self.question = [attributes objectForKeyNulled:@"question"];
            self.answer = [attributes objectForKeyNulled:@"answer"];
        }
    }
    
    return self;
}

+ (id)createWithAttributes:(NSDictionary*)attributes
{
    return [[ABXFaq alloc] initWithAttributes:attributes];
}

- (void)lookForLocalisation:(NSDictionary*)attributes language:(NSString*)language
{
    for (NSDictionary *localisation in [attributes objectForKeyNulled:@"localizations"]) {
        NSString *languageCode = [localisation valueForKeyPath:@"language.code"];
        if (languageCode && [languageCode caseInsensitiveCompare:language] == NSOrderedSame) {
            // Matching localisation
            self.question = [localisation objectForKeyNulled:@"question"];
            self.answer = [localisation objectForKeyNulled:@"answer"];
            break;
        }
    }
}

+ (NSURLSessionDataTask*)fetch:(void(^)(NSArray *faqs, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    return [self fetchList:@"faqs" params:nil complete:complete];
}

- (NSURLSessionDataTask*)upvote:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    return [self vote:@"upvote" complete:complete];
}

- (NSURLSessionDataTask*)downvote:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    return [self vote:@"downvote" complete:complete];
}

- (NSURLSessionDataTask*)vote:(NSString*)action complete:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    return [[ABXApiClient instance] PUT:[NSString stringWithFormat:@"faqs/%@/%@", _identifier, action]
                                 params:nil
                               complete:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error, id JSON) {
                                   if (complete) {
                                       complete(responseCode, httpCode, error);
                                   }
                               }];
}

- (NSURLSessionDataTask*)recordView:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    return [[ABXApiClient instance] GET:[NSString stringWithFormat:@"faqs/%@", _identifier]
                                 params:nil
                               complete:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error, id JSON) {
                                   if (complete) {
                                       complete(responseCode, httpCode, error);
                                   }
                               }];
}

@end
