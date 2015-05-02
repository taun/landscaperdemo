//
//  ABXAttachment.m
//  Sample Project
//
//  Created by Stuart Hall on 25/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXAttachment.h"

#import "NSDictionary+ABXNSNullAsNull.h"

@implementation ABXAttachment

- (NSURLSessionDataTask*)upload:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    return [[ABXApiClient instance] POSTImage:@"attachments.json"
                                        image:self.image
                                     complete:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error, id JSON) {
                                         self.identifier = [JSON objectForKeyNulled:@"attachment_id"];
                                         if (complete) {
                                             complete(responseCode, httpCode, error);
                                         }
                                     }];
}

@end
