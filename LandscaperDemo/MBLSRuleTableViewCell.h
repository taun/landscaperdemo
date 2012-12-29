//
//  MBLSRuleTableViewCell.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/23/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MBLSRuleTableViewCellDelegate <NSObject>

-(void)ruleCellTextRightEditingEnded:(id)sender;

@end

@interface MBLSRuleTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UITextField*       textLeft;
@property (nonatomic, weak) IBOutlet UITextField*       textRight;

-(IBAction)textRightEditingEnded:(id)sender;

@end
