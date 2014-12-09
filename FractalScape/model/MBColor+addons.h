//
//  MBColor+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 02/02/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBColor.h"
#import "NSManagedObject+Shortcuts.h"
#import "MDBTileObjectProtocol.h"

@interface MBColor (addons) <MDBTileObjectProtocol>

+(NSArray*) allColorsInContext: (NSManagedObjectContext *)context;

+(MBColor*) newMBColorWithPListDictionary: (NSDictionary*) colorDict inContext:(NSManagedObjectContext *)context;

+(MBColor*) newMBColorWithUIColor: (UIColor*) color inContext: (NSManagedObjectContext*) context;

+(MBColor*) findMBColorWithIdentifier: (NSString*) colorIdentifier inContext: (NSManagedObjectContext*) context;

+(UIColor*) newDefaultUIColor;
/*!
 This string is assigned by default in the CoreData model definition for the MBColor property identifier.

 
 @return The class default identifier string used to identify placeholder object.
 */
+(NSString*) defaultIdentifierString;

+(NSSortDescriptor*) colorsSortDescriptor;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) UIColor *asUIColor;

-(UIImage*) thumbnailImageSize: (CGSize) size;

@end
