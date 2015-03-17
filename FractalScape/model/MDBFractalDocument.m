//
//  MDBFractalDocument.m
//  FractalScapes
//
//  Created by Taun Chapman on 02/21/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalDocument.h"
#import "LSFractal.h"
#import "MBColorCategory.h"
#import "LSDrawingRuleType.h"
#import "MDBCloudManager.h"

#define kMDBDocumentCurrentVersion 1

/*!
 Implementation help from https://github.com/SilverBayTech/Defensive-UIDocument
 */
@implementation MDBFractalDocument

@synthesize loadResult = _loadResult;

+(NSInteger)version
{
    return kMDBDocumentCurrentVersion;
}

- (id) initWithFileURL:(NSURL *)url
{
    self = [super initWithFileURL:url];
    if (self)
    {
        _fractal = [LSFractal new];
        _categories = @[[MDBFractalCategory newCategoryIdentifier: @"idGeo" name: @"Geometric"],[MDBFractalCategory newCategoryIdentifier: @"idPlant" name: @"Plant"]];
    }
    return self;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    archiver.outputFormat = NSPropertyListXMLFormat_v1_0;
    
    [archiver encodeInteger: [[self class]version] forKey: @"version"];
    [archiver encodeObject: _fractal forKey: @"fractal"];
    
    [archiver finishEncoding];
    return data;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    NSData *data = (NSData *)contents;
    
    if ([data length] == 0)
    {
        _loadResult = MDBFractalDocumentLoad_ZERO_LENGTH_FILE;
        return NO;
    }
    
    
    @try
    {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        NSInteger version = [unarchiver decodeIntegerForKey: @"version"];
        switch (version) {
            case kMDBDocumentCurrentVersion:
                _fractal = [unarchiver decodeObjectForKey: @"fractal"];
                break;
                
            default:
                _loadResult = MDBFractalDocumentLoad_UNEXPECTED_VERSION;
                return NO;
        }
        
    }
    @catch (NSException *exception)
    {
        NSLog(@"%@ exception: %@", NSStringFromSelector(_cmd), exception);
        _loadResult = MDBFractalDocumentLoad_CORRUPT_FILE;
        return NO;
    }
    
    _loadResult = MDBFractalDocumentLoad_SUCCESS;
    return YES;
}

- (void) openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    _loadResult = MDBFractalDocumentLoad_NO_SUCH_FILE;
    [super openWithCompletionHandler:completionHandler];
}

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)url
                            forSaveOperation:(UIDocumentSaveOperation)saveOperation
                                       error:(NSError **)outError
{
    NSDictionary* fileAttributes;
    
#pragma message "TODO: how to get the thumbnail from the renderer in the editor? Give fractal a thumbnail property?"
#pragma message "TODO: Editor should be document controller?"
    
    UIImage* thumbnail = [UIImage imageNamed: @"documentThumbnailPlaceholder1024"];
    
    if (thumbnail)
    {
        fileAttributes = @{NSThumbnail1024x1024SizeKey:thumbnail};
    } else
    {
        fileAttributes = [NSDictionary new];
    }
    
    return fileAttributes;
}

#pragma mark - Deletion

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler {
    [super accommodatePresentedItemDeletionWithCompletionHandler:completionHandler];
    
    [self.delegate fractalDocumentWasDeleted:self];
}

#pragma mark - Handoff

- (void)updateUserActivityState:(NSUserActivity *)userActivity {
    [super updateUserActivityState:userActivity];
    [userActivity addUserInfoEntriesFromDictionary: @{ kMDBCloudManagerUserActivityFractalIdentifierUserInfoKey : self.fractal.identifier }];
}

#pragma mark - Lazy Properties

-(NSArray*)sourceColorCategories
{
    if (!_sourceColorCategories)
    {
        _sourceColorCategories = [MBColorCategory loadAllDefaultCategories];
    }
    return _sourceColorCategories;
}
-(LSDrawingRuleType*)sourceDrawingRules
{
    if (!_sourceDrawingRules) {
        _sourceDrawingRules = [LSDrawingRuleType newLSDrawingRuleTypeFromDefaultPListDictionary];
    }
    return _sourceDrawingRules;
}

@end
