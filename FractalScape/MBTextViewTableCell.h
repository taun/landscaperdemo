//
//  MBTextViewTableCell.h
//  FractalScape
//
//  Created by Taun Chapman on 03/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBXibAutolayoutTableCell.h"

@interface MBTextViewTableCell : MBXibAutolayoutTableCell

@property (nonatomic,weak) IBOutlet UITextView  *textView;

@end
