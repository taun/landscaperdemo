//
//  MDBFractalObjectList.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/03/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalObjectList.h"

@interface MDBFractalObjectList ()
@property (readwrite, copy) NSMutableArray *objects;
@end


@implementation MDBFractalObjectList

+(instancetype)newListWithEncodingKey:(NSString *)key
{
    return [[[self class] alloc]initWithEncodingKey: key];
}

#pragma mark - Initializers
- (instancetype)initWithEncodingKey:(NSString *)key
{
    self = [super init];
    
    if (self)
    {
        _encodingKey = key;
        _objects = [[NSMutableArray alloc] init];
    }
    
    return self;
}
- (instancetype)init
{
    return [self initWithEncodingKey: @"ShouldBeSet"];
}

#pragma mark - NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    if (self)
    {
        if ([aDecoder containsValueForKey: @"encodingKey"])
        {
            self.encodingKey = [aDecoder decodeObjectForKey: @"encodingKey"];
            
            if ([aDecoder containsValueForKey: self.encodingKey])
            {
                _objects = [[aDecoder decodeObjectForKey: self.encodingKey] mutableCopy];
            }
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (self.objects && self.encodingKey)
    {
        [aCoder encodeObject: self.encodingKey forKey: @"encodingKey"];
        [aCoder encodeObject: self.objects forKey: self.encodingKey];
    }
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    MDBFractalObjectList* listCopy = [[[self class] alloc] init];
    listCopy.objects = [self.objects mutableCopy];
    return listCopy;
}

#pragma mark - Subscripts
- (NSArray *)objectForKeyedSubscript:(NSIndexSet *)indexes
{
    return [self.objects objectsAtIndexes:indexes];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return self.objects[index];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
    return [self.objects countByEnumeratingWithState: state objects: stackbuf count: len];
}

#pragma mark - Object List Management

- (BOOL)isEmpty
{
    return self.objects.count <= 0;
}

-(BOOL) containsObject:(id)object
{
    return [self.objects containsObject: object];
}

-(id) lastObject
{
    return [self.objects lastObject];
}

-(id) firstObject
{
    return [self.objects firstObject];
}

- (NSInteger)count
{
    return self.objects.count;
}

- (NSInteger)indexOfObject:(id)object
{
    return [self.objects indexOfObject: object];
}

- (void) addObject:(id)additionalObject
{
    [self.objects addObject: additionalObject];
}

- (void) insertObject:(id)object atIndex:(NSInteger)index
{
    [self.objects insertObject: object atIndex: index];
}

- (void) removeObjects:(NSArray *)objectsToRemove
{
    [self.objects removeObjectsInArray: objectsToRemove];
}

-(void) removeObject:(id)objectToRemove
{
    [self.objects removeObject: objectToRemove];
}

- (MDBListOperationInfo)moveObject:(id)object toIndex:(NSInteger)toIndex
{
    NSInteger fromIndex = [self.objects indexOfObject: object];
    
    NSAssert(fromIndex != NSNotFound, @"Moving an item that isn't in this list is undefined.");
    
    [self.objects removeObject: object];
    
    NSInteger normalizedToIndex = toIndex;
    
    if (fromIndex < toIndex) {
        normalizedToIndex--;
    }
    
    [self.objects insertObject: object atIndex: normalizedToIndex];
    
    MDBListOperationInfo moveInfo = {
        .fromIndex = fromIndex,
        .toIndex = normalizedToIndex
    };
    
    return moveInfo;
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [self.objects replaceObjectAtIndex: index withObject: anObject];
}

- (NSArray *)allObjects
{
    return [self.objects copy];
}

#pragma mark - NSObject
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[MDBFractalObjectList class]])
    {
        return [self isEqualToList: object];
    }
    
    return NO;
}

#pragma mark - Equality

- (BOOL)isEqualToList:(MDBFractalObjectList *)list
{
    return [self.objects isEqualToArray: list.objects];
}

@end
