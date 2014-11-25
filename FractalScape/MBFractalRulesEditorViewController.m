//
//  MBFractalRulesEditorViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalRulesEditorViewController.h"
#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "LSDrawingRuleType+addons.h"


@interface MBFractalRulesEditorViewController ()

@end

@implementation MBFractalRulesEditorViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.editing = YES;
}
-(void) viewDidDisappear:(BOOL)animated {
    [self saveContext];
    [super viewDidDisappear:animated];
}
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setFractal:(LSFractal *)fractal {
    _fractal = fractal;
    self.fractalSummaryEditView.fractal = _fractal;
//    self.fractalStartRulesListView.rules = [_fractal mutableOrderedSetValueForKey: @"startingRules"];
    self.fractalStartRulesListView.rules = [_fractal.drawingRulesType mutableOrderedSetValueForKey: @"rules"];
}

@end
