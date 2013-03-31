//
//  MBAppDelegate.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LSDrawingRuleType;
@class LSFractal;

@interface MBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSDictionary*             lsFractalDefaults;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

//-(BOOL)coreDataDefaultsExist;
//-(void)addDefaultCoreDataData; //obsolete
-(LSDrawingRuleType*)loadDefaultDrawingRules;
-(LSFractal*)addDefaultLSFractals;
-(void)addDefaultColors;

@end
