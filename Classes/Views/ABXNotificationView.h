//
//  ABXNotificationView.h
//  Sample Project
//
//  Created by Stuart Hall on 30/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ABXNotificationView;

typedef void (^ABXNotificationViewCallback)(ABXNotificationView *view);

@interface ABXNotificationView : UIView

+ (ABXNotificationView*)show:(NSString*)text
                  actionText:(NSString*)actionText
             backgroundColor:(UIColor*)backgroundColor
                   textColor:(UIColor*)textColor
                 buttonColor:(UIColor*)buttonColor
                inController:(UIViewController*)controller
                 actionBlock:(ABXNotificationViewCallback)actionBlock
                dismissBlock:(ABXNotificationViewCallback)dismissBlock;

+ (void)fetchAndShowInController:(UIViewController*)controller
                 backgroundColor:(UIColor*)backgroundColor
                       textColor:(UIColor*)textColor
                     buttonColor:(UIColor*)buttonColor
                        complete:(void(^)(BOOL shown))complete;

- (void)dismiss;

@end
