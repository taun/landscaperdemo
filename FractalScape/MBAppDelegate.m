//
//  MBAppDelegate.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBAppDelegate.h"
#import "LSFractal+addons.h"
#import "LSReplacementRule.h"
#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"
#import "MBColor+addons.h"

#import "MBLSFractalEditViewController.h"

static const BOOL ERASE_CORE_DATA = YES;


@interface MBAppDelegate ()
@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (void)registerDefaults;

-(id) plistFileToObject: (NSString*) plistFileName;

-(void)loadMBColorsPList: (NSString*) plist;
-(LSDrawingRuleType*)loadLSDrawingRuleTypeFromPListDictionary: (NSDictionary*) plistDictRuleType;
-(NSInteger)loadRules: (NSDictionary*)rulesDict forType: (LSDrawingRuleType*) ruleType;
-(void)loadLSDrawingRulesPList: (NSString*) plist;
-(LSFractal*)loadLSFractalsPListAndReturnLastSelected: (NSString*) plist;

@end

@implementation MBAppDelegate

@synthesize window = _window;

+ (void)registerDefaults
{
    /*  */
    
//    NSString *pathStr = [[NSBundle mainBundle] bundlePath];
    //        NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
//    NSString *finalPath = [pathStr stringByAppendingPathComponent:@"Root.plist"];
    
//    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
//    NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];
//    
//    NSNumber *difficultyLevel = @0;
//    NSNumber *volume = @1.0;
//    NSNumber *theme = @0;
//    NSNumber *showIntro = @YES;
//    NSNumber *resetHighScores = @NO;
//    
//    NSMutableArray* highScores = [NSMutableArray array];
    
//    NSDictionary *prefItem;
//    for (prefItem in prefSpecifierArray)
//    {
//        NSString *keyValueStr = [prefItem objectForKey:@"Key"];
//        id defaultValue = [prefItem objectForKey:@"DefaultValue"];
//        
//        if ([keyValueStr isEqualToString:kLastEditedFractalURI])
//        {
//            difficultyLevel = defaultValue;
//        }
//        else if ([keyValueStr isEqualToString:kVolumeKey])
//        {
//            volume = defaultValue;
//        }
//        else if ([keyValueStr isEqualToString:kThemeKey])
//        {
//            theme = defaultValue;
//        }
//        else if ([keyValueStr isEqualToString:kShowIntroKey])
//        {
//            showIntro = defaultValue;
//        }
//        else if ([keyValueStr isEqualToString:kResetScoresKey])
//        {
//            resetHighScores = defaultValue;
//        }
//        else if ([keyValueStr isEqualToString:kHighScoresKey])
//        {
//            NSUInteger count = [[prefItem objectForKey:@"Values"] unsignedIntegerValue];
//            for (int i = 0; i < count; i++) {
//                [highScores addObject: @0];
//            }
//        }
//    }
//    
//    // since no default values have been set, create them here
//    NSDictionary *appDefaults =  [NSDictionary dictionaryWithObjectsAndKeys:
//                                  difficultyLevel, kDifficultyLevelKey,
//                                  volume, kVolumeKey,
//                                  theme, kThemeKey,
//                                  showIntro, kShowIntroKey,
//                                  highScores, kHighScoresKey,
//                                  resetHighScores, kResetScoresKey,
//                                  nil];
//    
//    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
//    if (![self coreDataDefaultsExist]) {
//        [self addDefaultCoreDataData];
//    }
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    // order of loading is important
    // colors are needed by fractals so need to be loaded before fractals
    [self loadMBColorsPList: @"MBColorsList"];
    // rules are needed by fractals so need to be loaded before fractals
    [self loadLSDrawingRulesPList: @"LSDrawingRulesDefaultTypeList"];
    // fractals should always be loaded last
    LSFractal* selectedFractal = [self loadLSFractalsPListAndReturnLastSelected: @"LSFractalsList"];
    
    
    [(MBLSFractalEditViewController*)self.window.rootViewController setFractal: selectedFractal];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self saveContext];
}

//-(BOOL)coreDataDefaultsExist {
//    BOOL result = NO;
//    
//    NSManagedObjectContext* context = self.managedObjectContext;
//    
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LSFractal" inManagedObjectContext:context];
//    [fetchRequest setEntity:entity];
//    
//    NSError *error = nil;
//    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
//    if (fetchedObjects == nil) {
//        // TODO: error handling
//    } else if ([fetchedObjects count]>0){
//        // really basic test, could be much more complete
//        result = YES;
//    }
//    
//    return result;
//}

/*
 utility method to return the contents of a plist
 */
-(id) plistFileToObject:(NSString *)plistFileName {
    NSError* error;
    
    NSString* plistPath = [[NSBundle mainBundle] pathForResource: plistFileName ofType: @"plist"];
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath: plistPath];

    id tempDefaults = [NSPropertyListSerialization propertyListWithData: plistXML
                                                                options: 0
                                                                 format: NULL
                                                                  error: &error];
    
    if (!tempDefaults) {
        NSLog(@"Error reading plist: %@", error);
    }
    return tempDefaults;
}

-(LSDrawingRuleType*)loadLSDrawingRuleTypeFromPListDictionary: (NSDictionary*) plistDictRuleType {
    LSDrawingRuleType* ruleType = nil;
    
    if (plistDictRuleType) {
        NSManagedObjectContext* context = self.managedObjectContext;
        
        ruleType = [LSDrawingRuleType findRuleTypeWithIdentifier: plistDictRuleType[@"identifier"] inContext: context];
       
        if (!ruleType) {
            ruleType = [NSEntityDescription
                           insertNewObjectForEntityForName:@"LSDrawingRuleType"
                           inManagedObjectContext: context];
            for (id propertyKey in plistDictRuleType) {
                [ruleType setValue: plistDictRuleType[propertyKey] forKey: propertyKey];
            }            
        }
    }
    [self saveContext];
    return ruleType;
}

-(NSInteger)loadRules: (NSDictionary*)rulesDict forType: (LSDrawingRuleType*) ruleType {
    NSInteger addedRulesCount = 0;
    
    if (ruleType && rulesDict) {
        NSManagedObjectContext* context = self.managedObjectContext;
        
        
        NSSet* currentDefaultRules = [ruleType.rules copy];
        // COuld convert set to dictionary and ise a lookup to detect existence but not worth it for a few rules.
        for (NSString* key in rulesDict) {
            BOOL alreadyExists = NO;
            
            for (NSManagedObject* existingRuleObject in currentDefaultRules) {
                if ([existingRuleObject isKindOfClass: [LSDrawingRule class]]) {
                    LSDrawingRule* existingRule = (LSDrawingRule*)existingRuleObject;
                    if ([existingRule.productionString isEqualToString: key]) {
                        alreadyExists = YES;
                    }
                }
            }
            if (!alreadyExists) {
                LSDrawingRule *newDrawingRule = [NSEntityDescription
                                                 insertNewObjectForEntityForName:@"LSDrawingRule"
                                                 inManagedObjectContext: context];
                newDrawingRule.type = ruleType;
                newDrawingRule.productionString = key;
                newDrawingRule.drawingMethodString = rulesDict[key];
                addedRulesCount += 1;
            }
        }
//        NSLog(@"Type: %@; Existing Rules: %@", ruleType, currentDefaultRules);
//        NSLog(@"Type: %@; All Rules: %@", ruleType, ruleType.rules);
    }
    [self saveContext];
    return addedRulesCount;
}
/*
 rules plist must have a root dictionary with two subDictionaries
 1) ruleType - key/values for the ruleType for all of the included rules
 2) rules - key/values for the rules
 */
-(void)loadLSDrawingRulesPList: (NSString*) plistFileName {
    
    id plistObject = [self plistFileToObject: plistFileName];
    
    if (![plistObject isKindOfClass: [NSDictionary class]] || ([plistObject count] < 2)) {
        NSLog(@"Error plistObject should be an dictionary with size > 1. is: %@", plistObject);
        return;
    }

    NSDictionary* plistRulesDict = (NSDictionary*)plistObject;
    NSDictionary* plistRuleType = [plistRulesDict objectForKey: @"ruleType"];
    NSDictionary* plistRules = [plistRulesDict objectForKey: @"rules"];
    
    LSDrawingRuleType* ruleType = [self loadLSDrawingRuleTypeFromPListDictionary: plistRuleType];
    
    NSInteger addRulesCount = [self loadRules: plistRules forType: ruleType];
    
    NSLog(@"Added %d rules.", addRulesCount);
}
/*
 MBColors plist must have a root array full of MBColor dictionary entries.
 Dictionary keys must be MBColor property names so setValue:forKey: can be used.
 */
-(void) loadMBColorsPList: (NSString*) plistFileName {
    
    id plistObject = [self plistFileToObject: plistFileName];
    
    if (![plistObject isKindOfClass: [NSArray class]] || ([plistObject count] == 0)) {
        NSLog(@"Error plistObject should be an array with size > 1. is: %@", plistObject);
        return;
    }


    NSArray* colorArray = (NSArray*) plistObject;
    
    if (colorArray) {
        NSManagedObjectContext* context = self.managedObjectContext;
        
        for (NSDictionary* colorDict in colorArray) {
            if ([colorDict isKindOfClass: [NSDictionary class]]) {
                
                // only create new color if one with identifier doesn't already exist
                NSString* identifier = [colorDict objectForKey: @"identifier"];
                if ([MBColor findMBColorWithIdentifier: identifier inContext: context] == nil) {
                    MBColor* newColor = [NSEntityDescription
                                         insertNewObjectForEntityForName:@"MBColor"
                                         inManagedObjectContext: context];
                    
                    
                    for (id propertyKey in colorDict) {
                        [newColor setValue: colorDict[propertyKey] forKey: propertyKey];
                    }
                }
            }
        }
    }
    [self saveContext]; // save colors for access by addDefaultLSFractals...
}

/*
 Fractals plist is a root array full or fractal dictionaries.
 */
-(LSFractal*)loadLSFractalsPListAndReturnLastSelected: (NSString*) plistFileName {
    
    id plistObject = [self plistFileToObject: plistFileName];
    
    if (![plistObject isKindOfClass: [NSArray class]] || ([plistObject count] == 0)) {
        NSLog(@"Error plistObject should be an array with size > 1. is: %@", plistObject);
        return nil;
    }
    
    NSArray* fractalList = (NSArray*) plistObject;
    
    LSFractal* defaultFractal;
    LSFractal* lastFractal;
    
    if (fractalList) {
        LSDrawingRuleType* defaultDrawingRuleType = [self loadLSDrawingRulesPListAndReturnDefaultRuleType];
        
        NSManagedObjectContext* context = self.managedObjectContext;
        
        NSArray* fractals = defaults[@"InitialLSFractals"];
        
        @"drawingRulesType.identifier";
        
        if ([fractals isKindOfClass:[NSArray class]]) {
            
            for (id fractalDictionary in fractals) {
                if ([fractalDictionary isKindOfClass: [NSDictionary class]]) {
                    // create the fractal
                    
                    // only create new fractal if one with identifier doesn't already exist
                    NSString* fractalName = [fractalDictionary objectForKey: @"name"];
                    if ([LSFractal findFractalWithName: fractalName inContext: context] == nil) {
                        LSFractal* fractal = [NSEntityDescription
                                              insertNewObjectForEntityForName:@"LSFractal"
                                              inManagedObjectContext: context];
                        
                        fractal.drawingRulesType = defaultDrawingRuleType;
                        lastFractal = fractal;
                        
                        for (id propertyKey in fractalDictionary) {
                            id propertyValue = fractalDictionary[propertyKey];
                            
                            if ([propertyValue isKindOfClass:[NSDictionary class]]) {
                                // dictionary is replacement rules
                                for (id replacementKey in propertyValue) {
                                    // create replacement rules and assign to fractal
                                    LSReplacementRule *newReplacementRule = [NSEntityDescription
                                                                             insertNewObjectForEntityForName:@"LSReplacementRule"
                                                                             inManagedObjectContext: context];
                                    
                                    newReplacementRule.contextString = replacementKey;
                                    newReplacementRule.replacementString = propertyValue[replacementKey];
                                    [fractal addReplacementRulesObject: newReplacementRule];
                                }
                            } else {
                                // all but dictionaries should be key value
                                [fractal setValue: propertyValue forKey: propertyKey];
                            }
                        }
                    }
                    
                }
            }
        }
        
        [self saveContext];
    }
    // What if the kLastEditedFractalURI is missing and yet defaults don't need to be loaded?
    // Then defaultFractal will be nil.
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSURL* selectedFractalURL = [userDefaults URLForKey: kLastEditedFractalURI];
    if (selectedFractalURL == nil) {
        // use a default
        defaultFractal = lastFractal;
    } else {
        // instantiate the saved default URI
        NSPersistentStoreCoordinator* store = self.managedObjectContext.persistentStoreCoordinator;
        NSManagedObjectID* objectID = [store managedObjectIDForURIRepresentation: selectedFractalURL];
        if (objectID != nil) {
            defaultFractal = (LSFractal*)[self.managedObjectContext objectWithID: objectID];
        } else {
            defaultFractal = lastFractal;
        }
    }
    return defaultFractal;
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"FSLibrary" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"FSLibrary.sqlite"];
    
    // for development, always delete the store first
    // will force load of defaults
    if (ERASE_CORE_DATA) {
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    }
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
