//
//  ABXFaq.h
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ABXModel.h"

@interface ABXFaq : ABXModel

@property (nonatomic, copy) NSNumber *identifier;
@property (nonatomic, copy) NSString *question;
@property (nonatomic, copy) NSString *answer;

+ (NSURLSessionDataTask*)fetch:(void(^)(NSArray *faqs, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;

- (NSURLSessionDataTask*)upvote:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;
- (NSURLSessionDataTask*)downvote:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;

- (NSURLSessionDataTask*)recordView:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;

@end
