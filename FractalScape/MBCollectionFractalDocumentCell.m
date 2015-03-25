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

@interface MBCollectionFractalDocumentCell ()

@property (weak, nonatomic) IBOutlet UIView         *imageFrame;
@property (weak, nonatomic) IBOutlet UIImageView    *imageView;
@property (weak, nonatomic) IBOutlet UILabel        *textLabel;
@property (weak, nonatomic) IBOutlet UILabel        *detailTextLabel;

@end

@implementation MBCollectionFractalDocumentCell


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self configureDefaults];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        //
        [self configureDefaults];
    }
    return self;
}
-(void) configureDefaults
{
    
//    [self fixConstraints];

    _radius = 5.0;
    
    _textLabel.text = @"Loading..";
    _detailTextLabel.text = @"";
    
    _imageView.image = nil;
    
//    UIImage* placeholder = [UIImage imageNamed: @"documentThumbnailPlaceholder130"];
//    UIImageView* strongImageView = self.imageView;
//    strongImageView.image = placeholder;
    
    if (!self.backgroundView) {
        MBColorCellBackgroundView* backgroundView = [MBColorCellBackgroundView new];
        self.backgroundView = backgroundView;
    }
    
    self.selectedBackgroundView = [self configureSelectedBackgroundViewFrame: CGRectZero];
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
-(void)setDocument:(MDBFractalDocument *)document
{
    if (_document != document)
    {
        [self configureDefaults];
        
        _document = document;
        
        if (_document)
        {
            if (_document.fractal.name) self.textLabel.text = _document.fractal.name;
            if (_document.fractal.descriptor) self.detailTextLabel.text = _document.fractal.descriptor;
            if (_document.thumbnail) self.imageView.image = _document.thumbnail;
        }
        else
        {
            [self configureDefaults];
        }
    }
}
-(void) setImageFrame:(UIView *)imageFrame {
    if (_imageFrame != imageFrame) {
        if ((YES)) {
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
