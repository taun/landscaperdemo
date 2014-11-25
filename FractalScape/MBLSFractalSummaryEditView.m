//
//  MBLSFractalSummaryEditView.m
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalSummaryEditView.h"

@implementation MBLSFractalSummaryEditView

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
    _name = [[UITextField alloc] initWithFrame: CGRectMake(10, 10, 220, 44)];
#if TARGET_INTERFACE_BUILDER
    _name.text = @"Just testing";
#endif
    _name.borderStyle = UITextBorderStyleRoundedRect;
    [self addSubview: _name];
    
    _category = [[UIPickerView alloc] initWithFrame: CGRectMake(300, 10, 130, 100)];
    _category.dataSource = self;
    _category.delegate = self;
    _category.showsSelectionIndicator = YES;
    _category.backgroundColor = [UIColor clearColor];
    [_category selectRow: 2 inComponent: 0 animated: NO];
    [self addSubview: _category];
    
    UIView* textViewBox = [[UIView alloc] initWithFrame: CGRectMake(10, 60, 120, 88)];
    textViewBox.layer.borderColor = _borderColor ? _borderColor.CGColor : nil;
    textViewBox.layer.borderWidth = 1.0;
    textViewBox.layer.cornerRadius = 6.0;
    
    [self addSubview: textViewBox];
    
    _descriptor = [[UITextView alloc] initWithFrame: CGRectMake(0, 0, 120, 88)];
#if TARGET_INTERFACE_BUILDER
    _descriptor.text = @"Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.";
#endif
    [textViewBox addSubview: _descriptor];
    
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
    
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(_name, _descriptor, _category, descriptorBox);
    
    [descriptorBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_descriptor]|" options:0 metrics: 0 views:viewsDictionary]];
    [descriptorBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_descriptor]|" options:0 metrics: 0 views:viewsDictionary]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[_name]-20-[_category(130)]-8-|" options:0 metrics: 0 views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[descriptorBox(_name)]" options:0 metrics: 0 views:viewsDictionary]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_category(100)]-8-|" options:0 metrics: 0 views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_name]-[descriptorBox]-8-|" options:0 metrics: 0 views:viewsDictionary]];
    
    [self setNeedsLayout];
}

-(void) layoutSubviews {
    [super layoutSubviews];
    
    _descriptor.superview.layer.borderColor = _borderColor ? _borderColor.CGColor : nil;
    
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

#pragma mark - UIPickerSource
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
#if TARGET_INTERFACE_BUILDER
    return 4;
#else
    return [[self.fractal allCategories] count];
#endif
}

#pragma mark - UIPickerDelegate
-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 24.0;
}
-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 120.0;
}
-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSArray* categories;
    
#if TARGET_INTERFACE_BUILDER
    categories = @[@"one",@"two",@"three",@"four"];
#else
    categories = [self.fractal allCategories];
#endif
    return categories[row];
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