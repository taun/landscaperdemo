//
//  NSString+ABXLocalized.m
//  Sample Project
//
//  Created by Stuart Hall on 26/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "NSString+ABXLocalized.h"

@implementation NSString (ABXLocalized)

- (NSMutableDictionary*)appbotXBundles
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *bundles = nil;
    dispatch_once(&onceToken, ^{
        bundles = [NSMutableDictionary dictionary];
    });
    return bundles;
}

- (NSBundle*)appbotXBundle
{
    static dispatch_once_t onceToken;
    static NSBundle *bundle = nil;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"AppbotX" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:path];
    });
    return bundle;
}

- (NSString*)localizedString
{
    // Load our language bundle
    static dispatch_once_t onceToken;
    static NSBundle *appbotXBundle = nil;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"AppbotX" ofType:@"bundle"];
        appbotXBundle = [NSBundle bundleWithPath:path];
    });
    
    // Loop through the prefered languages
    if ([NSLocale preferredLanguages].count > 0) {
        // Only the first language is valuable
        // the rest seems to be jibberish
        NSString *language = [[[NSLocale preferredLanguages] firstObject] lowercaseString];
        
        // First try the language
        NSString *s = [self localizedStringForLanguage:language];
        if (s.length > 0) {
            return s;
        }
        
        // See if we have the root language e.g. en for en-GB
        NSArray *parts = [language componentsSeparatedByString:@"-"];
        if (parts.count > 1) {
            NSString *s = [self localizedStringForLanguage:[parts firstObject]];
            if (s.length > 0) {
                return s;
            }
        }
    }

    // If we still don't have a localisation then fall back to en
    // if all else fails use the key
    return [self localizedStringForLanguage:@"en"] ?: self;
}

- (NSString*)localizedStringForLanguage:(NSString*)language
{
    static NSString *kNilValue = @"_na_";
    // First check if the user has defined a localisation
    if ([[[NSBundle mainBundle] localizations] containsObject:language]) {
        NSString *s = [[NSBundle mainBundle] localizedStringForKey:self value:kNilValue table:nil];
        if (s.length > 0 && ![s isEqualToString:kNilValue]) {
            // Use their localisation
            return s;
        }
    }
    
    // Look if we have a localisation
    if ([[[self appbotXBundle] localizations] containsObject:language]) {
        NSBundle *bundle = [[self appbotXBundles] objectForKey:language];
        if (!bundle) {
            NSString *path = [[self appbotXBundle] pathForResource:language ofType:@"lproj"];
            bundle = [NSBundle bundleWithPath:path];
            if (bundle) {
                // Cache the bundle
                [[self appbotXBundles] setObject:bundle forKey:language];
            }
        }
        
        if (bundle) {
            NSString *s = [bundle localizedStringForKey:self value:kNilValue table:nil];
            if (s.length > 0 && ![s isEqualToString:kNilValue]) {
                // Use our localisation
                return s;
            }
        }
    }
    
    return nil;
}

@end
