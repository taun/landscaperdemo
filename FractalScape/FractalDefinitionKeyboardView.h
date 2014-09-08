//
//  FractalDefinitionKeyboardView.h
//  FractalScape
//
//  Created by Taun Chapman on 01/29/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 L-System fractal drawing rules from http://paulbourke.net/fractals/fracintro/
 F: Move forward by line length drawing a line
 f: Move forward by line length without drawing a line
 +: Turn left by turning angle
 -: Turn right by turning angle
 |: Reverse direction (turn by 180)
 [: Push current drawing state onto stack
 ]: Pop current drawing state off stack
 #: Increment the line width by line width increment
 !: Decrement the line width by line width
 @: Draw a dot with line width radius
 {: Open a polygon
 }: Close a polygon and fill with fill color
 >: Multiply the line length by the line length scale factor
 <: Divide the line length by the line length scale factor
 &: Swap the meaning of + and -
 (: Decrement turning angle by turning angle increment
 ): Increment turning angle by turning angle increment
*/

@protocol FractalDefinitionKVCDelegate
- (void)keyTapped:(NSString*)title;
- (void)doneTapped;
@end

@interface FractalDefinitionKeyboardView : UIViewController

@property (nonatomic, weak)  IBOutlet  id<FractalDefinitionKVCDelegate> delegate;

//- (BOOL)loadFractalKeyboardNibFile;

- (IBAction)keyPressed:(UIButton*)sender;

@end
