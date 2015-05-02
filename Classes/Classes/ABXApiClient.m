//
//  ABXApiClient.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXApiClient.h"

#import "NSDictionary+ABXQueryString.h"
#import "NSDictionary+ABXNSNullAsNull.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <netdb.h>

@interface ABXApiClient ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, copy) NSString *apiKey;

@end

@implementation ABXApiClient

static NSString *kAppbotUrl = @"https://api.appbot.co/v1";

+ (ABXApiClient*)instance
{
    static dispatch_once_t onceToken;
    static ABXApiClient *client = nil;
    dispatch_once(&onceToken, ^{
        client = [[ABXApiClient alloc] init];
    });
    return client;
}

#pragma mark - Api Key

- (void)setApiKey:(NSString *)apiKey
{
    _apiKey = apiKey;
    
    // Initialise
    [self GET:@"app"
       params:[self combineDefaultParamsWith:@{}]
     complete:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error, id JSON) {
     }];
}

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        // Setup the request queue
        self.queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        
        // Setup our session
        self.session = [NSURLSession sessionWithConfiguration:nil delegate:nil delegateQueue:_queue];
    }
    return self;
}

#pragma mark - Requests

- (NSURLSessionDataTask*)GET:(NSString*)path params:(NSDictionary*)params complete:(ABXRequestCompletion)complete
{
    NSDictionary *parameters = [self combineDefaultParamsWith:params];
    
    // Create our URL
    NSURL *url = [[NSURL URLWithString:kAppbotUrl] URLByAppendingPathComponent:path];
    NSString *query = [parameters queryStringValue];
    url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:url.query ? @"&%@" : @"?%@", query]];
    
    // Create the request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allowsCellularAccess = YES;
    request.HTTPMethod = @"GET";
    return [self performRequest:request complete:complete];
}

- (NSURLSessionDataTask*)POST:(NSString*)path params:(NSDictionary*)params complete:(ABXRequestCompletion)complete
{
    return [self httpBodyRequest:@"POST" path:path params:params complete:complete];
}

- (NSURLSessionDataTask*)PUT:(NSString*)path params:(NSDictionary*)params complete:(ABXRequestCompletion)complete
{
    return [self httpBodyRequest:@"PUT" path:path params:params complete:complete];
}

- (NSURLSessionDataTask*)POSTImage:(NSString*)path image:(UIImage*)image complete:(ABXRequestCompletion)complete
{
    NSDictionary *parameters = [self combineDefaultParamsWith:@{}];
    
    // Create our URL
    NSURL *url = [[NSURL URLWithString:kAppbotUrl] URLByAppendingPathComponent:path];
    NSString *query = [parameters queryStringValue];
    url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:url.query ? @"&%@" : @"?%@", query]];
    
    // Request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allowsCellularAccess = YES;
    request.HTTPMethod = @"POST";
    
    // Boundary
    NSString *boundary = @"0Xdfdfegsdfsd6fRD";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // Attachment body
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@.png\"\r\n", [[NSUUID UUID] UUIDString]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:UIImagePNGRepresentation(image)];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
    
    return [self performRequest:request complete:complete];
}

- (NSURLSessionDataTask*)httpBodyRequest:(NSString*)method path:(NSString*)path params:(NSDictionary*)params complete:(ABXRequestCompletion)complete
{
    NSDictionary *parameters = [self combineDefaultParamsWith:params];
    
    // Create our URL
    NSURL *url = [[NSURL URLWithString:kAppbotUrl] URLByAppendingPathComponent:path];
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    
    // Create the request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
    NSError *error = nil;
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error]];
    if (error) {
        // Error setting the HTTP body
        if (complete) {
            complete(ABXResponseCodeErrorEncoding, -1, error, nil);
        }
        return nil;
    }
    else {
        request.allowsCellularAccess = YES;
        request.HTTPMethod = method;
        return [self performRequest:request complete:complete];
    }
}

- (NSURLSessionDataTask*)performRequest:(NSURLRequest*)request complete:(ABXRequestCompletion)complete
{
    // https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/TransitionGuide/SupportingEarlieriOS.html#//apple_ref/doc/uid/TP40013174-CH14-SW1
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // iOS 6.1 and below
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:self.queue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [self handleResponse:response data:data error:error complete:complete];
                               }];
        return nil;
    }
    else {
        // iOS 7
        NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                         [self handleResponse:response data:data error:error complete:complete];                                                     }];
        [task resume];
        return task;
    }
}

- (void)handleResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error complete:(ABXRequestCompletion)complete
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger httpCode = [httpResponse statusCode];
    if (httpCode >= 200 && httpCode < 300) {
        [self handleRequestSuccess:httpCode data:data complete:complete];
    }
    else {
        [self handleRequestFailure:httpCode error:error complete:complete];
    }
}

- (void)handleRequestSuccess:(NSInteger)httpCode data:(NSData*)data complete:(ABXRequestCompletion)complete
{
    NSError *jsonError = nil;
    NSDictionary *json = nil;
    
    if (data != nil && data.length > 0) {
        json = [NSJSONSerialization JSONObjectWithData:data
                                               options:0
                                                 error:&jsonError];
    }
    
    if (jsonError) {
        // JSON error
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(ABXResponseCodeErrorDecoding, httpCode, jsonError, nil);
            });
        }
    }
    else {
        // Success!
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(ABXResponseCodeSuccess, httpCode, nil, json);
            });
        }
    }
}

- (void)handleRequestFailure:(NSInteger)httpCode error:(NSError*)error complete:(ABXRequestCompletion)complete
{
    // Work out which error code
    ABXResponseCode responseCode = ABXResponseCodeErrorUnknown;
    switch (httpCode) {
        case 401:
            responseCode = ABXResponseCodeErrorAuth;
            break;
            
        case 402:
            responseCode = ABXResponseCodeErrorExpired;
            break;
    }
    
    if (complete) {
        dispatch_async(dispatch_get_main_queue(), ^{
            complete(responseCode, httpCode, error, nil);
        });
    }
}

#pragma mark - Key

- (void)validateApiKey
{
    // The API key must always be set
    assert(_apiKey);
    if (_apiKey == nil || _apiKey.length == 0) {
        NSException* myException = [NSException
                                    exceptionWithName:@"InvalidKeyException"
                                    reason:@"Key is not valid."
                                    userInfo:nil];
        @throw myException;
    }
}

#pragma mark - Params

- (NSDictionary*)combineDefaultParamsWith:(NSDictionary*)params
{
    [self validateApiKey];
    
    NSDictionary *defaultParams =  @{ @"bundle_identifier" : [[NSBundle mainBundle] bundleIdentifier],
                                      @"key" : _apiKey };
    if (params == nil) {
        // If there are no other params just use they key and bundle
        return defaultParams;
    }
    else {
        // Append the default values
        NSMutableDictionary *mutableParams = [params mutableCopy];
        [mutableParams addEntriesFromDictionary:defaultParams];
        return mutableParams;
    }
}

+ (BOOL)isInternetReachable
{
    // http://stackoverflow.com/a/18071526
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *) &zeroAddress);
    
    SCNetworkReachabilityFlags flags;
    if (reachabilityRef && SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
            // if target host is not reachable
            CFRelease(reachabilityRef);
            return NO;
        }
        
        if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
            // if target host is reachable and no connection is required
            //  then we'll assume (for now) that your on Wi-Fi
            CFRelease(reachabilityRef);
            return YES; // This is a wifi connection.
        }
        
        
        if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0)
             ||(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
            // ... and the connection is on-demand (or on-traffic) if the
            //     calling application is using the CFSocketStream or higher APIs
            
            if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                // ... and no [user] intervention is needed
                CFRelease(reachabilityRef);
                return YES; // This is a wifi connection.
            }
        }
        
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
            // ... but WWAN connections are OK if the calling application
            //     is using the CFNetwork (CFSocketStream?) APIs.
            CFRelease(reachabilityRef);
            return YES; // This is a cellular connection.
        }
    }
    
    return NO;
}

@end
