//
//  ABXNotification.h
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ABXModel.h"

@interface ABXNotification : ABXModel

@property (nonatomic, copy) NSNumber *identifier;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *actionLabel;
@property (nonatomic, copy) NSString *actionUrl;
@property (nonatomic, copy) NSDate *createdAt;

- (void)markAsSeen;
- (BOOL)hasSeen;
- (BOOL)hasAction;

+ (NSURLSessionDataTask*)fetchActive:(void(^)(NSArray *notifications, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;

+ (NSURLSessionDataTask*)fetch:(void(^)(NSArray *notifications, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;

@end
