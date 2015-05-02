//
//  ABXFAQViewController.h
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ABXFaq;

@interface ABXFAQViewController : UIViewController

@property (nonatomic, strong) ABXFaq *faq;
@property (nonatomic, assign) BOOL hideContactButton;

+ (void)pushOnNavController:(UINavigationController*)navigationController faq:(ABXFaq*)faq hideContactButton:(BOOL)hideContactButton;

@end
