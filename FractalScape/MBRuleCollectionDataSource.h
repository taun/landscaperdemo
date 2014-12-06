//
//  MBRuleCollectionDataSource.h
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface MBRuleCollectionDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic,strong) NSOrderedSet* rules;

+(instancetype)newWithRules: (NSOrderedSet*) rules;
-(instancetype)initWithRules: (NSOrderedSet*) rules;

@end
