//
//  MBStepperTableViewCell.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/23/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBStepperTableViewCell.h"

@implementation MBStepperTableViewCell

-(void) setupStepperObserver {
    [self addObserver: self forKeyPath: @"stepper.value" options: NSKeyValueObservingOptionNew context: NULL];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder: decoder];
    
    if (self) [self setupStepperObserver];
    
    return  self;
}

- (id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithFrame: frame reuseIdentifier: reuseIdentifier];

    if (self) [self setupStepperObserver];
    
    return self;
}

-(id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle: style reuseIdentifier: reuseIdentifier];
    
    if (self) [self setupStepperObserver];
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    // The user can only edit the text field when in editing mode.
    [super setEditing:editing animated:animated];
    self.stepper.enabled = editing;
}

/*!
 Action only works when changed through the GUI.
 The observer works for all changes.
 Unfortunately, could not figure out how to set the observer on load.
 */
- (IBAction)stepperValueChanged:(UIStepper *)aStepper {
    self.propertyValue.text = [self.formatter stringFromNumber: @(aStepper.value)];
    [self.propertyValue setNeedsDisplay];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: @"stepper.value"]) {
        [self stepperValueChanged: self.stepper];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void) dealloc {
    [self removeObserver: self forKeyPath: @"stepper.value"];
}

@end
