//
//  MDBFractalObjectList.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/03/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;


typedef struct MDBListOperationInfo {
    NSInteger fromIndex;
    NSInteger toIndex;
} MDBListOperationInfo;

/*!
 Acts as a mutable ordered collection. Class for dealing with the collection aspect of the rules and colors. Hides the implementation details so
 the viewer classes don't need to know whether the implementation is an array, ordered set, ...
 
 KVO: Observer key "allObjects" to be notified of changes to the collection.
 */
@interface MDBFractalObjectList : NSObject <NSCoding, NSCopying, NSFastEnumeration>

@property (nonatomic, readonly) NSArray*    allObjects;
@property (readonly) NSInteger              count;
@property (readonly, getter=isEmpty) BOOL   empty;
@property () NSString*                      encodingKey;

+ (instancetype)newListWithEncodingKey: (NSString*)key;
- (instancetype)initWithEncodingKey: (NSString*)key;
- (instancetype)init;

- (void)getObjects: (__unsafe_unretained id *)aBuffer range:(NSRange)aRange;
- (id) objectAtIndexedSubscript:(NSUInteger)index;
- (id) objectAtIndex:(NSUInteger)index;
- (NSArray *) objectForKeyedSubscript:(NSIndexSet *)indexes;
- (NSInteger) indexOfObject:(id)object;
- (void) addObject: (id)additionalObject;
- (void) addObjectsFromArray: (NSArray*)sourceArray;
- (void) insertObject:(id)object atIndex:(NSInteger)index;
//- (BOOL) canMoveObject:(id)object toIndex:(NSInteger)index inclusive:(BOOL)inclusive;
- (MDBListOperationInfo) moveObject:(id)object toIndex:(NSInteger)toIndex;
- (void) removeObjectAtIndex: (NSUInteger)index;
- (void) removeObjects:(NSArray *)objectsToRemove;
- (void) removeObject: (id)objectToRemove;
- (BOOL) isEqualToList:(MDBFractalObjectList *)list;
- (BOOL) containsObject: (id)object;
- (id) lastObject;
- (id) firstObject;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
@end
