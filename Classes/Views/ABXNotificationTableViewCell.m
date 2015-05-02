//
//  ABXNotificationTableViewCell.m
//  Sample Project
//
//  Created by Stuart Hall on 18/06/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXNotificationTableViewCell.h"

#import "ABXNotification.h"

#import "NSString+ABXSizing.h"

@interface ABXNotificationTableViewCell ()

@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *textDetailsLabel;
@property (nonatomic, strong) UIButton *actionButton;

@end

@implementation ABXNotificationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Created date
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, (CGRectGetWidth(self.contentView.bounds) - 30)/2, 30)];
        self.dateLabel.textColor = [UIColor blackColor];
        self.dateLabel.font = [UIFont systemFontOfSize:15];
        self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:self.dateLabel];
        
        // Text
        self.textDetailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 40, CGRectGetWidth(self.contentView.bounds) - 30, 0)];
        self.textDetailsLabel.textColor = [UIColor darkGrayColor];
        self.textDetailsLabel.font = [ABXNotificationTableViewCell detailFont];
        self.textDetailsLabel.numberOfLines = 0;
        self.textDetailsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:self.textDetailsLabel];
        
        // Action button
        self.actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] == NSOrderedAscending) {
            self.actionButton.frame = CGRectMake(20, CGRectGetHeight(self.contentView.bounds) - 38, CGRectGetWidth(self.contentView.bounds) - 40, 32);
        }
        else {
            self.actionButton.frame = CGRectMake(0, CGRectGetHeight(self.contentView.bounds) - 44, CGRectGetWidth(self.contentView.bounds), 44);
        }
        self.actionButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.actionButton addTarget:self action:@selector(onAction) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.actionButton];
    }
    return self;
}

- (void)setNotification:(ABXNotification *)notification
{
    _notification = notification;
    
    static dispatch_once_t onceToken;
    static NSDateFormatter *dateFormatter = nil;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    });
    
    self.dateLabel.text = [dateFormatter stringFromDate:notification.createdAt];
    
    self.textDetailsLabel.text = notification.message;
    [self setNeedsLayout];
    
    if ([notification hasAction]) {
        self.actionButton.hidden = NO;
        [self.actionButton setTitle:notification.actionLabel forState:UIControlStateNormal];
    }
    else {
        self.actionButton.hidden = YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect r = self.textDetailsLabel.frame;
    r.size.height = [self.notification.message heightForWidth:CGRectGetWidth(self.contentView.bounds) - 30 andFont:[ABXNotificationTableViewCell detailFont]];
    self.textDetailsLabel.frame = r;
}

- (void)onAction
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.notification.actionUrl]];
}

+ (UIFont*)detailFont
{
    static dispatch_once_t onceToken;
    static UIFont *font = nil;
    dispatch_once(&onceToken, ^{
        font = [UIFont systemFontOfSize:14];
    });
    return font;
}

+ (CGFloat)heightForNotification:(ABXNotification*)notification withWidth:(CGFloat)width
{
    return [notification.message heightForWidth:width - 30 andFont:[self detailFont]] + 60 + ([notification hasAction] ? 22 : 0);
}

@end
