//
//  MDBFractalCategory.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/02/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalCategory.h"

@implementation MDBFractalCategory

+(instancetype)newCategoryIdentifier:(NSString *)identifier name:(NSString *)name
{
    id newCategory = [[[self class]alloc]initWithIdentifier: identifier name: name];
    return newCategory;
}

-(instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        _name = name;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithIdentifier: nil name: nil];
}
@end
