//
//  MBLSRuleTableViewCell.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/23/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBLSRuleTableViewCell.h"

@implementation MBLSRuleTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    // The user can only edit the text field when in editing mode.
    [super setEditing:editing animated:animated];
    self.textRight.enabled = editing;
}

-(IBAction)textRightEditingEnded:(id)sender {
    id<MBLSRuleTableViewCellDelegate> cellDelegate = (id<MBLSRuleTableViewCellDelegate>)self.textRight.delegate;
    [cellDelegate ruleCellTextRightEditingEnded: self];
}
@end
