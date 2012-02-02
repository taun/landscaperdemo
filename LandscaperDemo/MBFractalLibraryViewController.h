//
//  MBFractalLibraryViewController.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FractalPadView;


@interface MBFractalLibraryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *fractalTableView;

@end
