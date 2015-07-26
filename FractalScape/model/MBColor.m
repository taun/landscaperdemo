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


/*
 From Paul Bourke's library - http://paulbourke.net
 Attribute in app credits.
 
 */


ColorHSLA   ColorConvertRGBAToHSLA(ColorRGBA);
ColorRGBA   ColorConvertHSLAToRGBA(ColorHSLA);


@interface MBColor ()
@property(nonatomic,strong,readwrite) UIColor       *UIColor;
@end

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

-(BOOL)isPattern
{
    BOOL aPattern = NO;
    
    if (self.imagePath && self.imagePath.length != 0) aPattern = YES;
    
    return aPattern;
}

-(UIColor*) UIColor {
    
    if (!_UIColor)
    {
        UIImage* colorImage;
        
        if (self.isPattern) {
            colorImage = [UIImage imageNamed: self.imagePath];
            if (colorImage) {
                // use pattern image
                _UIColor = [UIColor colorWithPatternImage: colorImage];
            }
        } else {
            _UIColor = [UIColor colorWithRed: self.red
                                         green: self.green
                                          blue: self.blue
                                         alpha: self.alpha];
        }
    }
    
    return _UIColor;
}

-(CGColorRef)CGColor
{
    return self.UIColor.CGColor;
}

-(ColorRgbaOrColorRef)asColorRgbaOrColorRefStruct
{
    ColorRGBA rgba;
    rgba.r = self.red;
    rgba.g = self.green;
    rgba.b = self.blue;
    rgba.a = self.alpha;
    
    
    ColorRgbaOrColorRef newStruct;
    if (self.isPattern)
    {
        newStruct.isColorRef = YES;
        newStruct.colorRef = self.CGColor;
        newStruct.rgba = rgba;
    }
    else
    {
        newStruct.isColorRef = NO;
        newStruct.colorRef = NULL;
        newStruct.rgba = rgba;
    }
    return newStruct;
}

-(void)rotateHueByDegrees:(CGFloat)degreeRotation
{
    if (!self.isPattern)
    {
        ColorRGBA rgba;
        rgba.r = self.red;
        rgba.g = self.green;
        rgba.b = self.blue;
        rgba.a = self.alpha;
        
        ColorHSLA hsla = ColorConvertRGBAToHSLA(rgba);
        hsla.h = hsla.h + degreeRotation;
        ColorRGBA rgba2 = ColorConvertHSLAToRGBA(hsla);
        
        self.red = rgba2.r;
        self.green = rgba2.g;
        self.blue = rgba2.b;
        // don't want to update UIColor, point is to avoid unneccessary object creation and churn
    }
}

-(UIImage*) thumbnailImageSize: (CGSize) size {
    UIImage* thumbnail;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    UIColor* thumbNailBackground = self.UIColor;
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


/*
 From Paul Bourke's library - http://paulbourke.net
 Attribute in app credits.
 
 */

/*
 Calculate HSL from RGB
 Hue is in degrees
 Lightness is betweeen 0 and 1
 Saturation is between 0 and 1
 */
ColorHSLA ColorConvertRGBAToHSLA(ColorRGBA rgbaColor)
{
    CGFloat themin,themax,delta;
    ColorHSLA hslaColor;
    hslaColor.a = rgbaColor.a;
    
    themin = MIN(rgbaColor.r,MIN(rgbaColor.g,rgbaColor.b));
    themax = MAX(rgbaColor.r,MAX(rgbaColor.g,rgbaColor.b));
    delta = themax - themin;
    hslaColor.l = (themin + themax) / 2;
    hslaColor.s = 0;
    if (hslaColor.l > 0 && hslaColor.l < 1)
        hslaColor.s = delta / (hslaColor.l < 0.5 ? (2*hslaColor.l) : (2-2*hslaColor.l));
    hslaColor.h = 0;
    if (delta > 0) {
        if (themax == rgbaColor.r && themax != rgbaColor.g)
            hslaColor.h += (rgbaColor.g - rgbaColor.b) / delta;
        if (themax == rgbaColor.g && themax != rgbaColor.b)
            hslaColor.h += (2 + (rgbaColor.b - rgbaColor.r) / delta);
        if (themax == rgbaColor.b && themax != rgbaColor.r)
            hslaColor.h += (4 + (rgbaColor.r - rgbaColor.g) / delta);
        hslaColor.h *= 60;
        if (hslaColor.h < 0)
            hslaColor.h += 360;
    }
    return(hslaColor);
}

/*
 Calculate RGB from HSL, reverse of RGB2HSL()
 Hue is in degrees
 Lightness is between 0 and 1
 Saturation is between 0 and 1
 */
ColorRGBA ColorConvertHSLAToRGBA(ColorHSLA hslaColor)
{
    ColorRGBA rgbaColor,sat,ctmp;
    rgbaColor.a = hslaColor.a;
    
    while (hslaColor.h < 0)
        hslaColor.h += 360;
    while (hslaColor.h > 360)
        hslaColor.h -= 360;
    
    if (hslaColor.h < 120) {
        sat.r = (120 - hslaColor.h) / 60.0;
        sat.g = hslaColor.h / 60.0;
        sat.b = 0;
    } else if (hslaColor.h < 240) {
        sat.r = 0;
        sat.g = (240 - hslaColor.h) / 60.0;
        sat.b = (hslaColor.h - 120) / 60.0;
    } else {
        sat.r = (hslaColor.h - 240) / 60.0;
        sat.g = 0;
        sat.b = (360 - hslaColor.h) / 60.0;
    }
    sat.r = MIN(sat.r,1);
    sat.g = MIN(sat.g,1);
    sat.b = MIN(sat.b,1);
    
    ctmp.r = 2 * hslaColor.s * sat.r + (1 - hslaColor.s);
    ctmp.g = 2 * hslaColor.s * sat.g + (1 - hslaColor.s);
    ctmp.b = 2 * hslaColor.s * sat.b + (1 - hslaColor.s);
    
    if (hslaColor.l < 0.5) {
        rgbaColor.r = hslaColor.l * ctmp.r;
        rgbaColor.g = hslaColor.l * ctmp.g;
        rgbaColor.b = hslaColor.l * ctmp.b;
    } else {
        rgbaColor.r = (1 - hslaColor.l) * ctmp.r + 2 * hslaColor.l - 1;
        rgbaColor.g = (1 - hslaColor.l) * ctmp.g + 2 * hslaColor.l - 1;
        rgbaColor.b = (1 - hslaColor.l) * ctmp.b + 2 * hslaColor.l - 1;
    }
    
    return(rgbaColor);
}
