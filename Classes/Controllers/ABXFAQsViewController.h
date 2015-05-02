//
//  ABXFAQsViewController.h
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ABXBaseListViewController.h"

@interface ABXFAQsViewController : ABXBaseListViewController

+ (void)showFromController:(UIViewController*)controller
         hideContactButton:(BOOL)hideContactButton
           contactMetaData:(NSDictionary*)contactMetaData
             initialSearch:(NSString*)initialSearch;

@property (nonatomic, assign) BOOL hideContactButton;
@property (nonatomic, strong) NSDictionary *contactMetaData;
@property (nonatomic, copy) NSString *initialSearch;

@end
