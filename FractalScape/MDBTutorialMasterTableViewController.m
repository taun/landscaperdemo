//
//  MDBTutorialMasterTableViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 07/19/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBTutorialMasterTableViewController.h"
#import "MDBTutorialDetailContainerViewController.h"



@interface MDBTutorialMasterTableViewController ()

@end

@implementation MDBTutorialMasterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    if (self.defaultController) {
//        UIViewController* childController = [self.storyboard instantiateViewControllerWithIdentifier: self.defaultController];
//        [self.splitViewController showDetailViewController: childController sender: self];
//    }
    
    UIView *backgroundView = [[UIView alloc] initWithFrame: self.view.bounds];
//    backgroundView.backgroundColor = [UIColor yellowColor];
    backgroundView.backgroundColor = self.view.tintColor;
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"documentThumbnailPlaceholder1024"]];
    [backgroundView addSubview: imageView];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIVisualEffectView* visualEffectView = [[UIVisualEffectView alloc] initWithEffect: [UIBlurEffect effectWithStyle: UIBlurEffectStyleExtraLight]];
    [backgroundView addSubview: visualEffectView];
    visualEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(imageView, visualEffectView);
    [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|" options:0 metrics:nil views:viewsDictionary]];
    [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics:nil views:viewsDictionary]];
    [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[visualEffectView]|" options:0 metrics:nil views:viewsDictionary]];
    [backgroundView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[visualEffectView]|" options:0 metrics:nil views:viewsDictionary]];
    
    self.tableView.backgroundView = backgroundView;
}
//HelpIntroductionControllerSegue

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //TutorialDetailNavController
    UINavigationController* detailNav = [self.storyboard instantiateViewControllerWithIdentifier: @"TutorialDetailNavController"];
    
//    if (self.splitViewController.viewControllers.count > 1 && self.splitViewController.isCollapsed)
//    {
//        NSInteger endIndex = indexPath.row;
//
//        NSMutableArray* tutorialControllers = [NSMutableArray arrayWithCapacity: endIndex + 1];
//        
//        for (NSInteger i=0; i <= endIndex; i++)
//        {
//            UITableViewCell* cell = [tableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow: i inSection: indexPath.section]];
//            NSString* identifier = cell.reuseIdentifier;
//            UIViewController* childController = [self.storyboard instantiateViewControllerWithIdentifier: identifier];
//            [tutorialControllers addObject: childController];
//        }
//        [detailNav setViewControllers: tutorialControllers animated: YES];
//        [self showDetailViewController: detailNav sender: nil];
//    }
//    else
//    {
        UITableViewCell* cell = [tableView cellForRowAtIndexPath: indexPath];
        NSString* identifier = cell.reuseIdentifier;
        UIViewController* childController = [self.storyboard instantiateViewControllerWithIdentifier: identifier];
        [detailNav setViewControllers: @[childController]];
        [self showDetailViewController: detailNav sender: cell];
//    }
}

#pragma mark - Table view data source

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}
*/
/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
