//
//  MBBasicLabelTextTableCell.h
//  FractalScape
//
//  Created by Taun Chapman on 03/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBXibAutolayoutTableCell.h"

@interface MBBasicLabelTextTableCell : MBXibAutolayoutTableCell

@property (nonatomic,weak) IBOutlet UILabel     *textLabel;
@property (nonatomic,weak) IBOutlet UITextField *textField;

@end
