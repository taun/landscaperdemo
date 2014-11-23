//
//  MBFractalTableDataSource.h
//  FractalScape
//
//  Created by Taun Chapman on 10/08/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LSFractal+addons.h"
#import "MBLSReplacementRuleTableViewCell.h"
#import "MBLSRuleSourceCollectionTableViewCell.h"
#import "MBLSRuleDestinationCollectionTableViewCell.h"

@interface MBFractalTableDataSource : NSObject <UITableViewDataSource>
/*!
 The LSFractal to use as the source.
 */
@property (nonatomic,weak) LSFractal*                                          fractal;
@property (nonatomic,strong) NSArray*                                          tableSections;
/*!
 Delegate for UIPickerView embedded in table
 */
@property (nonatomic,weak) id<UIPickerViewDelegate>                            pickerDelegate;
/*!
 Data source for UIPickerView embedded in table
 */
@property (nonatomic,weak) id<UIPickerViewDataSource>                          pickerSource;


+(instancetype) newSourceWithFractal: (LSFractal*) fractal tableSections: (NSArray*) sections;

-(instancetype) initWithFractal: (LSFractal*) fractal tableSections: (NSArray*) sections NS_DESIGNATED_INITIALIZER;

-(instancetype) init;

@end
