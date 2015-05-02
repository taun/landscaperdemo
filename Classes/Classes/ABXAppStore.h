//
//  ABXAppStore.h
//
//  Created by Stuart Hall on 18/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ABXAppStore : NSObject

+ (void)openAppStoreReviewForApp:(NSString*)itunesId;
+ (void)openAppStoreForApp:(NSString*)itunesId;

@end
