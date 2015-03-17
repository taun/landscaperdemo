//
//  MBStepperTableViewCell.h
//  FractalScape
//
//  Created by Taun Chapman on 02/23/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;


@interface MBStepperTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView*   propertyImage;
@property (nonatomic, weak) IBOutlet UILabel*       propertyLabel;
@property (nonatomic, weak) IBOutlet UITextField*   propertyValue;
@property (nonatomic, weak) IBOutlet UIStepper*     stepper;
@property (nonatomic, strong) NSNumberFormatter*    formatter;

- (IBAction)stepperValueChanged:(UIStepper *)aStepper;
@end
