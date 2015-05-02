//
//  ABXModel.h
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ABXApiClient.h"

// Protected methods
#define PROTECTED_ABXMODEL \
@interface ABXModel () \
+ (id)createWithAttributes:(NSDictionary*)attributes; \
+ (NSURLSessionDataTask*)fetchList:(NSString*)path \
                            params:(NSDictionary*)params \
                          complete:(void(^)(NSArray *objects, ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete; \
@end \

@interface ABXModel : NSObject
@end
