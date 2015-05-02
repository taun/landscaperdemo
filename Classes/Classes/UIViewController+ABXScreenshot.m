//
//  UIViewController+ABXScreenshot.m
//  Sample Project
//
//  Created by Stuart Hall on 30/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "UIViewController+ABXScreenshot.h"

@implementation UIViewController (ABXScreenshot)

- (UIImage*)takeScreenshot
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(self.view.window.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(self.view.window.bounds.size);
    
    if ([self.view.window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        // iOS 7
        [self.view.window drawViewHierarchyInRect:self.view.window.bounds afterScreenUpdates:YES];
    }
    else {
        // Old school
        [self.view.window.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
