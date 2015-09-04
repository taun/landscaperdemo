//
//  FractalScapeFractalModelTests.m
//  FractalScapeFractalModelTests
//
//  Created by Taun Chapman on 01/12/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//


@import XCTest;
@import Foundation;
@import UIKit;

#import "LSFractal.h"
#import "LSDrawingRule.h"
#import "LSReplacementRule.h"
#import "MDBFractalDocument.h"

@interface MDBExplodingObject : NSObject

@end


#define kUnitTestFileName   @"FractalTest.fractal"

@interface FractalScapeFractalModelTests : XCTestCase

@property(nonatomic,strong) NSFileManager   *fileManager;
@property(nonatomic,strong) NSString        *unitTestFilePath;
@property(nonatomic,strong) NSURL           *unitTestFileUrl;

@property (nonatomic,strong) NSDictionary                  *commandKeyDictionary;
@property (nonatomic,strong) NSDictionary                  *stringCommandDictionary;

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

    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirs objectAtIndex:0];
    
    self.unitTestFilePath = [docsDir stringByAppendingPathComponent:kUnitTestFileName];
    self.unitTestFileUrl = [NSURL fileURLWithPath: self.unitTestFilePath];
    
    self.fileManager = [NSFileManager defaultManager];
    [self.fileManager removeItemAtURL: self.unitTestFileUrl error:NULL];
    
}

- (void)tearDown
{
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
    
    LSFractal *fractalCopy = [fractal copy];
    
    BOOL result = [fractalCopy.name isEqualToString:copiedName];
    result = result && [fractalCopy.descriptor isEqualToString: fractal.descriptor];
    
    XCTAssert(result, @"Fractal copy not equal");
}

-(void) testMutableCopyDrawingRule {
    LSDrawingRule* drawingRule = [self createDrawingRuleWithProduction: @"F" command: @"commandDrawLine"];
    LSDrawingRule* drawingRuleCopy = [drawingRule copy];
    XCTAssert([drawingRuleCopy isSimilar: drawingRule], @"Drawing rule copy not equal");
}
-(void) testLevel1RulesCreation {
    LSFractal *fractal = [self createDefaultFractal];
    
    NSString* level1Rules = [[NSString alloc] initWithData: fractal.level1Rules encoding: NSUTF8StringEncoding] ;
    XCTAssert(level1Rules.length == 7, @"Wrong number of leaf rules");
}
-(void) testLevel5RulesCreation {
    LSFractal *fractal = [self createDefaultFractal];
    fractal.level = 5;
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
    fractal.level = 2;
    
    NSString* resultString = [[NSString alloc] initWithData: fractal.levelNRules encoding: NSUTF8StringEncoding];
    NSString* answer = @"FF+[+F-F-F]-[-F+F+F]FF+[+F-F-F]-[-F+F+F]+[+FF+[+F-F-F]-[-F+F+F]-FF+[+F-F-F]-[-F+F+F]-FF+[+F-F-F]-[-F+F+F]]-[-FF+[+F-F-F]-[-F+F+F]+FF+[+F-F-F]-[-F+F+F]+FF+[+F-F-F]-[-F+F+F]]";
    XCTAssert([answer isEqualToString: resultString], @"Rule should be:\n%@ \nis\n%@",answer,resultString);
}
- (void)testDefaultFractalLevel1Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createDefaultFractal];
        
        [fractal generateLevelData];
    }];
}

- (void)testDefaultFractalLevel5Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createDefaultFractal];
        fractal.level = 5;
        
        [fractal generateLevelData];
    }];
}

- (void)testSierpinskyFractalLevel5Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = 5;
        
        [fractal generateLevelData];
    }];
}

- (void)testSierpinskyFractalLevel6Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = 6;
        
        [fractal generateLevelData];
    }];
}

- (void)testSierpinskyFractalLevel7Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = 7;
        
        [fractal generateLevelData];
    }];
}

- (void)testSierpinskyFractalLevel8Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = 8;
        
        [fractal generateLevelData];
    }];
}

- (void)testSierpinskyFractalLevel9Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createSierpinskiGasketFractal];
        fractal.level = 9;
        
        [fractal generateLevelData];
    }];
}

- (void)testBushFractalLevel5Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createBushFractal];
        fractal.level = 5;
        
        [fractal generateLevelData];
    }];
}

- (void)testBushFractalLevel6Performance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        LSFractal *fractal = [self createBushFractal];
        fractal.level = 6;
        
        [fractal generateLevelData];
    }];
}

- (void)testSavingCreatesFile
{
    // given that we have an instance of our document
    MDBFractalDocument * objUnderTest = [[MDBFractalDocument alloc] initWithFileURL: self.unitTestFileUrl];
    
    // when we call saveToURL:forSaveOperation:completionHandler:
    XCTestExpectation *documentSaveExpectation = [self expectationWithDescription:@"document saved"];
    
    [objUnderTest saveToURL: self.unitTestFileUrl forSaveOperation:UIDocumentSaveForCreating completionHandler: ^(BOOL success)
     {
         XCTAssert(success);
         // Possibly assert other things here about the document after it has opened...
         
         XCTAssertTrue([_fileManager fileExistsAtPath:_unitTestFilePath], @"");
         [documentSaveExpectation fulfill];
         
     }];
    // then the completion block should be called, but with a failure indication
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {

    }];
}

- (void) testLoadingRetrievesData
{
    // given that we have saved the data from an instance of our class
    LSFractal* savedFractal = [self createDefaultFractal];
    
    MDBFractalDocument * document = [[MDBFractalDocument alloc] initWithFileURL: self.unitTestFileUrl];
    document.fractal = savedFractal;
    
    XCTestExpectation *documentSaveExpectation = [self expectationWithDescription:@"document saved"];
    
    [document saveToURL: self.unitTestFileUrl forSaveOperation:UIDocumentSaveForCreating completionHandler: ^(BOOL success)
     {
         XCTAssert(success);
         // Possibly assert other things here about the document after it has opened...
         
         [documentSaveExpectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error)
     {
     }];
    
    XCTestExpectation *documentCloseExpectation = [self expectationWithDescription:@"document close"];
    
    [document closeWithCompletionHandler: ^(BOOL success)
     {
         XCTAssert(success);
         // Possibly assert other things here about the document after it has opened...
         
         [documentCloseExpectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error)
     {
     }];
    
    // when we load a new document from that file
    XCTestExpectation *documentOpenExpectation = [self expectationWithDescription:@"document open"];
    
    MDBFractalDocument * objUnderTest = [[MDBFractalDocument alloc] initWithFileURL: self.unitTestFileUrl];
    [objUnderTest openWithCompletionHandler: ^(BOOL success)
     {
         XCTAssert(success);
         // Possibly assert other things here about the document after it has opened...
         
         LSFractal * loadedFractal = objUnderTest.fractal;
         
         BOOL result = [savedFractal.name isEqualToString: loadedFractal.name];
         result = result && [savedFractal.descriptor isEqualToString: loadedFractal.descriptor];
         
         XCTAssert(result, @"Fractal copy not equal");
         
         [documentOpenExpectation fulfill];
         
     }];
    // then the completion block should be called, but with a failure indication
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        [objUnderTest closeWithCompletionHandler:nil];
    }];
}

- (void) testLoadingWhenThereIsNoFile
{
    // given that the file does not exist
    
    // when we load a new document from that file
    XCTestExpectation *documentOpenExpectation = [self expectationWithDescription:@"document open"];
    
    MDBFractalDocument * objUnderTest = [[MDBFractalDocument alloc] initWithFileURL: self.unitTestFileUrl];
    [objUnderTest openWithCompletionHandler: ^(BOOL success)
     {
         XCTAssertFalse(success);
         // Possibly assert other things here about the document after it has opened...
         
         [documentOpenExpectation fulfill];
         
     }];
    // then the completion block should be called, but with a failure indication
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        [objUnderTest closeWithCompletionHandler:nil];
    }];
}
- (void) testLoadingEmptyFileShouldFailGracefully
{
    // given that the file is present but empty
    NSMutableData *data = [NSMutableData dataWithLength:0];
    [data writeToFile: self.unitTestFilePath atomically:YES];
    
    // when we load a new document from that file
    XCTestExpectation *documentOpenExpectation = [self expectationWithDescription:@"document open"];
    
    MDBFractalDocument * objUnderTest = [[MDBFractalDocument alloc] initWithFileURL: self.unitTestFileUrl];
    [objUnderTest openWithCompletionHandler: ^(BOOL success)
     {
         XCTAssertFalse(success);
         // Possibly assert other things here about the document after it has opened...
         
         [documentOpenExpectation fulfill];
         
     }];
    // then the completion block should be called, but with a failure indication
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        [objUnderTest closeWithCompletionHandler:nil];
    }];
}

- (void) testLoadingSingleByteFileShouldFailGracefully
{
    // given that the file is present and contains a single byte
    NSMutableData *data = [NSMutableData dataWithLength:1];
    [data appendBytes:" " length:1];
    [data writeToFile: self.unitTestFilePath atomically:YES];
    
    // when we load a new document from that file
    XCTestExpectation *documentOpenExpectation = [self expectationWithDescription:@"document open"];
    
    MDBFractalDocument * objUnderTest = [[MDBFractalDocument alloc] initWithFileURL: self.unitTestFileUrl];
    [objUnderTest openWithCompletionHandler: ^(BOOL success)
     {
         XCTAssertFalse(success);
         // Possibly assert other things here about the document after it has opened...
         
         [documentOpenExpectation fulfill];
         
     }];
    // then the completion block should be called, but with a failure indication
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        [objUnderTest closeWithCompletionHandler:nil];
    }];
}

- (void) testUnexpectedVersionShouldFailGracefully
{
    // given that the file contains an unexpected version number
    
    NSArray *array = [NSArray array];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeInt:-999 forKey:@"version"];
    [archiver encodeObject:array forKey:@"array"];
    [archiver finishEncoding];
    [data writeToFile: self.unitTestFilePath atomically:YES];
    
    // when we load a new document from that file
    XCTestExpectation *documentOpenExpectation = [self expectationWithDescription:@"document open"];
    
    MDBFractalDocument * objUnderTest = [[MDBFractalDocument alloc] initWithFileURL: self.unitTestFileUrl];
    [objUnderTest openWithCompletionHandler: ^(BOOL success)
     {
         XCTAssertFalse(success);
         // Possibly assert other things here about the document after it has opened...
         
         [documentOpenExpectation fulfill];
         
     }];
    // then the completion block should be called, but with a failure indication
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        [objUnderTest closeWithCompletionHandler:nil];
    }];
}

- (void) testExceptionDuringUnarchiveShouldFailGracefully
{
    // given that the file contains an object that will throw when unarchived
    
    MDBExplodingObject *exploding = [[MDBExplodingObject alloc] init];
    NSArray *array = [NSArray arrayWithObjects:exploding, nil];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeInteger: 1 forKey: @"version"];
    [archiver encodeObject:array forKey:@"array"];
    [archiver finishEncoding];
    [data writeToFile:_unitTestFilePath atomically:YES];
    
    // when we load a new document from that file
    
    XCTestExpectation *documentOpenExpectation = [self expectationWithDescription:@"document open"];

    MDBFractalDocument * objUnderTest = [[MDBFractalDocument alloc] initWithFileURL:_unitTestFileUrl];
    [objUnderTest openWithCompletionHandler:^(BOOL success)
    {
        XCTAssert(success);
        // Possibly assert other things here about the document after it has opened...

        [documentOpenExpectation fulfill];
    
    }];
    // then the completion block should be called, but with a failure indication
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        [objUnderTest closeWithCompletionHandler:nil];
    }];
}

#pragma mark - Utility Methods

-(LSDrawingRule*) createDrawingRuleWithProduction: (NSString*) prodString command: (NSString*)commandString {
    LSDrawingRule* drawingRule = [LSDrawingRule new];
    drawingRule.productionString = prodString;
    drawingRule.drawingMethodString = commandString;
    return drawingRule;
}
-(void) addRulesFromString: (NSString*) rulesAsString toCollection: (id) rulesCollection {

    NSRange ruleRange;
    ruleRange.length = 1;

    for (int i=0; i < rulesAsString.length; i++) {
        ruleRange.location = i;
        NSString* ruleKey = [rulesAsString substringWithRange: ruleRange];
        NSString* command = self.stringCommandDictionary[ruleKey];
        [rulesCollection addObject: [self createDrawingRuleWithProduction: ruleKey command: command]];
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
    LSFractal *fractalCopy = [LSFractal new];
    fractalCopy.name = @"DefaultFractal";
    fractalCopy.descriptor = @"A sample test fractal.";
    
    NSMutableArray* rules = [NSMutableArray new];
    [self addRulesFromString: @"F-+" toCollection: rules];
    fractalCopy.startingRules = [MDBFractalObjectList newListFromArray: rules];
    
    NSUInteger rulesCount =  fractalCopy.startingRules.count;
    
    XCTAssert(rulesCount == 3, @"Fractal rules not successfully created");
    
    LSReplacementRule* replacementRule = [LSReplacementRule new];
    replacementRule.contextRule = [self createDrawingRuleWithProduction: @"F" command: @"commandDrawLine"];
    
    NSMutableArray* replacementRules = [NSMutableArray new];
    [self addRulesFromString: @"F+F-F" toCollection: replacementRules];
    replacementRule.rules = [MDBFractalObjectList newListFromArray: replacementRules];
    
    NSUInteger replacementRulesCount = replacementRule.rules.count;
    XCTAssert(replacementRulesCount == 5, @"Fractal rules not successfully created");
    
    NSMutableArray* fractalReplacementRulesSet = [NSMutableArray new];
    [fractalReplacementRulesSet addObject: replacementRule];
    fractalCopy.replacementRules = fractalReplacementRulesSet;
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
    LSFractal *fractalCopy = [LSFractal new];
    fractalCopy.name = @"Sierpinski Gasket";
    fractalCopy.descriptor = @"A geometric fractal which looks like a circular?";
    
    NSMutableArray* rulesSet = [NSMutableArray new];
    
    [self addRulesFromString: @"FAF--FF--FF" toCollection: rulesSet];
    
    fractalCopy.startingRules = [MDBFractalObjectList newListFromArray: rulesSet];
    
    NSUInteger rulesCount =  fractalCopy.startingRules.count;
    
    XCTAssert(rulesCount == 11, @"Fractal rules not successfully created");
    
    LSReplacementRule* replacementRuleF = [LSReplacementRule new];
    replacementRuleF.contextRule = [self createDrawingRuleWithProduction: @"F" command: @"commandDrawLine"];
    
    NSMutableArray* replacementRulesSet = [NSMutableArray new];
    [self addRulesFromString: @"FF" toCollection: replacementRulesSet];
    replacementRuleF.rules = [MDBFractalObjectList newListFromArray: replacementRulesSet];
    
    LSReplacementRule* replacementRuleA = [LSReplacementRule new];
    replacementRuleA.contextRule = [self createDrawingRuleWithProduction: @"A" command: @"commandDoNothing"];
    
    NSMutableArray* replacementRulesSetA = [NSMutableArray new];
    [self addRulesFromString: @"--FAF++FAF++FAF--" toCollection: replacementRulesSetA];
    replacementRuleA.rules = [MDBFractalObjectList newListFromArray: replacementRulesSetA];
    
    NSUInteger replacementRulesCount = replacementRuleF.rules.count;
    XCTAssert(replacementRulesCount == 2, @"Fractal rules not successfully created");
    
    NSMutableArray* fractalReplacementRulesSet = [NSMutableArray new];
    [fractalReplacementRulesSet addObject: replacementRuleA];
    [fractalReplacementRulesSet addObject: replacementRuleF];
    fractalCopy.replacementRules = fractalReplacementRulesSet;
    
    return fractalCopy;
}
/*!
 -generateProduct production: @"F"
 -generateProduct production: @"FF+[+F-F-F]-[-F+F+F]"

 
 @return fractal
 */
-(LSFractal*) createBushFractal {
    LSFractal *fractalCopy = [LSFractal new];
    fractalCopy.name = @"Bush";
    fractalCopy.descriptor = @"A plant fractal which looks like a simple bush.";
    
    NSMutableArray* rules = [NSMutableArray new];
    
    [self addRulesFromString: @"F" toCollection: rules];
    fractalCopy.startingRules = [MDBFractalObjectList newListFromArray: rules];
    
    NSUInteger rulesCount =  fractalCopy.startingRules.count;
    
    XCTAssert(rulesCount == 1, @"Fractal rules not successfully created");
    
    LSReplacementRule* replacementRuleF = [LSReplacementRule new];
    replacementRuleF.contextRule = [self createDrawingRuleWithProduction: @"F" command: @"commandDrawLine"];
    
    NSMutableArray* replacementRulesSet = [NSMutableArray new];
    [self addRulesFromString: @"FF+[+F-F-F]-[-F+F+F]" toCollection: replacementRulesSet];
    replacementRuleF.rules = [MDBFractalObjectList newListFromArray: replacementRulesSet];
    
    NSMutableArray* fractalReplacementRulesSet = [NSMutableArray new];
    [fractalReplacementRulesSet addObject: replacementRuleF];
    fractalCopy.replacementRules = fractalReplacementRulesSet;
    
    return fractalCopy;
}


- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end

@implementation MDBExplodingObject

- (id) initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    
    if (self)
    {
        [NSException raise:@"MDBExplodingObjectException" format:@"goes bang when unarchived"];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger: 1 forKey: @"exploder"];
}
@end
