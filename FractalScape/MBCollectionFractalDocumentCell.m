//
//  FractalScape
//
//  Created by Taun Chapman on 02/26/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBCollectionFractalDocumentCell.h"
#import <QuartzCore/QuartzCore.h>

#import "LSFractal.h"
#import "MDBFractalInfo.h"
#import "MDBFractalDocument.h"
#import "MBColorCellBackgroundView.h"
#import "MDCCloudTransferStatusIndicator.h"
#import "FBKVOController.h"

@interface MBCollectionFractalDocumentCell ()

@property (weak, nonatomic) IBOutlet UIView         *imageFrame;
@property (weak, nonatomic) IBOutlet UIImageView    *imageView;
@property (weak, nonatomic) IBOutlet UILabel        *textLabel;
@property (weak, nonatomic) IBOutlet UILabel        *detailTextLabel;

@property (strong,nonatomic,readonly) FBKVOController*kvoController;

@end

@implementation MBCollectionFractalDocumentCell

@synthesize kvoController = _kvoController;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self configureDefaults];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    if (self) {
        //
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self configureDefaults];
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    [self.kvoController unobserve: _document];
    self.transferIndicator.progress = 0.0;
    [self.activityIndicator startAnimating];
}

-(void) configureDefaults
{
    
//    [self fixConstraints];

    _radius = 5.0;
    
    _textLabel.text = @"Loading..";
    _detailTextLabel.text = @"";
    
    _imageView.image = nil;
    
//    _selectedBorder = [UIColor whiteColor];
//    _selectedBorderWidth = 4.0;
    
//    UIImage* placeholder = [UIImage imageNamed: @"documentThumbnailPlaceholder130"];
//    UIImageView* strongImageView = self.imageView;
//    strongImageView.image = placeholder;
    
    if (!self.backgroundView) {
//        MBColorCellBackgroundView* backgroundView = [MBColorCellBackgroundView new];
        UIImageView* backgroundImage = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"kLibraryCellBackgroundImage"]];
        backgroundImage.opaque = NO;
        UIView* background = backgroundImage;
        self.backgroundView = background;
    }
    
    self.selectedBackgroundView = [self configureSelectedBackgroundViewFrame: CGRectZero];

    self.transferIndicator.progress = 0.0;
}

-(UIView*) configureSelectedBackgroundViewFrame: (CGRect) frame
{
    UIView *selectBackgroundView = [[UIView alloc] initWithFrame: frame];
    selectBackgroundView.layer.cornerRadius = self.radius;
    selectBackgroundView.layer.masksToBounds = NO;
    UIColor* border = [UIColor grayColor];
    CGColorRef colorCopy = CGColorCreateCopy(border.CGColor);
    selectBackgroundView.layer.borderColor = colorCopy;
    CGColorRelease(colorCopy);
    selectBackgroundView.layer.borderWidth = 0.0;
    
    if ((YES)) {
        selectBackgroundView.layer.shadowOpacity = 0.9;
        selectBackgroundView.layer.shadowRadius = 2;
        selectBackgroundView.layer.shadowOffset = CGSizeMake(2,2);
        selectBackgroundView.layer.shadowColor = [[UIColor whiteColor] CGColor];
    }
    
    selectBackgroundView.layer.backgroundColor = [[UIColor darkGrayColor] CGColor];
    return selectBackgroundView;
}

-(FBKVOController *)kvoController
{
    if (!_kvoController)
    {
        _kvoController = [FBKVOController controllerWithObserver: self];
    }
    return _kvoController;
}

-(void) propertyDcoumentThumbnailDidChange: (NSDictionary*)change object: (id)object
{
    if ([object thumbnail])
    {
        self.imageView.image = [object thumbnail];
    }
}

-(void)updateProgessIndicatorForURL: (NSURL*)docURL
{
    if (docURL)
    {
        NSError* error;
        id fileIsICloud;
        id downloadedStatusValue;
        id uploadedValue;
        id downloadingValue;
        id uploadingValue;
        
        
        [docURL getResourceValue: &fileIsICloud forKey: NSURLIsUbiquitousItemKey error: &error];
        
        if ([fileIsICloud boolValue])
        {
            [docURL getResourceValue: &downloadedStatusValue forKey: NSURLUbiquitousItemDownloadingStatusKey error: &error];
            [docURL getResourceValue: &downloadingValue forKey: NSURLUbiquitousItemIsDownloadingKey error: &error];
            [docURL getResourceValue: &uploadedValue forKey: NSURLUbiquitousItemIsUploadedKey error: &error];
            [docURL getResourceValue: &uploadingValue forKey: NSURLUbiquitousItemIsUploadingKey error: &error];
            
            self.transferIndicator.hidden = NO;
            
            if ([downloadingValue boolValue])
            {
                self.transferIndicator.progress = -0.1;
            }
            else if ([uploadingValue boolValue] || ![uploadedValue boolValue])
            {
                self.transferIndicator.progress = 0.1;
            }
            else
            {
                self.transferIndicator.progress = 1.0;
            }
        }
        else
        {
            self.transferIndicator.hidden = YES;
        }
        
    }
}

-(void)setDocument:(MDBFractalDocument *)document
{
    if (_document != document)
    {
//        [self configureDefaults];
        
        [self.activityIndicator stopAnimating];
        
        [self.kvoController unobserve: _document];
        
        _document = document;
        
        if (_document)
        {
            [self updateProgessIndicatorForURL: _document.fileURL];

            if (_document.loadResult == MDBFractalDocumentLoad_SUCCESS)
            {
                if (_document.fractal.name) self.textLabel.text = _document.fractal.name;
                if (_document.fractal.descriptor) self.detailTextLabel.text = _document.fractal.descriptor;
                [self propertyDcoumentThumbnailDidChange: nil object: _document];
                [self.kvoController observe: _document keyPath: @"thumbnail" options: 0 action: @selector(propertyDcoumentThumbnailDidChange:object:)];
            } else {
                self.textLabel.text = _document.loadResultString;
            }
 //            else
//            {
//                UIImage* placeholder = [UIImage imageNamed: @"documentThumbnailPlaceholder130"];
//                UIImageView* strongImageView = self.imageView;
//                strongImageView.image = placeholder;
//            }
        }
    }
}

-(void) purgeImage
{
    [self setDocument: nil];
    self.imageView.image = nil;
}

-(void) setImageFrame:(UIView *)imageFrame {
    if (_imageFrame != imageFrame) {
        if ((NO)) {
            imageFrame.layer.shadowOpacity = 0.5;
            imageFrame.layer.shadowOffset = CGSizeMake(0, 3.0);
        }
        _imageFrame = imageFrame;
    }
}

/*!
 Seems to be a bug in iOS 8 beta#?
 Cannont add constraints to the contentView using IB so we do it manually.
 */
//-(void) fixConstraints {
//    
//    NSMutableArray* constraints = [[NSMutableArray alloc] init];
//    
//    [constraints addObject: [NSLayoutConstraint
//                             constraintWithItem: self
//                             attribute: NSLayoutAttributeHeight
//                             relatedBy:NSLayoutRelationEqual
//                             toItem: nil
//                             attribute: 0
//                             multiplier: 1.0
//                             constant: 262.0]];
//    [constraints addObject: [NSLayoutConstraint
//                             constraintWithItem: self
//                             attribute: NSLayoutAttributeWidth
//                             relatedBy:NSLayoutRelationEqual
//                             toItem: nil
//                             attribute: 0
//                             multiplier: 1.0
//                             constant: 154.]];
//    
//    [self addConstraints: constraints];
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
