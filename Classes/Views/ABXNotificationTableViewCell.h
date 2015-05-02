//
//  ABXNotificationTableViewCell.h
//  Sample Project
//
//  Created by Stuart Hall on 18/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ABXNotification.h"
#import "ABXVersion.h"
#import "ABXVersionsViewController.h"

@interface ABXNotificationTableViewCell : UITableViewCell

@property (nonatomic, strong) ABXNotification *notification;

+ (CGFloat)heightForNotification:(ABXNotification*)notification withWidth:(CGFloat)width;

@end
