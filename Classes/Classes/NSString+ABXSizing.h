//
//  NSString+ABXSizing.h
//  Sample Project
//
//  Created by Stuart Hall on 12/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface NSString (ABXSizing)

- (CGFloat)heightForWidth:(CGFloat)width andFont:(UIFont*)font;
- (CGFloat)widthToFitFont:(UIFont*)font;

@end
