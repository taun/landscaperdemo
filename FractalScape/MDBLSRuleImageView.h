//
//  MDBLSRuleImageView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LSDrawingRule+addons.h"


IB_DESIGNABLE


@interface MDBLSRuleImageView : UIImageView

@property (nonatomic,strong) LSDrawingRule*             rule;

@property (nonatomic,assign) IBInspectable CGFloat      width;
@property (nonatomic,assign) IBInspectable CGFloat      cornerRadius;
@property (nonatomic,assign) IBInspectable BOOL         showBorder;
@property (nonatomic,assign) IBInspectable BOOL         readOnly;

@end
