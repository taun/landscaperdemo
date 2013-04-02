//
//  LSReplacementRule.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSFractal;

@interface LSReplacementRule : NSManagedObject

@property (nonatomic, retain) NSString * contextString;
@property (nonatomic, retain) NSString * replacementString;
@property (nonatomic, retain) NSSet *lsFractal;
@end

@interface LSReplacementRule (CoreDataGeneratedAccessors)

- (void)addLsFractalObject:(LSFractal *)value;
- (void)removeLsFractalObject:(LSFractal *)value;
- (void)addLsFractal:(NSSet *)values;
- (void)removeLsFractal:(NSSet *)values;

@end
