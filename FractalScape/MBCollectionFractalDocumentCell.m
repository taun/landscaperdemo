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
    
    self.info = nil;
    
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
    
    [self.transferIndicator setDirection: 0 progress: 0];
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

-(void) propertyDocumentDidChange: (NSDictionary*)changes object: (id)infoObject
{
    id old = changes[NSKeyValueChangeOldKey];
    if (old != nil && old != [NSNull null] && [old conformsToProtocol:@protocol(MDBFractaDocumentProtocol)])
    {
        id<MDBFractaDocumentProtocol> document = old;
        [self.kvoController unobserve: document];
    }
    
    id new = changes[NSKeyValueChangeNewKey];
    if (new != nil && new != [NSNull null] && [new conformsToProtocol:@protocol(MDBFractaDocumentProtocol)])
    {
        id<MDBFractaDocumentProtocol> document = new;
        
        if (document.loadResult == MDBFractalDocumentLoad_SUCCESS)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (document.fractal.name) self.textLabel.text = document.fractal.name;
                if (document.fractal.descriptor) self.detailTextLabel.text = document.fractal.descriptor;
            });

            
            [self.kvoController observe: document
                                keyPath: @"thumbnail"
                                options: NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                 action: @selector(propertyDcoumentThumbnailDidChange:object:)];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.textLabel.text = document.loadResultString;
            });
        }
    }
}

-(void) propertyDcoumentThumbnailDidChange: (NSDictionary*)change object: (id)object
{
    if ([object thumbnail])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = [object thumbnail];
            [object closeWithCompletionHandler:^(BOOL success) {}];
        });
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
            if (_info.isUploading) [self.transferIndicator setDirection: 1 progress: _info.uploadingProgress];
            // prioritize display of downloading over uploading
            if (_info.isDownloading) [self.transferIndicator setDirection: -1 progress: _info.downloadingProgress];
        }
        else if (!_info.isCurrent)
        {
            [self.transferIndicator setDirection: -1 progress: _info.downloadingProgress];
        }
        else
        {
            [self.transferIndicator setDirection: 0 progress: 0];
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
        [self.kvoController unobserve: _info.document];
        
        _info = info;
        
        if (_info)
        {
            [self.kvoController observe: _info
                                keyPath: @"document"
                                options: NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                 action: @selector(propertyDocumentDidChange:object:)];
            
            [self.kvoController observe: _info
                                keyPath: @"fileStatusChanged"
                                options: 0
                                 action: @selector(updateProgessIndicator)];
            
        }
        else
        {
            _imageView.image = nil;
            _textLabel.text = @"Loading..";
            _detailTextLabel.text = @"";
        }
    }
    [self updateProgessIndicator];
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
