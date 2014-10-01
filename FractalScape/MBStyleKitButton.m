//
//  MBStyleKitButton.m
//  FractalScape
//
//  Created by Taun Chapman on 09/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBStyleKitButton.h"

NSString* kKBBackgroundImage = @"kBKeyBackgroundLight";

@implementation MBStyleKitButton

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        //
//        [self setupAppearance];
        [self removeLabel];
    }
    return self;
}

-(instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //
        [self setupAppearance];
        [self removeLabel];
    }
    return self;
}

-(void) setImage:(UIImage *)image {
    [self setImage: image forState: UIControlStateNormal];
}

// Not used, just use IB
-(void) setupAppearance {
    [self setBackgroundImage: [UIImage imageNamed: kKBBackgroundImage] forState: UIControlStateNormal];
}

// Move label to internal property so the button just has image but label can be shown in IB for layout
-(void) removeLabel {
    NSString* labelText = self.titleLabel.text;
    
    if (labelText) {
        self.ruleCode = labelText;
        [self setTitle: nil forState: UIControlStateNormal];
    }
}
@end
