//
//  MBRuleSourceCollectionDataSource.h
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MBRuleSourceCollectionDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic,strong) NSSet* rules;

@end
