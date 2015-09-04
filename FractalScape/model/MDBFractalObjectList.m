//
//  MDBFractalObjectList.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/03/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalObjectList.h"
#import "MDBTileObjectProtocol.h"

@interface MDBFractalObjectList ()
@property (readwrite, copy) NSMutableArray *objects;
@end


@implementation MDBFractalObjectList

+(instancetype)newListFromArray:(NSArray *)array
{
    MDBFractalObjectList* newList = [[self class]new];
    
    [newList addObjectsFromArray: array];
    
    return newList;
}

+(instancetype)newListWithEncodingKey:(NSString *)key
{
    return [[[self class] alloc]initWithEncodingKey: key];
}

-(NSString*)debugDescription
{
    return [_objects debugDescription];
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
    // perform a deep copy so we only have one reference to the contained objects
    for (id object in self.objects) {
        [listCopy addObject: [object copy]];
    }
    return listCopy;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    MDBFractalObjectList* listCopy = [[[self class] alloc] init];
    // perform a deep copy so we only have one reference to the contained objects
    for (id object in self.objects) {
        [listCopy addObject: [object copy]];
    }
    return listCopy;
}

#pragma mark - Subscripts
- (void)getObjects:(__unsafe_unretained id *)aBuffer range:(NSRange)aRange
{
    [self.objects getObjects:(__unsafe_unretained id *)aBuffer range: aRange];
}
- (NSArray *)objectForKeyedSubscript:(NSIndexSet *)indexes
{
    return [self.objects objectsAtIndexes:indexes];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return self.objects[index];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [self objectAtIndexedSubscript: index];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
    return [self.objects countByEnumeratingWithState: state objects: stackbuf count: len];
}

#pragma mark - Object List Management

- (BOOL)isEmpty
{
    BOOL empty = YES;
    
    if (_objects && _objects.count > 0 && ![[_objects firstObject] isDefaultObject]) {
        empty = NO;
    }
    return empty;
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
    if (additionalObject)
    {
        [self willChangeValueForKey: @"allObjects"];
        
        id<MDBTileObjectProtocol> tileObject = [self.objects firstObject];
        if (tileObject && tileObject.isDefaultObject) {
            [self.objects removeObjectAtIndex: 0];
        }
        [self.objects addObject: additionalObject];
        
        [self didChangeValueForKey: @"allObjects"];
    }
}

- (void) addObjectsFromArray:(NSArray *)sourceArray
{
    [self willChangeValueForKey: @"allObjects"];
    
    id<MDBTileObjectProtocol> tileObject = [self.objects firstObject];
    if (tileObject && tileObject.isDefaultObject) {
        [self.objects removeObjectAtIndex: 0];
    }
    [self.objects addObjectsFromArray: sourceArray];
    
    [self didChangeValueForKey: @"allObjects"];
}

- (void) insertObject:(id)object atIndex:(NSInteger)index
{
    [self willChangeValueForKey: @"allObjects"];
    [self.objects insertObject: object atIndex: index];
    [self didChangeValueForKey: @"allObjects"];
}

- (void) removeObjectAtIndex:(NSUInteger)index
{
    [self willChangeValueForKey: @"allObjects"];
    [self.objects removeObjectAtIndex: index];
    [self didChangeValueForKey: @"allObjects"];
}
- (void) removeObjects:(NSArray *)objectsToRemove
{
    [self willChangeValueForKey: @"allObjects"];
    [self.objects removeObjectsInArray: objectsToRemove];
    [self didChangeValueForKey: @"allObjects"];
}

-(void) removeObject:(id)objectToRemove
{
    [self willChangeValueForKey: @"allObjects"];
    [self.objects removeObject: objectToRemove];
    [self didChangeValueForKey: @"allObjects"];
}

- (MDBListOperationInfo)moveObject:(id)object toIndex:(NSInteger)toIndex
{
    [self willChangeValueForKey: @"allObjects"];
    
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
    
    [self didChangeValueForKey: @"allObjects"];
    
    return moveInfo;
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [self willChangeValueForKey: @"allObjects"];
    [self.objects replaceObjectAtIndex: index withObject: anObject];
    [self didChangeValueForKey: @"allObjects"];
}

- (NSArray *)allObjects
{
    return [self.objects copy];
}

-(NSArray *)allObjectsDeepCopy
{
    NSArray *originalObjects = self.allObjects;
    NSMutableArray* newArray = [NSMutableArray arrayWithCapacity: originalObjects.count];
    for (id object in originalObjects)
    {
        [newArray addObject: [object copy]];
    }
    return [newArray copy];
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
