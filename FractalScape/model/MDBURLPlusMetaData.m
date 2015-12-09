//
//  MDBURLPlusMetaData.m
//  FractalScapes
//
//  Created by Taun Chapman on 12/08/15.
//  Copyright © 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBURLPlusMetaData.h"

@implementation MDBURLPlusMetaData

+(NSArray<MDBURLPlusMetaData *> *)newArrayFromURLArray:(NSArray <NSURL*> *)urlArray
{
    NSMutableArray* upmArray = [NSMutableArray arrayWithCapacity: urlArray.count];
    
    for (NSURL* url in urlArray)
    {
        [upmArray addObject: [MDBURLPlusMetaData urlPlusMetaWithFileURL: url metaData: nil]];
    }
    
    return upmArray;
}

+(instancetype)urlPlusMetaWithFileURL:(NSURL *)fileURL metaData:(NSMetadataItem *)metaData
{
    return [[[self class]alloc]initWithFileURL: fileURL metaData: metaData];
}

-(instancetype)initWithFileURL:(NSURL *)fileURL metaData:(NSMetadataItem *)metaData
{
    self = [super init];
    if (self) {
        _fileURL = fileURL;
        _metaDataItem = metaData;
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        return [self.fileURL isEqual: [other fileURL]];
    }
}

- (NSUInteger)hash
{
    return self.fileURL.hash;
}

-(instancetype)copy
{
    MDBURLPlusMetaData* newCopy = [MDBURLPlusMetaData urlPlusMetaWithFileURL: self.fileURL metaData: self.metaDataItem];
    return newCopy;
}

@end
