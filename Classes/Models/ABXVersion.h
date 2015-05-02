//
//  ABXVersion.h
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ABXModel.h"

@interface ABXVersion : ABXModel

@property (nonatomic, strong) NSDate *releaseDate;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *version;

- (void)markAsSeen;
- (BOOL)hasSeen;
- (BOOL)isNewerThanCurrent;
- (void)isLiveVersion:(NSString*)itunesId country:(NSString*)country complete:(void(^)(BOOL matches))complete;

+ (NSURLSessionDataTask*)fetch:(void(^)(NSArray *versions, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;

+ (NSURLSessionDataTask*)fetchCurrentVersion:(void(^)(ABXVersion *currentVersion, ABXVersion *latestVersion, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;

@end
