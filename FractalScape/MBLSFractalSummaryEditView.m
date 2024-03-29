//
//  MBLSFractalSummaryEditView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalSummaryEditView.h"
#import "FractalScapeIconSet.h"
#import "MDBFractalDocument.h"
#import "LSFractal.h"

#import "MDKLayerViewDesignable.h"

@interface MBLSFractalSummaryEditViewer ()
@property (nonatomic,weak) UIView           *contentView;
@property (nonatomic,assign) CGFloat        oldCategoryWidth;
@end

@implementation MBLSFractalSummaryEditViewer

-(BOOL)canBecomeFirstResponder
{
    return YES;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

-(void) setupSubviews {
    UIView* strongContentView;
    strongContentView = [[[NSBundle bundleForClass: [self class]] loadNibNamed: NSStringFromClass([self class]) owner: self options: nil] firstObject];
    [self addSubview: strongContentView];
    strongContentView.frame = self.bounds;
    _contentView = strongContentView;
  
#if TARGET_INTERFACE_BUILDER
    _name.text = @"Just testing";
#endif
    
    
    UITextView* strongDescriptor = _descriptor;
    MDKLayerViewDesignable* layerView = (MDKLayerViewDesignable*)strongDescriptor.superview;
    layerView.borderColor = [FractalScapeIconSet groupBorderColor];
    
    
#if TARGET_INTERFACE_BUILDER
    strongDescriptor.text = @"Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.";
#endif
    
    [self setupConstraints];
}

-(void) setupConstraints {
    UITextView* strongDescriptor = _descriptor;
    UITextField* strongName = _name;
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    strongName.translatesAutoresizingMaskIntoConstraints = NO;
    strongDescriptor.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView* descriptorBox = strongDescriptor.superview;
    descriptorBox.translatesAutoresizingMaskIntoConstraints = NO;
    //    descriptorBox.con
    
//    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(_name, _descriptor, _category, descriptorBox);
//    
//    [descriptorBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_descriptor]|" options:0 metrics: 0 views:viewsDictionary]];
//    [descriptorBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_descriptor]|" options:0 metrics: 0 views:viewsDictionary]];
//    
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[_name]-20-[_category(130)]-8-|" options:0 metrics: 0 views:viewsDictionary]];
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[descriptorBox(_name)]" options:0 metrics: 0 views:viewsDictionary]];
//    
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_category(100)]-8-|" options:0 metrics: 0 views:viewsDictionary]];
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_name]-[descriptorBox]-8-|" options:0 metrics: 0 views:viewsDictionary]];
    
    [self setNeedsLayout];
}

-(void) layoutSubviews {
    [super layoutSubviews];
    
    UITextView* strongDescriptor = _descriptor;
    MDKLayerViewDesignable* layerView = (MDKLayerViewDesignable*)strongDescriptor.superview;
    layerView.borderColor = [FractalScapeIconSet groupBorderColor];
    
    //    [self ];
}

-(void) setFractalDocument:(MDBFractalDocument *)fractalDocument {
    UITextView* strongDescriptor = _descriptor;
    UITextField* strongName = _name;

    _fractalDocument = fractalDocument;
    strongName.text = _fractalDocument.fractal.name;
    strongDescriptor.text = fractalDocument.fractal.descriptor;
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
//    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
//    {
//        UIPickerView* strongCategory = self.category;
//        NSLayoutConstraint* strongWidth = self.pickerViewWidthConstraint;
//        
//        strongCategory.hidden = YES;
//        self.oldCategoryWidth = strongWidth.constant;
//        strongWidth.constant = 0.0;
//        
//        UITextField* strongName = self.name;
//        [strongName setNeedsLayout];
//    }
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    UITextView* strongDescriptor = self.descriptor;
    strongDescriptor.editable = YES;
    [strongDescriptor becomeFirstResponder];
    return NO;
}

-(void) textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == _name) {
        if (![textField.text isEqualToString: self.fractalDocument.fractal.name]) {
            self.fractalDocument.fractal.name = textField.text;
            [self.fractalDocument updateChangeCount: UIDocumentChangeDone];
        }
    }
}

#pragma mark - UITextViewDelegate
-(BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    [[UIApplication sharedApplication] openURL: URL];
    
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        
        [textView resignFirstResponder];
        
        // Return FALSE so that the final '\n' character doesn't get added
        return NO;
    }
    // For any other character return TRUE so that the text gets added to the view
    return YES;
}

-(void) textViewDidEndEditing:(UITextView *)textView
{
    if (textView == _descriptor) {
        if (![textView.text isEqualToString: self.fractalDocument.fractal.descriptor]) {
            self.fractalDocument.fractal.descriptor = textView.text;
            [self.fractalDocument updateChangeCount: UIDocumentChangeDone];
        }
    }
    textView.editable = NO;
}

- (IBAction)descriptorTextViewTapped:(UITapGestureRecognizer *)sender
{
    UITextView* view = (UITextView*)sender.view;
    if ([view isMemberOfClass: [UITextView class]])
    {
        view.editable = YES;
        [view becomeFirstResponder];
    }
}
@end