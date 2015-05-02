//
//  ABXIssue.h
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXModel.h"

@interface ABXIssue : ABXModel

+ (NSURLSessionDataTask*)submit:(NSString*)email
                       feedback:(NSString*)feedback
                    attachments:(NSArray*)attachments
                       metaData:(NSDictionary*)metaData
                       complete:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete;

@end
