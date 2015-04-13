//
//  MDBFractalFiltersControllerViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 02/17/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalFiltersControllerViewController.h"
#import "MBLSFractalEditViewController.h"

#import "MBImageFilter.h"


@interface MDBFractalFiltersControllerViewController ()

@property (nonatomic,strong) NSArray        *filters;

@end

@implementation MDBFractalFiltersControllerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.view.translatesAutoresizingMaskIntoConstraints = NO;
//    _filterPicker.translatesAutoresizingMaskIntoConstraints = NO;
//    _filters = [CIFilter filterNamesInCategory: kCICategoryTileEffect];
    NSMutableArray* tempArray = [NSMutableArray new];
    [tempArray addObjectsFromArray: [CIFilter filterNamesInCategory: kCICategoryTileEffect]];
    [tempArray addObjectsFromArray: [CIFilter filterNamesInCategory: kCICategoryColorEffect]];
    [tempArray addObjectsFromArray: [CIFilter filterNamesInCategory: kCICategoryDistortionEffect]];
    [tempArray addObjectsFromArray: [CIFilter filterNamesInCategory: kCICategoryBlur]];
    _filters = [tempArray copy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//#pragma mark - UIPickerSource
//-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
//{
//    return 1;
//}
//-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
//{
//#if TARGET_INTERFACE_BUILDER
//    return 2;
//#else
//    return self.filters.count;
//#endif
//}
//
//#pragma mark - UIPickerDelegate
//-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
//{
//    return 24.0;
//}
//-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
//{
//    CGFloat width = self.filterPicker.bounds.size.width;
//    return width*(120.0/130.0);
//}
//-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    return self.filters[row];
//}
//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
//{
//    UILabel* tView = (UILabel*)view;
//    if (!tView)
//    {
//        tView = [[UILabel alloc] init];
//        [tView setFont:[UIFont systemFontOfSize: 18]];
//        //[tView setTextAlignment:UITextAlignmentLeft];
//        tView.numberOfLines=1;
//    }
//    // Fill the label text here
//    tView.text = self.filters[row];
//    return tView;
//}
//-(void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
//    [self.view becomeFirstResponder];
//    MBLSFractalEditViewController* editor = (MBLSFractalEditViewController*)self.fractalControllerDelegate;
//    
//    CIFilter *filter = [CIFilter filterWithName: self.filters[row]];
//
//    [editor applyFilter: filter];
//}

@end
