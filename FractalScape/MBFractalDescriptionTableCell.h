//
//  MBFractalDescriptionTableCell.h
//  FractalScape
//
//  Created by Taun Chapman on 10/30/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "MBXibAutolayoutTableCell.h"

@interface MBFractalDescriptionTableCell : MBXibAutolayoutTableCell

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end
