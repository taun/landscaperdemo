//
//  ABXVersion.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXVersion.h"

#import "NSDictionary+ABXNSNullAsNull.h"
#import "ABXKeychain.h"

PROTECTED_ABXMODEL

@implementation ABXVersion

- (id)initWithAttributes:(NSDictionary*)attributes
{
    self = [super init];
    if (self) {
        // Date formatter, cache as they are expensive to create
        static dispatch_once_t onceToken;
        static NSDateFormatter *formatter = nil;
        dispatch_once(&onceToken, ^{
            formatter = [NSDateFormatter new];
            [formatter setDateFormat:@"yyyy-MM-dd"];
        });
        
        // Convert the string to a date
        NSString *releaseDateString = [attributes objectForKeyNulled:@"release_date"];
        if (releaseDateString) {
            self.releaseDate = [formatter dateFromString:releaseDateString];
        }
        
        self.version = [attributes objectForKeyNulled:@"version"];
        
        // Look for a matching localisation
        if ([NSLocale preferredLanguages].count > 0) {
            NSString *language = [[NSLocale preferredLanguages] firstObject];
            
            // Make sure we don't match the default language code
            NSString *defaultLanguage = [attributes valueForKeyPath:@"language.code"];
            if (!defaultLanguage || ![language caseInsensitiveCompare:defaultLanguage] == NSOrderedSame) {
                // Look for an exact match
                [self lookForLocalisation:attributes language:language];
                
                // Look for a partial match (e.g. match en to en-au)
                if (self.text == nil) {
                    NSArray *parts = [language componentsSeparatedByString:@"-"];
                    if (parts.count > 1) {
                        language = [parts firstObject];
                        [self lookForLocalisation:attributes language:language];
                    }
                }
            }
        }
        
        // Fall back to the default if we have nothing
        if (self.text == nil) {
            self.text = [attributes objectForKeyNulled:@"change_text"];
        }
    }
    return self;
}

+ (id)createWithAttributes:(NSDictionary*)attributes
{
    return [[ABXVersion alloc] initWithAttributes:attributes];
}

- (void)lookForLocalisation:(NSDictionary*)attributes language:(NSString*)language
{
    for (NSDictionary *localisation in [attributes objectForKeyNulled:@"localizations"]) {
        NSString *languageCode = [localisation valueForKeyPath:@"language.code"];
        if (languageCode && [languageCode caseInsensitiveCompare:language] == NSOrderedSame) {
            // Matching localisation
            self.text = [localisation objectForKeyNulled:@"change_text"];
            break;
        }
    }
}

+ (NSURLSessionDataTask*)fetch:(void(^)(NSArray *versions, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    return [self fetchList:@"versions" params:nil complete:complete];
}

+ (NSURLSessionDataTask*)fetchCurrentVersion:(void(^)(ABXVersion *version, ABXVersion *latestVersion, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    NSString *currentVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ?: NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
    return [[ABXApiClient instance] GET:@"versions"
                                 params:@{ @"version" : currentVersion }
                               complete:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error, id JSON) {
                                   if (responseCode == ABXResponseCodeSuccess) {
                                       NSDictionary *results = [JSON objectForKeyNulled:@"results"];
                                       if (results && [results isKindOfClass:[NSDictionary class]]) {
                                           // Convert into objects
                                           ABXVersion *version = nil;
                                           ABXVersion *currentVersion = nil;
                                           
                                           if ([results objectForKeyNulled:@"version"]) {
                                               version = [self createWithAttributes:[results objectForKeyNulled:@"version"]];
                                           }
                                           
                                           if ([results objectForKeyNulled:@"current_version"]) {
                                               currentVersion = [self createWithAttributes:[results objectForKeyNulled:@"current_version"]];
                                           }
                                           
                                           // Success!
                                           if (complete) {
                                               complete(version, currentVersion, responseCode, httpCode, error);
                                           }
                                       }
                                       else {
                                           // Decoding error, pass the values through
                                           if (complete) {
                                               complete(nil, nil, ABXResponseCodeErrorDecoding, httpCode, error);
                                           }
                                       }
                                   }
                                   else {
                                       // Error, pass the values through
                                       if (complete) {
                                           complete(nil, nil, responseCode, httpCode, error);
                                       }
                                   }
                               }];
}

- (void)markAsSeen
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"Version" stringByAppendingString:self.version]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)hasSeen
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[@"Version" stringByAppendingString:self.version]];
}

- (BOOL)isNewerThanCurrent
{
    NSString *currentVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ?: NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
    return [self.version compare:currentVersion options:NSNumericSearch] == NSOrderedDescending;
}

- (void)isLiveVersion:(NSString*)itunesId country:(NSString*)country complete:(void(^)(BOOL matches))complete
{
    // Look up the version on the App Store and see if it matches us
    NSString *url = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?id=%@&entity=software&country=%@", itunesId, country];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue currentQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (data) {
                                   NSError *jsonError;
                                   NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data
                                                                                          options:0
                                                                                            error:&jsonError];
                                   if (!jsonError && [result isKindOfClass:[NSDictionary class]]) {
                                       NSArray *results = [result objectForKey:@"results"];
                                       if ([results isKindOfClass:[NSArray class]] && results.count > 0) {
                                           NSDictionary *result = [results firstObject];
                                           NSString *storeVersion = [result objectForKey:@"version"];
                                           if (complete && [storeVersion isKindOfClass:[NSString class]]) {
                                               complete([storeVersion isEqualToString:self.version]);
                                               return;
                                           }
                                       }
                                   }
                               }
                               
                               if (complete) {
                                   complete(NO);
                               }
                           }];
}

@end
