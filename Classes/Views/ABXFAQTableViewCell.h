//
//  ABXFAQTableViewCell.h
//  Sample Project
//
//  Created by Stuart Hall on 15/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ABXFaq;

@interface ABXFAQTableViewCell : UITableViewCell

- (void)setFAQ:(ABXFaq*)faq;

+ (CGFloat)heightForFAQ:(ABXFaq*)faq withWidth:(CGFloat)width;

@end
