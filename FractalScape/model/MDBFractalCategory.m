//
//  MDBFractalCategory.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/02/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalCategory.h"

@implementation MDBFractalCategory

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"identifier",
                          @"name",
                          nil];
    });
    return keysToBeCopied;
}

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

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        for ( NSString* aKey in [[self class] keysToBeCopied]) {
            id object = [aDecoder decodeObjectForKey: aKey];
            if (object) {
                [self setValue: object forKey: aKey];
            }
        }
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    for ( NSString* aKey in [[self class] keysToBeCopied]) {
        id propertyValue = [self valueForKey: aKey];
        if (propertyValue) {
            [aCoder encodeObject: propertyValue forKey: aKey];
        }
    }
}

#pragma mark - NSObject
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[MDBFractalCategory class]])
    {
        if ([_identifier isEqualToString: [object identifier]]) {
            return YES;
        };
    }
    
    return NO;
}

@end
