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
#define kMDBJGPQuality 1.0

NSString* const kMDBVersionFileName = @"version.txt";
NSString* const kMDBThumbnailFileName = @"thumbnail.jpg";
NSString* const kMDBFractalFileName = @"fractal.xml";

NSString * const CKFractalRecordType = @"Fractal";
NSString * const CKFractalRecordNameField = @"FractalName";
NSString * const CKFractalRecordNameInsensitiveField = @"FractalNameLowercase";
NSString * const CKFractalRecordDescriptorField = @"FractalDescriptor";
NSString * const CKFractalRecordFractalDefinitionAssetField = @"FractalDefinition";
NSString * const CKFractalRecordFractalThumbnailAssetField = @"FractalThumbnail";

NSString * const CKFractalRecordSubscriptionIDkey = @"subscriptionID";

@interface MDBFractalDocument ()
@property(nonatomic,strong) NSFileWrapper   *documentFileWrapper;
@property(nonatomic,strong) NSData          *thumbnailData;
@end

/*!
 Implementation help from https://github.com/SilverBayTech/Defensive-UIDocument
 */
@implementation MDBFractalDocument

@synthesize loadResult = _loadResult;
@synthesize thumbnail = _thumbnail;

+(NSInteger)version
{
    return kMDBDocumentCurrentVersion;
}

-(NSString*)loadResultString
{
    NSString* resultString;
    
    switch (_loadResult) {
        case MDBFractalDocumentLoad_SUCCESS:
            resultString = @"Success";
            break;
            
        case MDBFractalDocumentLoad_ZERO_LENGTH_FILE:
            resultString = @"Zero Length";
            break;
            
        case MDBFractalDocumentLoad_CORRUPT_FILE:
            resultString = @"Corrupt";
            break;
            
        case MDBFractalDocumentLoad_UNEXPECTED_VERSION:
            resultString = @"Wrong Version";
            break;
            
        case MDBFractalDocumentLoad_NO_SUCH_FILE:
            resultString = @"No File Found";
            break;
            
        default:
            break;
    }
    return resultString;
}

- (id) initWithFileURL:(NSURL *)url
{
    self = [super initWithFileURL:url];
    if (self)
    {
        _categories = @[[MDBFractalCategory newCategoryIdentifier: @"idGeo" name: @"Geometric"],[MDBFractalCategory newCategoryIdentifier: @"idPlant" name: @"Plant"]];
    }
    return self;
}

#pragma mark - Getting/Setting Wrappers


#pragma mark fractalWrappers

- (NSFileWrapper*)fractalFileWrapper
{
    return _documentFileWrapper.fileWrappers[kMDBFractalFileName];
}

- (void)updateDocumentWrapperForFractal
{
    NSFileWrapper* existingWrapper = [self fractalFileWrapper];
    if (existingWrapper)
    {
        [self.documentFileWrapper removeFileWrapper: existingWrapper];
    }

    if (self.fractal)
    {
        [self.documentFileWrapper addRegularFileWithContents: [NSKeyedArchiver archivedDataWithRootObject: self.fractal] preferredFilename: kMDBFractalFileName];
    }
}

- (void)updateFractalFromDocumentWrapper
{
//    LSFractal* returnFractal;
    
    NSData* fileData = [[self fractalFileWrapper] regularFileContents];
    
    if (fileData)
    {
        self.fractal = nil;
        self.fractal = [NSKeyedUnarchiver unarchiveObjectWithData: fileData];
    }
    else
    {
        self.fractal = nil;
    }
}

#pragma mark ThumbnailWrappers

- (NSFileWrapper*)thumbnailFileWrapper
{
    return [self.documentFileWrapper.fileWrappers valueForKey: kMDBThumbnailFileName];
}

- (void)updateDocumentWrapperForThumbnail
{
    NSFileWrapper* existingWrapper = [self thumbnailFileWrapper];
    if (existingWrapper)
    {
        [self.documentFileWrapper removeFileWrapper: existingWrapper];
    }
    
    if (self.thumbnail)
    {
        [self.documentFileWrapper addRegularFileWithContents: UIImagePNGRepresentation(self.thumbnail) preferredFilename: kMDBThumbnailFileName]; // UIImageJPEGRepresentation(self.thumbnail, kMDBJGPQuality)
    }
}

- (void)updateThumbnailFromDocumentWrapper
{
    NSData* fileData = [[self thumbnailFileWrapper] regularFileContents];
    
    if (fileData)
    {
        // see -(void)thumbnail lazy getter for explanation why we only save the thumbnail data here.
        self.thumbnailData = [fileData copy];
     }
    else
    {
        self.thumbnail = nil;
    }
}

//-(UIImage*)thumbnail
//{
//    if (!self.thumbnail && !_documentFileWrapper)
//    {
//        [self updateThumbnailFromDocumentWrapper];
//    }
//    return self.thumbnail;
//}

#pragma mark - Save/Load

- (id)contentsForType:(NSString *)typeName error:(NSError * __autoreleasing *)outError
{
    if (self.documentFileWrapper == nil)
    {
        self.documentFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    }

    NSFileWrapper* existingVersion = self.documentFileWrapper.fileWrappers[kMDBVersionFileName];
    if (existingVersion) {
        [self.documentFileWrapper removeFileWrapper: existingVersion];
    }
    
    [self.documentFileWrapper addRegularFileWithContents: [NSKeyedArchiver archivedDataWithRootObject: @(kMDBDocumentCurrentVersion)] preferredFilename: kMDBVersionFileName];
    
    if (self.fractal)
    {
        [self updateDocumentWrapperForFractal];
    }
    
    if (self.thumbnail) {
        [self updateDocumentWrapperForThumbnail];
    }
    
    return self.documentFileWrapper;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError
{
    _documentFileWrapper = (NSFileWrapper *)contents;
    
    if (!_documentFileWrapper || _documentFileWrapper.fileWrappers.count == 0)
    {
        _loadResult = MDBFractalDocumentLoad_ZERO_LENGTH_FILE;
        NSError*__autoreleasing error = [NSError errorWithDomain: @"FractalScape" code: _loadResult userInfo: nil];
        outError = (NSError*__autoreleasing*)&error;
        return NO;
    }
    
    
    @try
    {
        NSData* versionData = [_documentFileWrapper.fileWrappers[kMDBVersionFileName] regularFileContents];
        NSInteger version = [[NSKeyedUnarchiver unarchiveObjectWithData: versionData] integerValue];
        
        switch (version)
        {
            case kMDBDocumentCurrentVersion:
                [self updateFractalFromDocumentWrapper];
                [self updateThumbnailFromDocumentWrapper];
                break;
                
            default:
                _loadResult = MDBFractalDocumentLoad_UNEXPECTED_VERSION;
                NSError*__autoreleasing error = [NSError errorWithDomain: @"FractalScape" code: _loadResult userInfo: nil];
                outError = (NSError*__autoreleasing*)&error;
                return NO;
        }
        if (!self.fractal)
        {
            _loadResult = MDBFractalDocumentLoad_CORRUPT_FILE;
//            NSLog(@"Problem loading file %@",_documentFileWrapper.filename);
            NSError*__autoreleasing error = [NSError errorWithDomain: @"FractalScape" code: _loadResult userInfo: nil];
            outError = (NSError*__autoreleasing*)&error;
            return NO;
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"%@ exception: %@", NSStringFromSelector(_cmd), exception);
        _loadResult = MDBFractalDocumentLoad_CORRUPT_FILE;
        NSError*__autoreleasing error = [NSError errorWithDomain: @"FractalScape" code: _loadResult userInfo: nil];
        outError = (NSError*__autoreleasing*)&error;
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

//- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)url
//                            forSaveOperation:(UIDocumentSaveOperation)saveOperation
//                                       error:(NSError * __autoreleasing *)outError
//{
//    NSDictionary* fileAttributes;
//    
//#pragma message "TODO: how to get the thumbnail from the renderer in the editor? Give fractal a thumbnail property?"
//#pragma message "TODO: Editor should be document controller?"
//    
//    UIImage* thumbnail = [UIImage imageNamed: @"documentThumbnailPlaceholder1024"];
//    
//    if (thumbnail)
//    {
//        fileAttributes = @{NSThumbnail1024x1024SizeKey:thumbnail};
//    }
//    else
//    {
//        fileAttributes = [NSDictionary new];
//    }
//    
//    return fileAttributes;
//}

#pragma mark - Deletion

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler {
    [super accommodatePresentedItemDeletionWithCompletionHandler:completionHandler];
    
    if ([self.delegate respondsToSelector: @selector(fractalDocumentWasDeleted:)])
    {
        [self.delegate fractalDocumentWasDeleted: self];
    }
}

#pragma mark - Handoff

- (void)updateUserActivityState:(NSUserActivity *)userActivity
{
    [super updateUserActivityState:userActivity];
    [userActivity addUserInfoEntriesFromDictionary: @{ kMDBCloudManagerUserActivityFractalIdentifierUserInfoKey : self.fractal.identifier }];
}

#pragma mark - Lazy Properties

/*!
 Lazily convert the NSData to a UIImage. Since the thumbnail property always gets called by the collectionViewCell on the main thread,
 this is a way around the lack of background thread support of UIImage creation. Creating the UIImage as part of the loadFromContents:
 method performed on a serial operation queue was causing malloc errors when creating the image UITraitCollection.
 
 @return a fractal thumbnail
 */
-(UIImage*)thumbnail
{
    if (_thumbnailData) {
        _thumbnail = [UIImage imageWithData: _thumbnailData];
        _thumbnailData = nil;
    }
    return _thumbnail;
}

-(void)setThumbnail:(UIImage *)thumbnail
{
    if (_thumbnail != thumbnail) {
        _thumbnail = thumbnail;
        _thumbnailData = nil;
    }
}

#pragma mark - CloudKit

-(CKRecord*)asCloudKitRecord
{
    CKRecord* record;
    if (self.fractal)
    {
        record = [[CKRecord alloc] initWithRecordType: CKFractalRecordType];
        
        LSFractal* fractal = self.fractal;
        
        record[CKFractalRecordNameField] = fractal.name;
        record[CKFractalRecordNameInsensitiveField] = [fractal.name lowercaseString];
        record[CKFractalRecordDescriptorField] = fractal.descriptor;
        
        NSURL* fractalURL = [self.fileURL URLByAppendingPathComponent: kMDBFractalFileName];
        record[CKFractalRecordFractalDefinitionAssetField] = [[CKAsset alloc] initWithFileURL: fractalURL];

        NSURL* thumbnailURL = [self.fileURL URLByAppendingPathComponent: kMDBThumbnailFileName];
        record[CKFractalRecordFractalThumbnailAssetField] = [[CKAsset alloc] initWithFileURL: thumbnailURL];
   }
    
    return record;
}

@end
