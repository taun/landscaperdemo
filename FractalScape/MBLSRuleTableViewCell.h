//
//  MBLSRuleTableViewCell.h
//  FractalScape
//
//  Created by Taun Chapman on 02/23/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import UIKit;

#import "MBXibAutolayoutTableCell.h"

@protocol MBLSRuleTableViewCellDelegate <NSObject>

-(void)ruleCellTextRightEditingEnded:(id)sender;

@end

@interface MBLSRuleTableViewCell : MBXibAutolayoutTableCell

@property (nonatomic, weak) IBOutlet UITextField*       textLeft;
@property (nonatomic, weak) IBOutlet UITextField*       textRight;

-(IBAction)textRightEditingEnded:(id)sender;

@end
