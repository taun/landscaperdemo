//
//  ABXFeedbackViewController.h
//  Sample Project
//
//  Created by Stuart Hall on 30/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ABXFeedbackViewController : UIViewController

@property (nonatomic, copy) NSString *placeholder;

+ (void)showFromController:(UIViewController*)controller
               placeholder:(NSString*)placeholder;

+ (void)showFromController:(UIViewController*)controller
               placeholder:(NSString*)placeholder
                     email:(NSString*)email
                  metaData:(NSDictionary*)metaData
                     image:(UIImage*)image;

@property (nonatomic, copy) NSString *defaultEmail;
@property (nonatomic, strong) NSDictionary *metaData;
@property (nonatomic, strong) UIImage *image;

@end
