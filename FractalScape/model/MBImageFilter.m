//
//  MDBFilterObjectTile.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/30/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MBImageFilter.h"

#import "MBAppDelegate.h"
#import "MDBAppModel.h"



static EAGLContext* __eaglContext;


@interface MBImageFilter ()

@property (nonatomic,readwrite) CIFilter             *ciFilter;
@property (nonatomic,assign) CGRect                  lastBounds;

@end



@implementation MBImageFilter

@synthesize name = _name;

+(NSSortDescriptor*) sortDescriptor
{
    return  [NSSortDescriptor sortDescriptorWithKey: @"identifier" ascending: YES];
}

+ (NSSet *)keysToBeCopied
{
    static NSSet *keysToBeCopied = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"identifier",
                          @"name",
                          @"inputValues",
                          nil];
    });
    return keysToBeCopied;
}

+(NSString*) defaultIdentifierString
{
    static NSString* MBImageFilterDefaultIdentifierString = @"NoneYet";
    return MBImageFilterDefaultIdentifierString;
}

+(CIContext*) filterContext
{
    static CIContext* __filterContext;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSDictionary *options = @{ kCIContextWorkingColorSpace : [NSNull null], kCIContextUseSoftwareRenderer : @NO };
        __filterContext = [CIContext contextWithOptions: options];
        //        __filterContext = [CIContext contextWithOptions: nil];
    });
    
    return __filterContext;
}

+(CGColorSpaceRef)colorSpace
{
    static CGColorSpaceRef __sDeviceRgbColorSpace = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sDeviceRgbColorSpace = CGColorSpaceCreateDeviceRGB();
    });
    return __sDeviceRgbColorSpace;
}


+(instancetype)newFilterWithIdentifier:(NSString *)ciFilterName
{
    MBImageFilter* newFilter = [[[self class]alloc]initWithFilterIdentifier: ciFilterName];
    
    return newFilter;
}

-(NSString*)cacheIdentifierString
{
    return [NSString stringWithFormat: @"%@.%@",NSStringFromClass([self class]), self.identifier];
}

-(instancetype)initWithFilterIdentifier: (NSString*)ciFilterName
{
    self = [super init];
    if (self) {
        if (ciFilterName)
        {
            _identifier = ciFilterName;
        } else
        {
            _identifier = [[self class] defaultIdentifierString];
        }
    }
    return self;
}

- (instancetype)init
{
    self = [self initWithFilterIdentifier: nil];
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        for ( NSString* aKey in [[self class] keysToBeCopied])
        {
            id object = [aDecoder decodeObjectForKey: aKey];
            if (object)
            {
                [self setValue: object forKey: aKey];
            }
        }
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    for ( NSString* aKey in [[self class] keysToBeCopied])
    {
        id propertyValue = [self valueForKey: aKey];
        if (propertyValue)
        {
            [aCoder encodeObject: propertyValue forKey: aKey];
        }
    }
}

-(id) copyWithZone:(NSZone *)zone
{
    MBImageFilter *copy = [[[self class]allocWithZone: zone] init];
    
    if (copy)
    {
        for ( NSString* aKey in [[self class] keysToBeCopied]) {
            id object = [self valueForKey: aKey];
            if (object) {
                [copy setValue: object forKey: aKey];
            }
        }
        
    }
    return copy;
}

-(BOOL) isDefaultObject
{
    BOOL isDefault = [[[self class] defaultIdentifierString] isEqualToString: self.identifier];
    return isDefault;
}

-(NSMutableDictionary*)inputValues
{
    if (!_inputValues) {
        _inputValues = [NSMutableDictionary new];
    }
    return _inputValues;
}

-(CIFilter*)ciFilter
{
    if (!_ciFilter && self.identifier && !self.isDefaultObject)
    {
        _ciFilter = [CIFilter filterWithName: self.identifier];
        [_ciFilter setDefaults];
//        [self setCiFilter: _ciFilter values: self.inputValues];
    }
    return _ciFilter;
}

-(NSString*)name
{
    if (!_name)
    {
        _name = self.ciFilter.attributes[kCIAttributeFilterDisplayName];
    }
    return _name;
}
//-(void)setCiFilter:(CIFilter *)ciFilter values: (NSDictionary*)keyValues
//{
//    if (keyValues.count > 0)
//    {
//        for (NSString* key in keyValues)
//        {
//            if (key && keyValues[key]) [ciFilter setValue: keyValues[key] forKey: key];
//        }
//    }
//}

-(UIImage*) thumbnailImageSize: (CGSize) size
{
    return nil;
}

-(void)settingsDefault: (CIVector*)vector
{
    CGFloat referenceDim =  MIN(vector.CGRectValue.size.width, vector.CGRectValue.size.height);

    CIVector* filterCenter = [CIVector vectorWithX: CGRectGetMidX(vector.CGRectValue) Y: CGRectGetMidY(vector.CGRectValue)];
    
    // droste, circularWrap, stretch crop, glass lozenge, glass distortion
    NSDictionary* filterAttributes = [self.ciFilter attributes];
    if (filterAttributes[kCIInputCenterKey])
    {
        [self.ciFilter setValue: filterCenter forKey: kCIInputCenterKey];
    }
    
    if (filterAttributes[@"inputPoint"])
    {
        [self.ciFilter setValue: filterCenter forKey: @"inputPoint"];
    }
    
    if (filterAttributes[kCIInputWidthKey])
    {
        CGFloat width = referenceDim/3.0;
        [self.ciFilter setValue: @(width) forKey: kCIInputWidthKey];
    }
    
    if (filterAttributes[kCIInputRadiusKey])
    {
        CGFloat radius = 10.0;
        
        if ([[self.identifier lowercaseString] containsString: @"blur"])
        {
            radius = 10.0;
        }
        else
        {
            radius = referenceDim/2.5;
        }
        
        [self.ciFilter setValue: @(radius) forKey: kCIInputRadiusKey];
    }
    
    if (filterAttributes[kCIInputTransformKey])
    {
        CGAffineTransform transform = CGAffineTransformIdentity;
        CGAffineTransform translate = CGAffineTransformTranslate(transform, filterCenter.X, filterCenter.Y);
        CGAffineTransform scale = CGAffineTransformScale(translate, 0.4, 0.4);
        CGAffineTransform rtranslate = CGAffineTransformTranslate(scale, -filterCenter.X, -filterCenter.Y);
        
        [self.ciFilter setValue:[NSValue valueWithBytes: &rtranslate objCType: @encode(CGAffineTransform)] forKey:@"inputTransform"];
    }
}

-(void)settingsCITriangleKaleidoscope: (CIVector*)vector
{
    CGFloat referenceDim =  MIN(vector.CGRectValue.size.width, vector.CGRectValue.size.height);
    
    CIVector* filterCenter = [CIVector vectorWithX: CGRectGetMidX(vector.CGRectValue) Y: CGRectGetMidY(vector.CGRectValue)];
    
    [self.ciFilter setValue: filterCenter forKey: @"inputPoint"];
    [self.ciFilter setValue: @(referenceDim/4.0) forKey: @"inputSize"];
    [self.ciFilter setValue: @(1.0) forKey: @"inputDecay"];
}

-(void)settingsCIKaleidoscope: (CIVector*)vector
{
    CIVector* filterCenter = [CIVector vectorWithX: CGRectGetMidX(vector.CGRectValue) Y: CGRectGetMidY(vector.CGRectValue)];
    
    [self.ciFilter setValue: filterCenter forKey: @"inputCenter"];
}

-(void)settingsCITriangleTile: (CIVector*)vector
{
    CIVector* filterCenter = [CIVector vectorWithX: CGRectGetMidX(vector.CGRectValue) Y: CGRectGetMidY(vector.CGRectValue)];
    
    [self.ciFilter setValue: filterCenter forKey: @"inputCenter"];
    [self.ciFilter setValue: @(vector.CGRectValue.size.width*0.38) forKey: @"inputWidth"];
}

-(void)settingsCIOpTile: (CIVector*)vector
{
    CIVector* filterCenter = [CIVector vectorWithX: CGRectGetMidX(vector.CGRectValue) Y: CGRectGetMidY(vector.CGRectValue)];
    
    [self.ciFilter setValue: filterCenter forKey: @"inputCenter"];
    [self.ciFilter setValue: @(vector.CGRectValue.size.width*0.05) forKey: @"inputWidth"];
    [self.ciFilter setValue: @(1.0/0.4) forKey: @"inputScale"]; // inverse of scale transform
}

-(void)settingsCIPerspectiveTile: (CIVector*)vector
{
    CGRect rect = vector.CGRectValue;
    
    [self.ciFilter setValue: [CIVector vectorWithX: CGRectGetMaxX(rect)*1.2 Y: CGRectGetMinY(rect)*0.9 ] forKey: @"inputTopLeft"];
    [self.ciFilter setValue: [CIVector vectorWithX: CGRectGetMaxX(rect)*0.9 Y: CGRectGetMaxY(rect)*0.7 ] forKey: @"inputTopRight"];
    [self.ciFilter setValue: [CIVector vectorWithX: CGRectGetMinX(rect)*0.8 Y: CGRectGetMaxY(rect)*0.9 ] forKey: @"inputBottomRight"];
    [self.ciFilter setValue: [CIVector vectorWithX: CGRectGetMinX(rect)*1.1 Y: CGRectGetMinY(rect)*1.3 ] forKey: @"inputBottomLeft"];
}

-(void)settingsCIDroste: (CIVector*)vector
{
    CGFloat referenceDim =  MIN(vector.CGRectValue.size.width, vector.CGRectValue.size.height);
    CGPoint center = CGPointMake(CGRectGetMidX(vector.CGRectValue), CGRectGetMidY(vector.CGRectValue));
    CGRect innerBox = CGRectMake(center.x, center.y, 0.001*referenceDim, 0.001*referenceDim);
    CIVector* p1 = [CIVector vectorWithCGPoint: innerBox.origin];
    CIVector* p2 = [CIVector vectorWithX: CGRectGetMaxX(innerBox) Y: CGRectGetMaxY(innerBox)];
    
    [self.ciFilter setValue: p1 forKey: @"inputInsetPoint0"];
    [self.ciFilter setValue: p2 forKey: @"inputInsetPoint1"];
    [self.ciFilter setValue: @(4) forKey: @"inputStrands"];
    [self.ciFilter setValue: @(4) forKey: @"inputPeriodicity"];
}

-(void)settingsCICircularWrap: (CIVector*)vector
{
    CGFloat referenceDim =  MIN(vector.CGRectValue.size.width, vector.CGRectValue.size.height);
    CIVector* filterCenter = [CIVector vectorWithX: CGRectGetMidX(vector.CGRectValue) Y: CGRectGetMidY(vector.CGRectValue)];
    
    [self.ciFilter setValue: filterCenter forKey: @"inputCenter"];
    [self.ciFilter setValue: @(referenceDim*0.1) forKey: @"inputRadius"];
    [self.ciFilter setValue: @(-3.0/4.0*3.14) forKey: @"inputAngle"];
}

//-(void)settingsTemplate: (CIVector*)vector
//{
//CGFloat referenceDim =  MIN(vector.CGRectValue.size.width, vector.CGRectValue.size.height);
//CIVector* filterCenter = [CIVector vectorWithX: CGRectGetMidX(vector.CGRectValue) Y: CGRectGetMidY(vector.CGRectValue)];
//
//[self.ciFilter setValue: filterCenter forKey: @"inputPoint"];
//}

-(void)setGoodDefaultsForbounds:(CGRect)bounds
{
    CIVector* vector = [CIVector vectorWithCGRect: bounds];
    
    SEL selector = NSSelectorFromString([NSString stringWithFormat: @"settings%@:",self.identifier]);
    
    if ([self respondsToSelector: selector])
    {
        [self performSelector: selector withObject: vector];
    }
    else
    {
        [self settingsDefault: vector];
    }
    
    self.lastBounds = bounds;
}

-(void)setInputValuesOnFilter: (CIFilter*)ciFilter
{
    NSDictionary* filterAttributes = [self.ciFilter attributes];

    for (id key in self.inputValues) {
        //
        if (filterAttributes[key])
        {
            NSNumber* value = self.inputValues[key];
            [self.ciFilter setValue: value forKey: key];
        }
    }
}

-(CIImage *)getOutputCIImageForInputCIImage:(CIImage *)inputImage
{
    CIImage* outputImage;
    
    CIFilter* filter = self.ciFilter;
    
    if (filter)
    {
        [filter setValue: inputImage forKey: kCIInputImageKey];
        outputImage = filter.outputImage;
    }
    else
    {
         outputImage = inputImage;
    }
    
    return outputImage;
}

/*!
 Only used for generating the thumbnail tile.
 
 @param inputImage reference image to filter
 @param context    global context passed in
 
 @return filtered image
 */
-(UIImage*) filterImage:(UIImage *)inputImage withContext:(CIContext *)context
{
    UIImage* filteredUIImage;
    
    @autoreleasepool
    {
        CGFloat imageWidth = inputImage.scale*inputImage.size.width;
        CGFloat imageHeight = inputImage.scale*inputImage.size.height;
        CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
        CGRect imageBounds = CGRectMake(0.0, 0.0, imageWidth, imageHeight);

        CIImage *image = [CIImage imageWithCGImage: inputImage.CGImage];
        
        CGRect nonAsImageBounds = self.lastBounds;
        [self setGoodDefaultsForbounds: imageBounds];
        self.lastBounds = nonAsImageBounds;
        
        [self.ciFilter setValue: image forKey: kCIInputImageKey];

        if (self.inputValues && self.inputValues.count > 0)
        {
            [self setInputValuesOnFilter: self.ciFilter];
        }
        
        CIImage *filteredImage = [self.ciFilter valueForKey:kCIOutputImageKey];
        
        CIImage* cropped = [filteredImage imageByCroppingToRect: imageBounds];

        UIGraphicsBeginImageContext(imageSize);
        CGImageRef tempRef = [context createCGImage: cropped fromRect: imageBounds];
        filteredUIImage = [UIImage imageWithCGImage: tempRef scale: inputImage.scale orientation: UIImageOrientationUp];
        CGImageRelease(tempRef);
        UIGraphicsEndImageContext();
        
        // reset to non thumbnail settings
        [self setGoodDefaultsForbounds: nonAsImageBounds];
    }
    
    return filteredUIImage;
}

-(NSPurgeableData*) getCachedAsImageData
{
    MBAppDelegate* appDelegate = (MBAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSCache* cache = appDelegate.appModel.resourceCache;
    
    return [cache objectForKey: [self cacheIdentifierString]];
}

-(void) saveCachedAsImageData: (NSPurgeableData*)data
{
    MBAppDelegate* appDelegate = (MBAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSCache* cache = appDelegate.appModel.resourceCache;

    [cache setObject: data forKey: [self cacheIdentifierString]];
}

-(UIImage*) asImage
{
    UIImage* tempImage;
    
    if (self.isDefaultObject)
    {
        //kMBFilterBackground2, kBIconRulePlaceEmpty
        tempImage = [UIImage imageNamed: @"kBIconRulePlaceEmpty"];
    }
    else
    {
        NSPurgeableData* imageData = [self getCachedAsImageData];
        
        if (imageData)
        {
            if ([imageData beginContentAccess])
            {
                tempImage = [UIImage imageWithData: imageData];
                [imageData endContentAccess];
            }
        }
        
        if (!tempImage)
        {
            @autoreleasepool
            {
                UIImage* preFilterImage = [UIImage imageNamed: @"kBIconRulePlaceEmpty"];
                tempImage = [self filterImage: preFilterImage withContext: [MBImageFilter filterContext]];
            }
            
            NSPurgeableData* newImageData = [NSPurgeableData dataWithData: UIImagePNGRepresentation(tempImage)];
            [self saveCachedAsImageData: newImageData];
        }
    }
    
    return tempImage;
}

- (id) debugQuickLookObject
{
    return [self debugDescription];
}

-(void)dealloc
{
    
}

@end
