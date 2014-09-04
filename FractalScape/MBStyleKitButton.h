//
//  MBStyleKitButton.h
//  FractalScape
//
//  Created by Taun Chapman on 09/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBStyleKitButton : UIButton

@property (strong,nonatomic) NSString   *ruleCode;

// Set defaultImage to PaintCode StyleKit image
-(void) setImage:(UIImage *)image;

@end
