//
//  MDBHelpContentsTableViewCell.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/11/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBHelpContentsTableViewCell.h"

@interface MDBHelpContentsTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *pageTitle;

@end


@implementation MDBHelpContentsTableViewCell


-(void)setTitle:(NSString *)title
{
    if ([_title isEqualToString: title])
    {
        _title = title;
        self.pageTitle.text = _title;
        [self setNeedsLayout];
    }
}


@end
