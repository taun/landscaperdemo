//
//  ABXVersionNotificationView.h
//  Sample Project
//
//  Created by Stuart Hall on 18/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXNotificationView.h"

@interface ABXVersionNotificationView : ABXNotificationView

+ (void)fetchAndShowInController:(UIViewController*)controller
                     foriTunesID:(NSString*)itunesId
                 backgroundColor:(UIColor*)backgroundColor
                       textColor:(UIColor*)textColor
                     buttonColor:(UIColor*)buttonColor
                        complete:(void(^)(BOOL shown))complete;

@end
