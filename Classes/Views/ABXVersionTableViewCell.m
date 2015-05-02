//
//  ABXVersionTableViewCell.m
//  Sample Project
//
//  Created by Stuart Hall on 22/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXVersionTableViewCell.h"

#import "ABXVersion.h"
#import "NSString+ABXSizing.h"
#import "NSString+ABXLocalized.h"

@interface ABXVersionTableViewCell ()

@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *textDetailsLabel;

@end

@implementation ABXVersionTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Version number
        self.versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, (CGRectGetWidth(self.contentView.bounds) - 30)/2, 30)];
        self.versionLabel.textColor = [UIColor blackColor];
        self.versionLabel.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:self.versionLabel];
        
        // Release date
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.contentView.bounds), 10, (CGRectGetWidth(self.contentView.bounds) - 30)/2, 30)];
        self.dateLabel.textColor = [UIColor blackColor];
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        self.dateLabel.font = [UIFont systemFontOfSize:15];
        self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:self.dateLabel];
        
        // Text
        self.textDetailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 40, CGRectGetWidth(self.contentView.bounds) - 30, 0)];
        self.textDetailsLabel.textColor = [UIColor darkGrayColor];
        self.textDetailsLabel.font = [ABXVersionTableViewCell detailFont];
        self.textDetailsLabel.numberOfLines = 0;
        self.textDetailsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:self.textDetailsLabel];
    }
    return self;
}

- (void)setVersion:(ABXVersion *)version
{
    _version = version;
    
    self.versionLabel.text = [[[@"Version" localizedString] stringByAppendingString:@" "] stringByAppendingString:version.version];
    
    static dispatch_once_t onceToken;
    static NSDateFormatter *dateFormatter = nil;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    });
    
    self.dateLabel.text = [dateFormatter stringFromDate:version.releaseDate];
    
    self.textDetailsLabel.text = version.text;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect r = self.textDetailsLabel.frame;
    r.size.height = [self.version.text heightForWidth:CGRectGetWidth(self.contentView.bounds) - 30 andFont:[ABXVersionTableViewCell detailFont]];
    self.textDetailsLabel.frame = r;
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

+ (CGFloat)heightForVersion:(ABXVersion*)version withWidth:(CGFloat)width
{
    NSLog(@"- Width : %f", width);
    
    return [version.text heightForWidth:width - 30 andFont:[self detailFont]] + 60;
}

@end
