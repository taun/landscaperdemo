//
//  ABXAttachment.h
//  Sample Project
//
//  Created by Stuart Hall on 25/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXModel.h"

@interface ABXAttachment : ABXModel

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSNumber *identifier;
@property (nonatomic, assign) NSUInteger retries;

- (NSURLSessionDataTask*)upload:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;

@end
