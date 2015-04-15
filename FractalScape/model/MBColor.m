//
//  MBColor.m
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBColor.h"
#import "LSFractal.h"
#import "MBColorCategory.h"

@implementation MBColor

+(UIColor*) newDefaultUIColor
{
    return [UIColor colorWithRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];
}

+(NSString*) defaultIdentifierString {
    // This string is assigned by default in the CoreData model definition for the MBColor property identifier.
    static NSString* MBColorDefaultIdentifierString = @"NoneYet";
    return MBColorDefaultIdentifierString;
}



+(MBColor*) newMBColorWithUIColor:(UIColor *)color {
    
    MBColor *newColor = [MBColor new];
    
    if (newColor) {
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        
        BOOL success = [color getRed: &red green: &green blue: &blue alpha: &alpha];
        
        if (success) {
            newColor.red = red;
            newColor.blue = blue;
            newColor.green = green;
            newColor.alpha = alpha;
        }
        
        newColor.imagePath = @"";
    }
    return newColor;
}

+(NSSortDescriptor*) sortDescriptor {
    return  [NSSortDescriptor sortDescriptorWithKey: @"index" ascending: YES];
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"alpha",
                          @"red",
                          @"blue",
                          @"green",
                          @"identifier",
                          @"imagePath",
                          @"name",
                          @"index",
                          nil];
    });
    return keysToBeCopied;
}

- (id) debugQuickLookObject
{
    return [self debugDescription];
}

-(NSString*)debugDescription
{
    NSString* ddesc = [NSString stringWithFormat: @"Color %@ RGB: %0.1f:%0.1f:%0.1f",_identifier,_red,_green,_blue];
    return ddesc;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _identifier = [[self class] defaultIdentifierString];
    }
    return self;
}

-(id) copyWithZone:(NSZone *)zone {
    MBColor *copy = [[[self class]allocWithZone: zone] init];
    
    if (copy) {
        for ( NSString* aKey in [[self class] keysToBeCopied]) {
            id object = [self valueForKey: aKey];
            if (object) {
                [copy setValue: object forKey: aKey];
            }
        }
        
    }
    return copy;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        for ( NSString* aKey in [[self class] keysToBeCopied]) {
            id object = [aDecoder decodeObjectForKey: aKey];
            if (object) {
                [self setValue: object forKey: aKey];
            }
        }
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    for ( NSString* aKey in [[self class] keysToBeCopied]) {
        id propertyValue = [self valueForKey: aKey];
        if (propertyValue) {
            [aCoder encodeObject: propertyValue forKey: aKey];
        }
    }
}
+(MBColor*) newMBColorFromPListDictionary:(NSDictionary *)colorDict {
    
    MBColor *newObject = [[self class] new];
    
    if (newObject) {
        for (id propertyKey in colorDict) {
            [newObject setValue: colorDict[propertyKey] forKey: propertyKey];
        }
    }
    return newObject;
}

-(NSDictionary*)asPListDictionary
{
    NSMutableDictionary* plistDict = [NSMutableDictionary new];
    for (NSString* aKey in [[self class] keysToBeCopied]) {
        id object = [self valueForKey: aKey];
        if (object) {
            [plistDict setObject: object forKey: aKey];
        }
    }
    if (plistDict.count == 0) {
        plistDict = nil;
    }
    return plistDict;
}

-(UIColor*) asUIColor {
    
    UIColor* newUIColor;
    UIImage* colorImage;
    
    NSString* imagePath = self.imagePath;
    
    if (imagePath && imagePath.length != 0) {
        colorImage = [UIImage imageNamed: self.imagePath];
        if (colorImage) {
            // use pattern image
            newUIColor = [UIColor colorWithPatternImage: colorImage];
        }
    } else {
        newUIColor = [UIColor colorWithRed: self.red
                                     green: self.green
                                      blue: self.blue
                                     alpha: self.alpha];
    }
    
    return newUIColor;
}

-(UIImage*) thumbnailImageSize: (CGSize) size {
    UIImage* thumbnail;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    UIColor* thumbNailBackground = [self asUIColor];
    [thumbNailBackground setFill];
    CGContextFillRect(context, viewRect);
    CGContextRestoreGState(context);
    
    
    thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return thumbnail;
}

-(BOOL) isDefaultObject {
    BOOL isDefault = [[MBColor defaultIdentifierString] isEqualToString: self.identifier];
    return isDefault;
}

-(UIImage*) asImage {
    return [self thumbnailImageSize: CGSizeMake(40.0, 40.0)];
}
@end