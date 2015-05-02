//
//  ABXApiClient.h
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

@import Foundation;
@import UIKit;


// Error codes
typedef enum {
    ABXResponseCodeSuccess,       // Request completed successfully
    ABXResponseCodeErrorAuth,     // Check your bundle identifier and API key
    ABXResponseCodeErrorExpired,  // Account requires payment
    ABXResponseCodeErrorDecoding, // Error decoding the JSON data
    ABXResponseCodeErrorEncoding, // Error encoding the post/put request
    ABXResponseCodeErrorNotFound, // Not found
    ABXResponseCodeErrorUnknown   // Unknown error
} ABXResponseCode;

typedef void (^ABXRequestCompletion)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error, id JSON);

@interface ABXApiClient : NSObject

+ (ABXApiClient*)instance;

+ (BOOL)isInternetReachable;

- (void)setApiKey:(NSString *)apiKey;

- (NSURLSessionDataTask*)GET:(NSString*)path params:(NSDictionary*)params complete:(ABXRequestCompletion)complete;

- (NSURLSessionDataTask*)POST:(NSString*)path params:(NSDictionary*)params complete:(ABXRequestCompletion)complete;
- (NSURLSessionDataTask*)POSTImage:(NSString*)path image:(UIImage*)image complete:(ABXRequestCompletion)complete;

- (NSURLSessionDataTask*)PUT:(NSString*)path params:(NSDictionary*)params complete:(ABXRequestCompletion)complete;

@end
