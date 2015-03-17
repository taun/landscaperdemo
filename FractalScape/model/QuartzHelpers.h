//
//  QuartzHelpers.h
//  FractalScape
//
//  Created by Taun Chapman on 01/12/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

@import UIKit;

#ifndef FractalScape_QuartzHelpers_h
#define FractalScape_QuartzHelpers_h



@import QuartzCore;
@import CoreGraphics;


CGPoint CGPointConfineToRect(CGPoint, CGRect);
// Functions used to draw all content
CGColorRef CreateDeviceGrayColor(CGFloat w, CGFloat a);
CGColorRef CreateDeviceRGBColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a);
CGColorRef graphBackgroundColor(void);


/** Creates a CGPattern from a CGImage. */
CGPatternRef CreateImagePattern( CGImageRef image );

/** Creates a CGColor that draws the given CGImage as a pattern. */
CGColorRef CreatePatternColor( CGImageRef image );

CGImageRef GetCGImageNamed( NSString *name );


CGColorRef GetCGPatternFromUIImage( UIImage *uImage );

#endif
