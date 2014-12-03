//
//  MBColor+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 02/02/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBColor.h"

#import "MDBTileObjectProtocol.h"

@interface MBColor (addons) <MDBTileObjectProtocol>

+(NSArray*) allColorsInContext: (NSManagedObjectContext *)context;

+(MBColor*) newMBColorWithPListDictionary: (NSDictionary*) colorDict inContext:(NSManagedObjectContext *)context;

+(MBColor*) newMBColorWithUIColor: (UIColor*) color inContext: (NSManagedObjectContext*) context;

+(MBColor*) findMBColorWithIdentifier: (NSString*) colorIdentifier inContext: (NSManagedObjectContext*) context;

+(UIColor*) newDefaultUIColor;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) UIColor *asUIColor;

-(UIImage*) thumbnailImageSize: (CGSize) size;


@property (nonatomic,readonly) BOOL     isDefaultObject;

-(UIImage*) asImage;
@end
