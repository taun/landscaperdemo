//
//  MBStyleKitButton.h
//  FractalScape
//
//  Created by Taun Chapman on 09/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//




@interface MBStyleKitButton : UIButton

@property (strong,nonatomic) NSString   *ruleCode;

// Set defaultImage to PaintCode StyleKit image
// NOT used due to using actual images to better see view in IB
-(void) setImage:(UIImage *)image;

@end
