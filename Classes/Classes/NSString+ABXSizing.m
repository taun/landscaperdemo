//
//  NSString+ABXSizing.m
//
//  Created by Stuart Hall on 12/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "NSString+ABXSizing.h"

@implementation NSString (ABXSizing)

- (CGFloat)heightForWidth:(CGFloat)width andFont:(UIFont*)font
{
    CGSize size;
    CGSize constraintSize = CGSizeMake(width, CGFLOAT_MAX);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        size = [self boundingRectWithSize:constraintSize
                                             options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                          attributes:@{NSFontAttributeName:font}
                                             context:nil].size;
    }
    else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        
        size = [self sizeWithFont:font
                           constrainedToSize:constraintSize
                               lineBreakMode:NSLineBreakByWordWrapping];
        
#pragma clang diagnostic pop
    }
#else
    size = [self sizeWithFont:font
                    constrainedToSize:constraintSize
                        lineBreakMode:UILineBreakModeWordWrap];
#endif
    
    return ceil(size.height);
}

- (CGFloat)widthToFitFont:(UIFont*)font
{
    CGSize size;
    CGSize constraintSize = CGSizeMake(CGFLOAT_MAX, font.lineHeight);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        size = [self boundingRectWithSize:constraintSize
                                  options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                               attributes:@{NSFontAttributeName:font}
                                  context:nil].size;
    }
    else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        
        size = [self sizeWithFont:font
                constrainedToSize:constraintSize
                    lineBreakMode:NSLineBreakByTruncatingTail];
        
#pragma clang diagnostic pop
    }
#else
    size = [self sizeWithFont:font
            constrainedToSize:constraintSize
                lineBreakMode:UILineBreakByTruncatingTail];
#endif
    
    return ceil(size.width);
}

@end
