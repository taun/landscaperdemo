//
//  MDBLSObjectTileListAddDeleteView.m
//  FractalScape
//
//  Created by Taun Chapman on 02/09/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBLSObjectTileListAddDeleteView.h"

@implementation MDBLSObjectTileListAddDeleteView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setupSubviews];
    }
    return self;
}

-(void) setupSubviews {
    UIView* view = [[[NSBundle bundleForClass: [self class]] loadNibNamed: NSStringFromClass([self class]) owner: self options: nil] firstObject];
    [self addSubview: view];
    view.frame = self.bounds;
    
#if TARGET_INTERFACE_BUILDER
#endif

    [self setupConstraints];
    
}

-(void) setupConstraints
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

- (IBAction)deletePressed:(id)sender
{
}

- (IBAction)addPressed:(id)sender
{
}
@end
