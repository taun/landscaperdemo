//
//  MDBSettingsTableViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 07/15/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBSettingsTableViewController.h"

#import "MDBAppModel.h"
#import "MDBPurchaseViewController.h"
#import "MDBProPurchaseableProduct.h"


@interface MDBSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *allowPremiumSwitch;
@property (weak, nonatomic) IBOutlet UIButton *moedaeButton;
@property (nonatomic,strong) UIDynamicAnimator*buttonAnimator;

- (IBAction)allowPremiumButtonChanged:(UISwitch *)sender;
- (IBAction)jumpToAppSettings:(id)sender;
- (IBAction)leaveForTwitter:(id)sender;
- (IBAction)leaveForFacebook:(id)sender;
- (IBAction)moedaeButtonTapped:(id)sender;
- (IBAction)leaveForAppStore:(id)sender;
- (IBAction)leaveForEmail:(id)sender;

@end

@implementation MDBSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //#ifndef DEBUG
//    [self.tableView deleteSections: [NSIndexSet indexSetWithIndex: 3] withRowAnimation: UITableViewRowAnimationNone];
    //#endif

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
    [self stopAnimation];
}
-(void)updateUIDueToSettingsChange
{
    [self updateControls];
}
-(void) updateControls
{
    self.appVersion.text = self.appModel.versionString;
    self.appBuild.text = self.appModel.buildString;
    
    self.showHelpTipsSwitch.on = self.appModel.showHelpTips;
    self.showParallaxSwitch.on = self.appModel.showParallax;
    self.showWatermarkSwitch.on = self.appModel.useWatermark;
    self.hideOriginSwitch.on = self.appModel.hideOrigin;
    
    MDBProPurchaseableProduct* proPak = self.appModel.purchaseManager.proPak;
    self.showWatermarkSwitch.enabled = proPak.hasLocalReceipt;
    
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

-(IBAction)hideOriginChanged:(UISwitch*)sender
{
    [self.appModel setHideOrigin: sender.on];
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView* headerView = (UITableViewHeaderFooterView*)view;
    headerView.textLabel.textColor = [UIColor lightGrayColor];
}

-(void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
//    UITableViewCell* cell = [tableView cellForRowAtIndexPath: indexPath];
//    NSString* identifier = cell.reuseIdentifier;
//    if ([identifier isEqualToString: @"LaunchSettings"])
//    {
//        //
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: UIApplicationOpenSettingsURLString]];
//    }
//    else if ([identifier isEqualToString: @"LaunchTwitter"])
//    {
//        //
//        NSURL* twitterAccount = [NSURL URLWithString:@"twitter://user?screen_name=taunc"];
//        BOOL twitter = [[UIApplication sharedApplication] canOpenURL:twitterAccount];
//        if (!twitter)
//        {
//            [[UIApplication sharedApplication] openURL: twitterAccount];
//        }
//        else
//        {
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.twitter.com/taunc"]];
//        }
//    }
//    else if ([identifier isEqualToString: @"LaunchFacebook"])
//    {
//        //
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://www.facebook.com/fractalscapes"]];
//    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString: @"ShowPurchaseControllerSegue"])
    {
        //
        UINavigationController* navCon = (UINavigationController*)segue.destinationViewController;
        MDBPurchaseViewController* pvc = [navCon.viewControllers firstObject];
        pvc.purchaseManager = self.appModel.purchaseManager;
    }
}

- (IBAction)allowPremiumButtonChanged:(UISwitch *)sender
{
    [self.appModel ___setAllowPremium: sender.on];
}

- (IBAction)jumpToAppSettings:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: UIApplicationOpenSettingsURLString]];
}

- (IBAction)leaveForTwitter:(id)sender
{
    NSURL* twitterAccount = [NSURL URLWithString:@"twitter://user?screen_name=taunc"];
    BOOL twitter = [[UIApplication sharedApplication] canOpenURL:twitterAccount];
    if (!twitter)
    {
        [[UIApplication sharedApplication] openURL: twitterAccount];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.twitter.com/taunc"]];
    }
}

- (IBAction)leaveForFacebook:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://www.facebook.com/fractalscapes"]];
}

- (IBAction)leaveForEmail:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"mailto:help@fractalscapes.info"]];
}

- (IBAction)moedaeButtonTapped:(id)sender
{
    if (!_buttonAnimator || !self.buttonAnimator.running) {
        [self generateAnimatedButtonView];
    }
    else
    {
        [self stopAnimation];
    }
}

-(void)stopAnimation
{
    if (_buttonAnimator && self.buttonAnimator.running) [self.buttonAnimator removeAllBehaviors];
}

-(UIDynamicAnimator*) buttonAnimator
{
    if (_buttonAnimator == nil)
    {
        _buttonAnimator = [[UIDynamicAnimator alloc] initWithReferenceView: self.moedaeButton.superview];
    }
    
    return _buttonAnimator;
}

-(void) generateAnimatedButtonView
{
    UIDynamicItemBehavior* behaviour = [[UIDynamicItemBehavior alloc] init];
    [behaviour addItem: self.moedaeButton];
    behaviour.density = 1000;
    behaviour.angularResistance = 0;
    [behaviour addAngularVelocity: 6.28/60 forItem: self.moedaeButton];
    
    [self.buttonAnimator addBehavior: behaviour];
}

- (IBAction)leaveForAppStore:(id)sender
{
    // https://itunes.apple.com/us/app/fractalscapes-interactive/id916265154?ls=1&mt=8
    // https://geo.itunes.apple.com/us/app/fractalscapes-interactive/id916265154?mt=8
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://itunes.apple.com/us/app/fractalscapes-interactive/id916265154?ls=1&mt=8"]];
}

- (IBAction)useWatermarkButtonChanged:(UISwitch *)sender
{
    [self.appModel ___setUseWatermark: sender.on];
}

-(void)unwindFromPurchaseController:(UIStoryboardSegue *)segue
{
    UIViewController* sourceController = (UIViewController*)segue.sourceViewController;
    
    // This is necessary due to presentation being over full context, popover style
    [sourceController.presentingViewController dismissViewControllerAnimated: YES completion:^{
        
    }];
}

@end
