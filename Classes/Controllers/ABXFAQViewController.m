//
//  ABXFAQViewController.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXFAQViewController.h"

#import "ABXFaq.h"
#import "ABXFeedbackViewController.h"
#import "NSString+ABXLocalized.h"

@interface ABXFAQViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UIView *bottom;

@end

@implementation ABXFAQViewController

- (void)dealloc
{
    self.webview.delegate = nil;
    self.webview = nil;
}

+ (void)pushOnNavController:(UINavigationController*)navigationController faq:(ABXFaq*)faq hideContactButton:(BOOL)hideContactButton
{
    // Show the details
    ABXFAQViewController* controller = [[ABXFAQViewController alloc] init];
    controller.faq = faq;
    controller.hideContactButton = hideContactButton;
    [navigationController pushViewController:controller animated:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [@"FAQ" localizedString];
    
    // Webview
    CGRect bounds = self.view.bounds;
    bounds.size.height -= 44;
    self.webview = [[UIWebView alloc] initWithFrame:bounds];
    self.webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webview.clipsToBounds = NO;
    self.webview.delegate = self;
    [self.view addSubview:self.webview];
    
    [self addToolbar];
    
    // Nav buttons
    if (!self.hideContactButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithTitle:[@"Contact" localizedString]
                                                  style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(onContact)];
    }
    
    // Load the HTML
    NSString *html = [NSString stringWithFormat:
                      @"<html>"
                      @"<head>"
                      @"<style>"
                      @"body { font-family: 'Helvetica Neue'; font-size:15px; padding:10px; }"
                      "h1 {font-weight: 400; font-size:24px;}"
                      "img {max-width:100%%}"
                      ".answer {white-space: pre-wrap;}"
                      @"</style>"
                      @"</head>"
                      @"<body>"
                      @"<h1>%@</h1>"
                      @"<div class='answer'>%@</div>"
                      @"</html>"
                      "</body>", self.faq.question, self.faq.answer];
    [self.webview loadHTMLString:html
                         baseURL:nil];
    
    // Record a view, ignore the result
    [self.faq recordView:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.r
}

#pragma mark - Buttons

- (void)onContact
{
    [ABXFeedbackViewController showFromController:self
                                      placeholder:[@"How can we help?" localizedString]];
}

#pragma mark - UI

- (void)addToolbar
{
    // Toolbar
    UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 44, CGRectGetWidth(self.view.frame), 44)];
    bottom.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    bottom.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bottom];
    self.bottom = bottom;
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:bottom.bounds];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [bottom addSubview:toolbar];
    
    // Voting label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 44)];
    label.font = [UIFont systemFontOfSize:15];
    label.text = [@"Helpful?" localizedString];
    label.backgroundColor = [UIColor clearColor];
    [bottom addSubview:label];
    
    // Upvote button
    UIButton *yesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] == NSOrderedAscending) {
        yesButton.frame = CGRectMake(CGRectGetWidth(bottom.bounds) - 132, 6, 44, 32);
    }
    else {
        yesButton.frame = CGRectMake(CGRectGetWidth(bottom.bounds) - 132, 0, 44, 44);
    }
    yesButton.layer.cornerRadius = 4;
    yesButton.layer.masksToBounds = YES;
    [yesButton setTitle:[@"Yes" localizedString] forState:UIControlStateNormal];
    yesButton.titleLabel.font = [UIFont systemFontOfSize:15];
    yesButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [yesButton addTarget:self action:@selector(onUpVote) forControlEvents:UIControlEventTouchUpInside];
    [bottom addSubview:yesButton];
    
    // Downvote button
    UIButton *noButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] == NSOrderedAscending) {
        noButton.frame = CGRectMake(CGRectGetWidth(bottom.bounds) - 66, 6, 44, 32);
    }
    else {
        noButton.frame = CGRectMake(CGRectGetWidth(bottom.bounds) - 66, 0, 44, 44);
    }
    noButton.layer.cornerRadius = 4;
    noButton.layer.masksToBounds = YES;
    [noButton setTitle:[@"No" localizedString] forState:UIControlStateNormal];
    noButton.titleLabel.font = [UIFont systemFontOfSize:15];
    noButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [noButton addTarget:self action:@selector(onDownVote) forControlEvents:UIControlEventTouchUpInside];
    [bottom addSubview:noButton];
}

#pragma mark - Buttons

- (void)onDone
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Voting

- (void)clearBottomBar
{
    // Remove the existing views
    for (UIView *v in self.bottom.subviews) {
        if (![v isKindOfClass:[UIToolbar class]]) {
            [v removeFromSuperview];
        }
    }
}

- (void)showVoteLoading
{
    [self clearBottomBar];
    
    // Spinner
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activity startAnimating];
    activity.center = CGPointMake(32, 22);
    [self.bottom addSubview:activity];
    
    // Label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 200, 44)];
    label.font = [UIFont systemFontOfSize:15];
    label.text = [@"One moment please..." localizedString];
    label.backgroundColor = [UIColor clearColor];
    [self.bottom addSubview:label];
}

- (void)completeVoting
{
    [self clearBottomBar];
    
    // Label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 44)];
    label.font = [UIFont systemFontOfSize:15];
    label.text = [@"Thanks for your feedback." localizedString];
    label.backgroundColor = [UIColor clearColor];
    [self.bottom addSubview:label];
}

- (void)onDownVote
{
    // Thumbs down
    [self showVoteLoading];
    [self.faq downvote:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error) {
        [self completeVoting];
    }];
}

- (void)onUpVote
{
    // Thumbsup
    [self showVoteLoading];
    [self.faq upvote:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error) {
        [self completeVoting];
    }];
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    return YES;
}

@end
