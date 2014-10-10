//
//  MBFractalTableDataSource.h
//  FractalScape
//
//  Created by Taun Chapman on 10/08/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LSFractal+addons.h"
#import "MBFractalAxiomEditViewController.h"

@interface MBFractalTableDataSource : NSObject <UITableViewDataSource>

@property (nonatomic,weak) NSMutableArray*                                     fractalData;

+(instancetype) newSourceWithFractalData: (NSArray*) fractalData;

-(instancetype) initWithFractalData: (NSArray*) fractal NS_DESIGNATED_INITIALIZER;

-(instancetype) init;

- (IBAction)categoryInputChanged:(id)sender;
- (IBAction)nameInputChanged:(id)sender;

@end