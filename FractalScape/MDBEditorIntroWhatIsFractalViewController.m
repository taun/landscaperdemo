//
//  MDBEditorIntroWhatIsFractalViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/17/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBEditorIntroWhatIsFractalViewController.h"

@interface MDBEditorIntroWhatIsFractalViewController ()


@end

@implementation MDBEditorIntroWhatIsFractalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    UIWebView* webView = [[UIWebView alloc] initWithFrame: CGRectZero];
//    webView.translatesAutoresizingMaskIntoConstraints = NO;
//    webView.backgroundColor = [UIColor clearColor];
//    
//    self.webView = webView;
//
//    [self.webContainer addSubview: self.webView];
//    self.webView.frame = self.webContainer.bounds;
//    
//    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(webView);
//    
//    [self.webContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[webView]-0-|"
//                                                                          options: 0
//                                                                          metrics: nil
//                                                                            views: viewsDictionary]];
//    
//    [self.webContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-0-[webView]-0-|"
//                                                                          options: 0
//                                                                          metrics: nil
//                                                                            views: viewsDictionary]];
//    [self loadDocument: self.documentName];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [self.webContainer setNeedsLayout];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [self layoutWebView];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void)layoutWebView
{
    WKWebViewConfiguration* config = [WKWebViewConfiguration new];
    config.allowsAirPlayForMediaPlayback = NO;
    config.suppressesIncrementalRendering = YES;
    
    WKWebView* webView = [[WKWebView alloc] initWithFrame: self.webContainer.bounds configuration: config];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.backgroundColor = [UIColor clearColor];
    webView.allowsBackForwardNavigationGestures = NO;
    
    self.webView = webView;
    
    [self.webContainer addSubview: self.webView];
    self.webView.frame = self.webContainer.bounds;
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(webView);
    
    [self.webContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[webView]-0-|"
                                                                               options: 0
                                                                               metrics: nil
                                                                                 views: viewsDictionary]];
    
    [self.webContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-48-[webView]-0-|"
                                                                               options: 0
                                                                               metrics: nil
                                                                                 views: viewsDictionary]];
}

-(void)setDocumentName:(NSString *)documentName
{
    if (_documentName != documentName)
    {
        _documentName = documentName;
        if (_documentName) [self loadDocument: _documentName];
    }
}

-(void)loadDocument:(NSString*)documentName {
    if (documentName)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:documentName ofType:nil];
        NSURL *url = [NSURL fileURLWithPath:path];
        NSString* html = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: nil];
        WKNavigation* navigation = [self.webView loadHTMLString: html baseURL: url];
    }
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.webView setNeedsLayout];
    [self.webView layoutIfNeeded];
    [self.webContainer setNeedsLayout];
    [self.webContainer layoutIfNeeded];
}

-(void)dealloc
{
    
}

@end
