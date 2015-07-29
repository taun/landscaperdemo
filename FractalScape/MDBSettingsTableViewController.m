//
//  MDBSettingsTableViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 07/15/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBSettingsTableViewController.h"

#import "MDBAppModel.h"


@interface MDBSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *allowPremiumSwitch;

- (IBAction)allowPremiumButtonChanged:(UISwitch *)sender;

@end

@implementation MDBSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef DEBUG
    [self.tableView deleteSections: [NSIndexSet indexSetWithIndex: 3] withRowAnimation: UITableViewRowAnimationNone];
#endif

    // Do any additional setup after loading the view.
    UIView *backgroundView = [[UIView alloc] initWithFrame: self.view.bounds];
//    UIColor* notePadYellow = [UIColor colorWithRed: 0.8 green: 0.8 blue: 0 alpha: 1.0];
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


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateControls];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateUIDueToSettingsChange) name: NSUserDefaultsDidChangeNotification object: nil];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSUserDefaultsDidChangeNotification object: nil];
}
-(void)updateUIDueToSettingsChange
{
    [self updateControls];
}
-(void) updateControls
{
    self.appVersion.text = self.appModel.versionBuildString;
    
    self.showHelpTipsSwitch.on = self.appModel.showHelpTips;
    self.showParallaxEffect.on = self.appModel.showParallax;
    
    self.allowPremiumSwitch.on = self.appModel.allowPremium;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)showHelpTipsChanged:(UISwitch *)sender
{
    [self.appModel setShowHelpTips: sender.on];
}

- (IBAction)showParallaxEffectChanged:(UISwitch *)sender
{
    [self.appModel setShowParallax: sender.on];
}

-(void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath: indexPath];
    NSString* identifier = cell.reuseIdentifier;
    if ([identifier isEqualToString: @"LaunchSettings"])
    {
        //
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: UIApplicationOpenSettingsURLString]];
    }
    else if ([identifier isEqualToString: @"LaunchTwitter"])
    {
        //
        NSURL* twitterAccount = [NSURL URLWithString:@"twitter://user?screen_name=taunc"];
        BOOL twitter = [[UIApplication sharedApplication] canOpenURL:twitterAccount];
        if (!twitter)
        {
            [[UIApplication sharedApplication] openURL: twitterAccount];
        }
        else
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.twitter.com/taunc"]];
        }
    }
}

- (IBAction)allowPremiumButtonChanged:(UISwitch *)sender
{
    [self.appModel ___setAllowPremium: sender.on];
}

- (IBAction)useWatermarkButtonChanged:(UISwitch *)sender
{
    [self.appModel ___setUseWatermark: sender.on];
}
@end
