//
//  MBLSFractalSummaryEditView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalSummaryEditView.h"
#import "MDKLayerViewDesignable.h"
#import "FractalScapeIconSet.h"

@implementation MBLSFractalSummaryEditViewer

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
    UIView* view = [[[NSBundle bundleForClass: [self class]] loadNibNamed: NSStringFromClass([self class]) owner: self options: nil] firstObject];
    [self addSubview: view];
    view.frame = self.bounds;
    
#if TARGET_INTERFACE_BUILDER
    _name.text = @"Just testing";
#endif
    
    [_category selectRow: 2 inComponent: 0 animated: NO];
    
    MDKLayerViewDesignable* layerView = (MDKLayerViewDesignable*)_descriptor.superview;
    layerView.borderColor = [FractalScapeIconSet groupBorderColor];
    
    
#if TARGET_INTERFACE_BUILDER
    _descriptor.text = @"Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.";
#endif
    
    [self setupConstraints];
    
}

-(void) setupConstraints {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    _name.translatesAutoresizingMaskIntoConstraints = NO;
    _descriptor.translatesAutoresizingMaskIntoConstraints = NO;
    _category.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView* descriptorBox = _descriptor.superview;
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
    
    MDKLayerViewDesignable* layerView = (MDKLayerViewDesignable*)_descriptor.superview;
    layerView.borderColor = [FractalScapeIconSet groupBorderColor];
    
    //    [self ];
}

-(void) setFractal:(LSFractal *)fractal {
    _fractal = fractal;
    _name.text = _fractal.name;
    _descriptor.text = fractal.descriptor;
    NSInteger categoryIndex = [[self.fractal allCategories] indexOfObject: self.fractal.category];
    [_category reloadAllComponents];
    [_category selectRow: categoryIndex inComponent: 0 animated: YES];
}
#pragma mark - UITextFieldDelegate
-(void) textFieldDidEndEditing:(UITextField *)textField {
    if (textField == _name) {
        self.fractal.name = textField.text;
    }
}
#pragma mark - UITextViewDelegate
-(void) textViewDidEndEditing:(UITextView *)textView
{
    if (textView == _descriptor) {
        self.fractal.descriptor = textView.text;
    }
}

#pragma mark - UIPickerSource
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
#if TARGET_INTERFACE_BUILDER
    return 4;
#else
    return [[self.fractal allCategories] count];
#endif
}

#pragma mark - UIPickerDelegate
-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 24.0;
}
-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat width = _category.bounds.size.width;
    return width*(120.0/130.0);
}
-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSArray* categories;
    
#if TARGET_INTERFACE_BUILDER
    categories = @[@"one",@"two",@"three",@"four"];
#else
    categories = [self.fractal allCategories];
#endif
    return categories[row];
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel* tView = (UILabel*)view;
    if (!tView)
    {
        tView = [[UILabel alloc] init];
        [tView setFont:[UIFont systemFontOfSize: 18]];
        //[tView setTextAlignment:UITextAlignmentLeft];
        tView.numberOfLines=1;
    }
    // Fill the label text here
    tView.text = [self.fractal allCategories][row];
    return tView;
}
-(void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString* category = [self.fractal allCategories][row];
    self.fractal.category = category;
    [self saveContext];
}
// TODO: change to sendActionsFor...
//- (void)textViewDidEndEditing:(UITextView *)textView {
//    //    if (textView == self.fractalDescriptor) {
//    //        self.fractal.descriptor = textView.text;
//    //    }
//    self.fractal.descriptor = textView.text;
//    [self saveContext];
//}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.fractal.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } else {
            //            self.fractalDataChanged = YES;
        }
    }
}

@end