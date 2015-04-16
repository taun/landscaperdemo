//
//  MDBFilterObjectTile.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/30/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MBImageFilter.h"

@interface MBImageFilter ()

@property (nonatomic,readwrite) CIFilter             *ciFilter;
@property (nonatomic,readwrite) CIContext            *filterContext;

@end



@implementation MBImageFilter

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

+(instancetype)newFilterWithIdentifier:(NSString *)ciFilterName
{
    MBImageFilter* newFilter = [[[self class]alloc]initWithFilterIdentifier: ciFilterName];
    
    return newFilter;
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

-(CIFilter*)ciFilter
{
    if (!_ciFilter && self.identifier) {
        _ciFilter = [CIFilter filterWithName: self.identifier];
        [self setCiFilter: _ciFilter values: self.inputValues];
    }
    return _ciFilter;
}

-(void)setCiFilter:(CIFilter *)ciFilter values: (NSDictionary*)keyValues
{
    for (NSString* key in keyValues) {
        [ciFilter setValue: keyValues[key] forKey: key];
    }
}

-(CIContext*) filterContext {
    if (!_filterContext) {
        _filterContext = [CIContext contextWithOptions: nil];
    }
    return _filterContext;
}


-(UIImage*) thumbnailImageSize: (CGSize) size
{
    return nil;
}

-(void)setGoodDefaultsOnCIFilter: (CIFilter*)ciFilter forImage: (CIImage*)inputImage bounds:(CGRect)bounds
{
    CGFloat imageWidth = bounds.size.width;
    CGFloat imageHeight = bounds.size.height;
    
    CGFloat midX = imageWidth/2.0;
    CGFloat midY = imageHeight/2.0;
    
    CIVector* filterCenter = [CIVector vectorWithX: midX Y: midY];
    
    NSDictionary* filterAttributes = [self.ciFilter attributes];
    if (filterAttributes[kCIInputCenterKey]) {
        [self.ciFilter setValue: filterCenter forKey: kCIInputCenterKey];
    }
    
    if (filterAttributes[@"inputPoint"]) {
        [self.ciFilter setValue: filterCenter forKey: @"inputPoint"];
    }
    
    if (filterAttributes[kCIInputWidthKey]) {
        CGFloat width = imageWidth/3.0;
        [self.ciFilter setValue: @(width) forKey: kCIInputWidthKey];
    }
    
    if (filterAttributes[kCIInputRadiusKey]) {
        CGFloat radius = 10.0;

        if ([[self.identifier lowercaseString] containsString: @"blur"])
        {
            radius = 10.0;
        }
        else
        {
            radius = imageWidth/2.5;
        }
        
        [self.ciFilter setValue: @(radius) forKey: kCIInputRadiusKey];
    }
    
    [self.ciFilter setValue: inputImage forKey:kCIInputImageKey];

}

-(void)setInputValuesOnFilter: (CIFilter*)ciFilter
{
    
}

-(UIImage*) filterImage:(UIImage *)inputImage withContext:(CIContext *)context
{
    [self.ciFilter setDefaults];
    
    self.name = self.ciFilter.attributes[kCIAttributeFilterDisplayName];
    
    CGFloat imageWidth = inputImage.scale*inputImage.size.width;
    CGFloat imageHeight = inputImage.scale*inputImage.size.height;
    CGRect imageBounds = CGRectMake(0.0, 0.0, imageWidth, imageHeight);

    CIImage *image = [CIImage imageWithCGImage: inputImage.CGImage];

    if (self.inputValues && self.inputValues.count > 0)
    {
        [self setInputValuesOnFilter: self.ciFilter];
    }
    else
    {
        [self setGoodDefaultsOnCIFilter: self.ciFilter forImage: image bounds: imageBounds];
    }
    
    CIImage *filteredImage = [self.ciFilter valueForKey:kCIOutputImageKey];
    
    CGImageRef cgImage = [context createCGImage: filteredImage fromRect: imageBounds];
    
    UIImage* filteredUIImage = [UIImage imageWithCGImage: cgImage scale: inputImage.scale orientation: UIImageOrientationUp];
    
    CGImageRelease(cgImage);
    
    
    return filteredUIImage;
}

-(UIImage*) asImage
{
    UIImage* defaultImage = [UIImage imageNamed: @"kMBFilterBackground2"];
    
    return [self filterImage: defaultImage withContext: self.filterContext];
}

- (id) debugQuickLookObject
{
    return [self debugDescription];
}


@end