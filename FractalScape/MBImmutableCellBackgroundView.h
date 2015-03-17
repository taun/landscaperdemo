//
//  MBImmutableCellBackgroundView.h
//  FractalScape
//
//  Created by Taun Chapman on 03/28/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "MBColorCellBackgroundView.h"

@interface MBImmutableCellBackgroundView : MBColorCellBackgroundView

@property (nonatomic,assign) BOOL       readOnlyView;

@property (nonatomic,weak) CALayer      *outlineLayer;

@end
