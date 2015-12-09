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
#import "MDBURLPlusMetaData.h"
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
    [self.kvoController unobserve: _info.document];
    [self.kvoController unobserve: _info];
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

-(void)updateProgessIndicator
{
#pragma message "TODO add bad file load indicator"
    if (_info.urlPlusMeta.metaDataItem)
    {
        self.transferIndicator.hidden = NO;
        
        if (_info.isDownloading || _info.isUploading)
        {
            if (_info.isDownloading)
            {
                self.transferIndicator.progress = - _info.downloadingProgress;
            }
            else if (_info.isUploading)
            {
                self.transferIndicator.progress = _info.uploadingProgress;
            }
        }
        else
        {
            self.transferIndicator.progress = 100.0;
        }
    }
    else
    {
        self.transferIndicator.hidden = YES;
    }
}

-(void)setInfo:(MDBFractalInfo *)info
{
    if (_info != info)
    {
//        [self configureDefaults];
        
        [self.activityIndicator stopAnimating];
        
        [self.kvoController unobserve: _info];
        
        _info = info;
        
        if (_info)
        {
            if ( _info.document.loadResult == MDBFractalDocumentLoad_SUCCESS)
            {
                if ( _info.document.fractal.name) self.textLabel.text =  _info.document.fractal.name;
                if ( _info.document.fractal.descriptor) self.detailTextLabel.text =  _info.document.fractal.descriptor;
                [self propertyDcoumentThumbnailDidChange: nil object:  _info.document];
                [self.kvoController observe:  _info.document keyPath: @"thumbnail" options: 0 action: @selector(propertyDcoumentThumbnailDidChange:object:)];
                [self.kvoController observe: _info keyPath: @"fileStatusChanged" options: 0 action: @selector(updateProgessIndicator)];
            } else {
                self.textLabel.text =  _info.document.loadResultString;
            }
            
            [self updateProgessIndicator];

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
    [self setInfo: nil];
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
