//
//  ABXTextView.m
//  Sample Project
//
//  Created by Stuart Hall on 30/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXTextView.h"

@interface ABXTextView ()

@property (nonatomic, assign) BOOL didDrawPlaceholder;

@end

@implementation ABXTextView

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self setup];
	}
	return self;
}


- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
    {
		[self setup];
	}
	return self;
}

- (void)setup
{
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setNeedsDisplay)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)textDidChange:(NSNotification*)notification
{
    if (self.didDrawPlaceholder || self.text.length == 0) {
        [self setNeedsDisplay];
    }
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
    
	if (self.text.length == 0 && self.placeholder) {
        self.didDrawPlaceholder = YES;
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
            CGRect rect = CGRectInset(self.bounds, 4, 8);
            [self.placeholder drawInRect:rect
                          withAttributes:@{ NSFontAttributeName : self.font,
                                            NSForegroundColorAttributeName : [UIColor colorWithWhite:0.8 alpha:1]}];
        }
        else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
            CGRect rect = CGRectInset(self.bounds, 8, 8);
            [[UIColor colorWithWhite:0.8 alpha:1] set];
            [self.placeholder drawInRect:rect withFont:self.font];
#pragma clang diagnostic pop            
        }
	}
    else {
        self.didDrawPlaceholder = NO;
    }
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    if (self.didDrawPlaceholder || self.text.length == 0) {
        [self setNeedsDisplay];
    }
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    [self setNeedsDisplay];
}

@end
