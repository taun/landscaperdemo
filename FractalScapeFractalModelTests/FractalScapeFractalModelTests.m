//
//  FractalScapeFractalModelTests.m
//  FractalScapeFractalModelTests
//
//  Created by Taun Chapman on 01/12/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CoreData/CoreData.h>

#import "NSManagedObject+Shortcuts.h"
#import "LSFractal+addons.h"
#import "LSDrawingRule+addons.h"
#import "LSReplacementRule+addons.h"


@interface FractalScapeFractalModelTests : XCTestCase

@property (nonatomic,strong) NSDictionary                  *commandKeyDictionary;
@property (nonatomic,strong) NSDictionary                  *stringCommandDictionary;
@property (nonatomic,strong) NSManagedObjectContext        *managedObjectContext;
@property (nonatomic,strong) NSManagedObjectModel          *managedObjectModel;
@property (nonatomic,strong) NSPersistentStoreCoordinator  *persistentStoreCoordinator;

@end

@implementation FractalScapeFractalModelTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSMutableDictionary* tempKeyDictionary = [NSMutableDictionary new];
    tempKeyDictionary[@"commandDrawLine"] = @"F";
    tempKeyDictionary[@"commandRotateCC"] = @"+";
    tempKeyDictionary[@"commandRotateC"] = @"-";
    tempKeyDictionary[@"commandPush"] = @"[";
    tempKeyDictionary[@"commandPop"] = @"]";
    tempKeyDictionary[@"commandDoNothing"] = @"A";
    
    _commandKeyDictionary = [tempKeyDictionary copy];
    
    NSMutableDictionary* tempCommandDictionary = [NSMutableDictionary new];
    for (NSString* key in tempKeyDictionary) {
        tempCommandDictionary[tempKeyDictionary[key]] = key;
    }
    
    _stringCommandDictionary = [tempCommandDictionary copy];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void) testCreateFractal {
    LSFractal *fractal = [self createDefaultFractal];
    XCTAssert(fractal, @"Default Fractal not successfully created");

    NSUInteger rulesCount =  fractal.startingRules.count;
    XCTAssert(rulesCount == 3, @"Fractal rules not successfully created");

    LSReplacementRule* replacementRule = [fractal.replacementRules firstObject];
    NSUInteger replacementRulesCount = replacementRule.rules.count;
    XCTAssert(replacementRulesCount == 5, @"Fractal rules not successfully created");
}

-(void) testMutableCopyFractal {
    
    NSString* name = @"testing";
    NSString* copiedName = @"testing  1";
    
    LSFractal *fractal = [self createDefaultFractal];
    fractal.name = name;
    fractal.descriptor = @"more tests";
    
    LSFractal *fractalCopy = [fractal mutableCopy];
    
    BOOL result = [fractalCopy.name isEqualToString:copiedName];
    result = result && [fractalCopy.descriptor isEqualToString: fractal.descriptor];
    
    XCTAssert(result, @"Fractal copy not equal");
}

-(void) testMutableCopyDrawingRule {
    LSDrawingRule* drawingRule = [self createDrawingRuleWithProduction: @"F" command: @"commandDrawLine"];
    LSDrawingRule* drawingRuleCopy = [drawingRule mutableCopy];
    XCTAssert([drawingRuleCopy isSimilar: drawingRule], @"Drawing rule copy not equal");
}
-(void) testLevel1RulesCreation {
    LSFractal *fractal = [self createDefaultFractal];
    
    NSString* level1Rules = [[NSString alloc] initWithData: fractal.level1Rules encoding: NSUTF8StringEncoding] ;
    XCTAssert(level1Rules.length == 7, @"Wrong number of leaf rules");
}
-(void) testLevel5RulesCreation {
    LSFractal *fractal = [self createDefaultFractal];
    fractal.level = @5;
    NSString* levelNRules = [[NSString alloc] initWithData: fractal.levelNRules encoding: NSUTF8StringEncoding];
    
    XCTAssert(levelNRules.length == 487, @"Wrong number of leaf rules");
}
/*!
 -generateProduct production: @"FF+[+F-F-F]-[-F+F+F]"
 -generateProduct production: @"FF+[+F-F-F]-[-F+F+F]FF+[+F-F-F]-[-F+F+F]+[+FF+[+F-F-F]-[-F+F+F]-FF+[+F-F-F]-[-F+F+F]-FF+[+F-F-F]-[-F+F+F]]-[-FF+[+F-F-F]-[-F+F+F]+FF+[+F-F-F]-[-F+F+F]+FF+[+F-F-F]-[-F+F+F]]"

 */
-(void) testBushLevel1RulesCreation {
    LSFractal *fractal = [self createBushFractal];
    
    NSString* resultString = [[NSString alloc] initWithData: fractal.level1Rules encoding: NSUTF8StringEncoding];
    NSString* answer = [NSString stringWithCString: "FF+[+F-F-F]-[-F+F+F]" encoding: NSUTF8StringEncoding];
    XCTAssert([answer isEqualToString: resultString], @"Rule should be:\n%@ \nis\n%@",answer,resultString);
}
-(void) testBushLevel2RulesCreation {
    LSFractal *fractal = [self createBushFractal];
    
    NSString* resultString = [[NSString alloc] initWithData: fractal.level2Rules encoding: NSUTF8StringEncoding];
    NSString* answer = @"FF+[+F-F-F]-[-F+F+F]FF+[+F-F-F]-[-F+F+F]+[+FF+[+F-F-F]-[-F+F+F]-FF+[+F-F-F]-[-F+F+F]-FF+[+F-F-F]-[-F+F+F]]-[-FF+[+F-F-F]-[-F+F+F]+FF+[+F-F-F]-[-F+F+F]+FF+[+F-F-F]-[-F+F+F]]";
    XCTAssert([answer isEqualToString: resultString], @"Rule should be:\n%@ \nis\n%@",answer,resultString);
}
-(void) testBushLevel2NRulesCreation {
    LSFractal *fractal = [self createBushFractal];
    fractal.level = @2;
    
    NSString* resultString = [[NSString alloc] initWithData: fractal.levelNRules encoding: NSUTF8StringEncoding];
    NSString* answer = @"FF+[+F-F-F]-[-F+F+F]FF+[+F-F-F]-[-F+F+F]+[+FF+[+F-F-F]-[-F+F+F]-FF+[+F-F-F]-[-F+F+F]-FF+[+F-F-F]-[-F+F+F]]-[-FF+[+F-F-F]-[-F+F+F]+FF+[+F-F-F]-[-F+F+F]+FF+[+F-F-F]-[-F+F+F]]";
    XCTAssert([answer isEqualToString: resultString], @"Rule should be:\n%@ \nis\n%@",answer,resultString);
}
- (void)testDefaultFractalLevel1Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createDefaultFractal];
        
        fractal.level1Rules;
    }];
}

- (void)testDefaultFractalLevel5Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createDefaultFractal];
        fractal.level = @5;
        
        fractal.levelNRules;
    }];
}

- (void)testSierpinskyFractalLevel5Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = @5;
        
        fractal.levelNRules;
    }];
}

- (void)testSierpinskyFractalLevel6Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = @6;
        
        fractal.levelNRules;
    }];
}

- (void)testSierpinskyFractalLevel7Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = @7;
        
        fractal.levelNRules;
    }];
}

- (void)testSierpinskyFractalLevel8Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = @8;
        
        fractal.levelNRules;
    }];
}

- (void)testSierpinskyFractalLevel9Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = @9;
        
        fractal.levelNRules;
    }];
}

- (void)testBushFractalLevel5Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createBushFractal];
        fractal.level = @5;
        
        fractal.levelNRules;
    }];
}

- (void)testBushFractalLevel6Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createBushFractal];
        fractal.level = @6;
        
        fractal.levelNRules;
    }];
}

-(LSDrawingRule*) createDrawingRuleWithProduction: (NSString*) prodString command: (NSString*)commandString {
    LSDrawingRule* drawingRule = (LSDrawingRule*)[LSDrawingRule insertNewObjectIntoContext: self.managedObjectContext];
    drawingRule.productionString = prodString;
    drawingRule.drawingMethodString = commandString;
    return drawingRule;
}
-(void) addRulesFromString: (NSString*) rulesAsString toSet: (NSMutableOrderedSet*) rulesSet {

    NSRange ruleRange;
    ruleRange.length = 1;

    for (int i=0; i < rulesAsString.length; i++) {
        ruleRange.location = i;
        NSString* ruleKey = [rulesAsString substringWithRange: ruleRange];
        NSString* command = self.stringCommandDictionary[ruleKey];
        [rulesSet addObject: [self createDrawingRuleWithProduction: ruleKey command: command]];
    }
}
-(NSString*) stringFromRuleSet: (NSPointerArray*) ruleArray {
    NSMutableString* ruleString = [NSMutableString new];
    
    for (int i=0; i < ruleArray.count; i++) {
        NSString* ruleCommandString = [ruleArray pointerAtIndex: i];
        if (ruleCommandString) {
            [ruleString appendString: self.commandKeyDictionary[ruleCommandString]];
        } else {
//            break;
        }
    }
    return [ruleString copy];
}
-(LSFractal*) createDefaultFractal {
    LSFractal *fractalCopy = (LSFractal*)[LSFractal insertNewObjectIntoContext: self.managedObjectContext];
    
    NSMutableOrderedSet* rulesSet = [fractalCopy mutableOrderedSetValueForKey: [LSFractal startingRulesKey]];
    [self addRulesFromString: @"F-+" toSet: rulesSet];
    [fractalCopy.managedObjectContext processPendingChanges];
    
    NSUInteger rulesCount =  fractalCopy.startingRules.count;
    
    XCTAssert(rulesCount == 3, @"Fractal rules not successfully created");
    
    LSReplacementRule* replacementRule = (LSReplacementRule*)[LSReplacementRule insertNewObjectIntoContext: self.managedObjectContext];
    replacementRule.contextRule = [self createDrawingRuleWithProduction: @"F" command: @"commandDrawLine"];
    
    NSMutableOrderedSet* replacementRulesSet = [replacementRule mutableOrderedSetValueForKey: [LSReplacementRule rulesKey]];
    [self addRulesFromString: @"F+F-F" toSet: replacementRulesSet];
    
    NSUInteger replacementRulesCount = replacementRule.rules.count;
    XCTAssert(replacementRulesCount == 5, @"Fractal rules not successfully created");
    
    NSMutableOrderedSet* fractalReplacementRulesSet = [fractalCopy mutableOrderedSetValueForKey: [LSFractal replacementRulesKey]];
    [fractalReplacementRulesSet addObject: replacementRule];

    return fractalCopy;
}

/*!
 Start = FAF--FF--FF
 A -> --FAF++FAF++FAF--
 F -> FF
 
 turningAngle: 1.0471975511966
 lineLength: 10
 lineWidth: 2
 
 @return sierpinski fractal
 */
-(LSFractal*) createSierpinskiGasketFractal {
    LSFractal *fractalCopy = (LSFractal*)[LSFractal insertNewObjectIntoContext: self.managedObjectContext];
    
    NSMutableOrderedSet* rulesSet = [fractalCopy mutableOrderedSetValueForKey: [LSFractal startingRulesKey]];
    
    [self addRulesFromString: @"FAF--FF--FF" toSet: rulesSet];
    [fractalCopy.managedObjectContext processPendingChanges];
    
    NSUInteger rulesCount =  fractalCopy.startingRules.count;
    
    XCTAssert(rulesCount == 11, @"Fractal rules not successfully created");
    
    LSReplacementRule* replacementRuleF = (LSReplacementRule*)[LSReplacementRule insertNewObjectIntoContext: self.managedObjectContext];
    replacementRuleF.contextRule = [self createDrawingRuleWithProduction: @"F" command: @"commandDrawLine"];
    
    NSMutableOrderedSet* replacementRulesSet = [replacementRuleF mutableOrderedSetValueForKey: [LSReplacementRule rulesKey]];
    [self addRulesFromString: @"FF" toSet: replacementRulesSet];

    
    LSReplacementRule* replacementRuleA = (LSReplacementRule*)[LSReplacementRule insertNewObjectIntoContext: self.managedObjectContext];
    replacementRuleA.contextRule = [self createDrawingRuleWithProduction: @"A" command: @"commandDoNothing"];
    
    NSMutableOrderedSet* replacementRulesSetA = [replacementRuleA mutableOrderedSetValueForKey: [LSReplacementRule rulesKey]];
    [self addRulesFromString: @"--FAF++FAF++FAF--" toSet: replacementRulesSetA];
    
    NSUInteger replacementRulesCount = replacementRuleF.rules.count;
    XCTAssert(replacementRulesCount == 2, @"Fractal rules not successfully created");
    
    NSMutableOrderedSet* fractalReplacementRulesSet = [fractalCopy mutableOrderedSetValueForKey: [LSFractal replacementRulesKey]];
    [fractalReplacementRulesSet addObject: replacementRuleA];
    [fractalReplacementRulesSet addObject: replacementRuleF];
    
    return fractalCopy;
}
/*!
 -generateProduct production: @"F"
 -generateProduct production: @"FF+[+F-F-F]-[-F+F+F]"

 
 @return fractal
 */
-(LSFractal*) createBushFractal {
    LSFractal *fractalCopy = (LSFractal*)[LSFractal insertNewObjectIntoContext: self.managedObjectContext];
    
    NSMutableOrderedSet* rulesSet = [fractalCopy mutableOrderedSetValueForKey: [LSFractal startingRulesKey]];
    
    [self addRulesFromString: @"F" toSet: rulesSet];
    [fractalCopy.managedObjectContext processPendingChanges];
    
    NSUInteger rulesCount =  fractalCopy.startingRules.count;
    
    XCTAssert(rulesCount == 1, @"Fractal rules not successfully created");
    
    LSReplacementRule* replacementRuleF = (LSReplacementRule*)[LSReplacementRule insertNewObjectIntoContext: self.managedObjectContext];
    replacementRuleF.contextRule = [self createDrawingRuleWithProduction: @"F" command: @"commandDrawLine"];
    
    NSMutableOrderedSet* replacementRulesSet = [replacementRuleF mutableOrderedSetValueForKey: [LSReplacementRule rulesKey]];
    [self addRulesFromString: @"FF+[+F-F-F]-[-F+F+F]" toSet: replacementRulesSet];
    
    
    NSMutableOrderedSet* fractalReplacementRulesSet = [fractalCopy mutableOrderedSetValueForKey: [LSFractal replacementRulesKey]];
    [fractalReplacementRulesSet addObject: replacementRuleF];
    
    return fractalCopy;
}
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
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"FSTestLibrary.sqlite"];
    
    // for development, always delete the store first
    // will force load of defaults
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
