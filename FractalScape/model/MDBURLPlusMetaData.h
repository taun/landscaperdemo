//
//  MDBURLPlusMetaData.h
//  FractalScapes
//
//  Created by Taun Chapman on 12/08/15.
//  Copyright © 2015 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 The CloudCoordinator is the only place with metadataItems and the metaDataItems can't be stored in the NSURL passed out.
 The LocalCoordinator does not have metadataItems so it only has NSURLs.
 
 The NSMetaDataItems are needed as they are the only source of the upload download progress and they are update during the metaDataQuery.
 
 This class lets the cloudCoordinator return NSURL and NSMetaDataItems.
 
 Equality and hashing is based on fileURL;
 */
@interface MDBURLPlusMetaData : NSObject <NSCopying>

/*!
 File URL
 */
@property(nonatomic,strong) NSURL           *fileURL;
/*!
 NSMetaDataQuery metaDataItem
 */
@property(nonatomic,strong) NSMetadataItem  *metaDataItem;

+(instancetype) urlPlusMetaWithFileURL: (NSURL*)fileURL metaData: (NSMetadataItem*)metaData;

-(instancetype)initWithFileURL: (NSURL*)fileURL metaData: (NSMetadataItem*)metaData;

+(NSArray<MDBURLPlusMetaData*> *)newArrayFromURLArray: (NSArray <MDBURLPlusMetaData*> *)urlArray;

@end
