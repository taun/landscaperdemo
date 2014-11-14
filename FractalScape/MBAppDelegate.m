//
//  MBAppDelegate.m
//  FractalScape
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
#import "MBColorCategory+addons.h"
#import "NSManagedObject+Shortcuts.h"

#import "MBLSFractalEditViewController.h"


@interface MBAppDelegate ()
@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (void)registerDefaults;

-(id) plistFileToObject: (NSString*) plistFileName;

-(void)loadMBColorsPList: (NSString*) plist;
-(LSDrawingRuleType*)loadLSDrawingRuleTypeFromPListDictionary: (NSDictionary*) plistDictRuleType;
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
            ruleType = [LSDrawingRuleType insertNewObjectIntoContext: context];
            for (id propertyKey in plistDictRuleType) {
                [ruleType setValue: plistDictRuleType[propertyKey] forKey: propertyKey];
            }            
        }
    }
    [self saveContext];
    return ruleType;
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
    NSDictionary* plistRuleType = plistRulesDict[@"ruleType"];
//    NSDictionary* plistRules = plistRulesDict[@"rules"];
    NSArray* plistRulesArray = plistRulesDict[@"rulesArray"];
    
    LSDrawingRuleType* ruleType = [self loadLSDrawingRuleTypeFromPListDictionary: plistRuleType];
    
    long addRulesCount = [ruleType loadRulesFromPListRulesArray: plistRulesArray];
    
    NSLog(@"Added %ld rules.", addRulesCount);
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


    NSArray* colorCategoriesArray = (NSArray*) plistObject;
    
    if (colorCategoriesArray) {
        NSManagedObjectContext* context = self.managedObjectContext;
        
        for (NSDictionary* colorCategoryDict in colorCategoriesArray) {
            if ([colorCategoryDict isKindOfClass: [NSDictionary class]]) {
                
                // only create new color if one with identifier doesn't already exist
                NSString* identifier = colorCategoryDict[@"identifier"];
                MBColorCategory* colorCategory = [MBColorCategory findCategoryWithIdentifier: identifier inContext: context];
                if (colorCategory == nil) {
                    colorCategory = [MBColorCategory insertNewObjectIntoContext: context];
                    
                    colorCategory.identifier = identifier;
                    colorCategory.name = colorCategoryDict[@"name"];
                    colorCategory.descriptor = colorCategoryDict[@"descriptor"];
                    
                }
                NSArray* colorsArray = colorCategoryDict[@"colors"];
                if (colorCategory && colorsArray.count > 0) {
                    [colorCategory loadColorsFromPListColorsArray: colorsArray];
                }
            }
        }
    }
    [self saveContext]; // save colors for access by addDefaultLSFractals...
}

- (void)addObjectFrom:(NSDictionary *)availableObjects usingKeysInString:(NSString *)keyString toCollection:(NSMutableOrderedSet *)collection {
    NSString* key;
    id newObject;
    for (int y=0; y < keyString.length; y++) {
        //
        key = [keyString substringWithRange: NSMakeRange(y, 1)];
        
        newObject = availableObjects[key];
        
        if (newObject) {
            [collection addObject: newObject];
        }
    }
}

- (void)copyObjectFrom:(NSDictionary *)availableObjects usingKeysInString:(NSString *)keyString toCollection:(NSMutableOrderedSet *)collection {
    NSString* key;
    id newObject;
    for (int y=0; y < keyString.length; y++) {
        //
        key = [keyString substringWithRange: NSMakeRange(y, 1)];
        
        newObject = availableObjects[key];
        
        if (newObject) {
            [collection addObject: [newObject mutableCopy]];
        }
    }
}

/*
 Fractals plist is a root array full of fractal dictionaries.
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
        NSManagedObjectContext* context = self.managedObjectContext;
    
        LSDrawingRuleType* fractalDrawingRuleType;
        
        
        //NSArray* fractals = defaults[@"InitialLSFractals"];
        
        //@"drawingRulesType.identifier";
        
            
        for (id fractalDictionary in fractalList) {
            if ([fractalDictionary isKindOfClass: [NSDictionary class]]) {
                // create the fractal
                
                // only create new fractal if one with identifier doesn't already exist
                NSString* fractalName = fractalDictionary[@"name"];
                if ([LSFractal findFractalWithName: fractalName inContext: context] == nil) {
                    LSFractal* fractal = [LSFractal insertNewObjectIntoContext: context];
                    
                    //fractalDrawingRuleType = [LSDrawingRuleType findRuleTypeWithIdentifier: [fractalDictionary objectForKey: @"drawingRulesType.identifier"] inContext: self.managedObjectContext];
                    //fractal.drawingRulesType = fractalDrawingRuleType;
                    lastFractal = fractal;
                    
                    // handle special cases
                    NSMutableDictionary* mutableFractalDictionary = [fractalDictionary mutableCopy];
                    
                    // need rules type before we can handle starting rules and replacement rules
                    NSString* rulesTypeString = mutableFractalDictionary[@"drawingRulesType.identifier"];
                    if (rulesTypeString != nil && rulesTypeString.length > 0) {
                        fractalDrawingRuleType = [LSDrawingRuleType findRuleTypeWithIdentifier: rulesTypeString inContext: self.managedObjectContext];
                        fractal.drawingRulesType = fractalDrawingRuleType;
                        [mutableFractalDictionary removeObjectForKey: @"drawingRulesType.identifier"];
                    }
                    
                    NSDictionary* availableRules = [fractal.drawingRulesType rulesDictionary];

                    NSString* startingRulesKey = @"startingRules";
                    NSString* startingRulesString = mutableFractalDictionary[startingRulesKey];
                    if (startingRulesString != nil && rulesTypeString.length > 0) {
                        NSMutableOrderedSet* startingRules = [fractal mutableOrderedSetValueForKey: startingRulesKey];
                        
                        [self copyObjectFrom: availableRules usingKeysInString: startingRulesString toCollection: startingRules];
                        
                        [mutableFractalDictionary removeObjectForKey: startingRulesKey];
                    }
                   
                    NSString* replacementRulesKey = @"replacementRules";
                    NSString* rulesKey = @"rules";
                    NSDictionary* replacementRulesDict = mutableFractalDictionary[replacementRulesKey];
                    if (replacementRulesDict && replacementRulesDict.count > 0) {
                        NSMutableOrderedSet* replacementRules = [fractal mutableOrderedSetValueForKey: replacementRulesKey];
 
                        for (NSString* key in replacementRulesDict) {
                            //
                            LSReplacementRule *newReplacementRule = [LSReplacementRule insertNewObjectIntoContext: context];
                            
                            newReplacementRule.contextRule = availableRules[key];
                            
                            NSMutableOrderedSet* rules = [newReplacementRule mutableOrderedSetValueForKey: rulesKey];
                            NSString* replacementRulesString = replacementRulesDict[key];
                            
                            [self copyObjectFrom: availableRules usingKeysInString: replacementRulesString toCollection: rules];
                            
                            [replacementRules addObject: newReplacementRule];
                        }
                        [mutableFractalDictionary removeObjectForKey: replacementRulesKey];
                    }

                    NSString* lineColorsKey = @"lineColors";
                    NSArray* lineColorsArray = mutableFractalDictionary[lineColorsKey];
                    if (lineColorsArray && lineColorsArray.count > 0) {
                        NSMutableSet* mutableColorsSet = [fractal mutableSetValueForKey: lineColorsKey];
                        
                        NSInteger colorIndex = 0;
                        
                        for (NSDictionary* colorDict in lineColorsArray) {
                            MBColor* newColor = [MBColor newMBColorWithPListDictionary: colorDict inContext: fractal.managedObjectContext];
                            newColor.index = [NSNumber numberWithInteger: colorIndex];
                            colorIndex++;
                            [mutableColorsSet addObject: newColor];
                        }
                        [mutableFractalDictionary removeObjectForKey: lineColorsKey];
                    }
                    
                    NSString* fillColorsKey = @"fillColors";
                    NSArray* fillColorsArray = mutableFractalDictionary[fillColorsKey];
                    if (fillColorsArray && fillColorsArray.count > 0) {
                        NSMutableSet* mutableColorsSet = [fractal mutableSetValueForKey: fillColorsKey];
                        
                        NSInteger colorIndex = 0;
                        
                        for (NSDictionary* colorDict in fillColorsArray) {
                            MBColor* newColor = [MBColor newMBColorWithPListDictionary: colorDict inContext: fractal.managedObjectContext];
                            // the order of colors in the PList array is the index order
                            // if you want to change the color order, change it in the PList.
                            newColor.index = [NSNumber numberWithInteger: colorIndex];
                            colorIndex++;
                           [mutableColorsSet addObject: newColor];
                         }
                        [mutableFractalDictionary removeObjectForKey: fillColorsKey];
                    }
                    
                    for (id propertyKey in mutableFractalDictionary) {
                        id propertyValue = mutableFractalDictionary[propertyKey];
                        // all but dictionaries should be key value
                        [fractal setValue: propertyValue forKey: propertyKey];
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
#ifdef DEBUG
    if ([[[NSProcessInfo processInfo] arguments] containsObject:@"eraseCoreData"]) {
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    }
#endif
    
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
