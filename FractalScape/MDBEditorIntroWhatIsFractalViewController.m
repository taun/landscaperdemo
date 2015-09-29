//
//  MDBEditorIntroWhatIsFractalViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/17/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBEditorIntroWhatIsFractalViewController.h"
#import "MDBMainLibraryTabBarController.h"
#import "MDBAppModel.h"

@interface MDBEditorIntroWhatIsFractalViewController ()

@property(nonatomic,strong) NSArray        *documentPaths;
@property(nonatomic,assign) NSUInteger     currentPage;
@property(nonatomic,strong) WKNavigation   *currentNavigation;

@end

@implementation MDBEditorIntroWhatIsFractalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.currentPage = 0;
    //[self layoutWebView];
    if ((NO))
    {
        [self loadDocument: self.currentPage];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [self.webContainer setNeedsLayout];
    if ((YES))
    {
        [self layoutWebView];
        [self loadDocument: self.currentPage];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ((NO))
    {
        [self loadDocument: self.currentPage];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.webView removeFromSuperview];
    self.webView = nil;
}

-(void)layoutWebView
{
    UIView* webView;
    UIWebView* uiWebView;
    WKWebView* wkWebView;
    
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    
    if ([osVersion hasPrefix: @"8"])
    {
        /*
         iOS 8 WKWebView seems to have a problem with CSS and the documentation files
         so we use UIWebView only for iOS8.
         */
        uiWebView = [[UIWebView alloc] initWithFrame: CGRectZero];
        uiWebView.userInteractionEnabled = YES;
        uiWebView.delegate = self;
        uiWebView.translatesAutoresizingMaskIntoConstraints = NO;
        uiWebView.scrollView.backgroundColor = [UIColor clearColor];
        uiWebView.scrollView.alwaysBounceVertical = YES;
        uiWebView.scrollView.alwaysBounceHorizontal = NO;
        uiWebView.backgroundColor = [UIColor clearColor];
        uiWebView.scalesPageToFit = YES;
        
        webView = uiWebView;
    }
    else
    {
        WKPreferences* prefs = [WKPreferences new];
        prefs.javaScriptEnabled = YES;
        
        WKWebViewConfiguration* config = [WKWebViewConfiguration new];
        config.preferences = prefs;
        //    config.allowsAirPlayForMediaPlayback = NO;
        config.suppressesIncrementalRendering = NO;
        
        wkWebView = [[WKWebView alloc] initWithFrame: self.webContainer.bounds configuration: config];
        wkWebView.userInteractionEnabled = YES;
        wkWebView.UIDelegate = self;
        wkWebView.navigationDelegate = self;
        wkWebView.translatesAutoresizingMaskIntoConstraints = NO;
        wkWebView.scrollView.backgroundColor = [UIColor clearColor];
        wkWebView.scrollView.alwaysBounceVertical = YES;
        wkWebView.scrollView.alwaysBounceHorizontal = NO;
        wkWebView.backgroundColor = [UIColor clearColor];
        wkWebView.allowsBackForwardNavigationGestures = NO;
        webView = wkWebView;
    }
    
    self.webView = webView;
    [self.webContainer addSubview: self.webView];
    self.webView.frame = self.webContainer.bounds;

    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(webView);
    
    [self.webContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[webView]-0-|"
                                                                               options: 0
                                                                               metrics: nil
                                                                                 views: viewsDictionary]];
    
    [self.webContainer addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-0-[webView]-0-|"
                                                                               options: 0
                                                                               metrics: nil
                                                                                 views: viewsDictionary]];
    
}

-(void)setDocumentName:(NSString *)documentName
{
    self.currentPage = 0;
    
    if (_documentName != documentName)
    {
        _documentName = documentName;
        
        NSMutableArray* tempDocuments = [NSMutableArray new];
        NSString *path;

        if ([_documentName hasSuffix: @"_"])
        {
            int documentIndex = 0;
            @try {
                do {
                    NSString* numberedDocumentName = [NSString stringWithFormat: @"%@%u",_documentName,documentIndex];
                    path = [[NSBundle mainBundle] pathForResource: numberedDocumentName ofType: @"html" inDirectory: @"documentation"];
                    if (path)
                    {
                        [tempDocuments addObject: path];
                    }
                    documentIndex++;
                } while (path || documentIndex > 10);
                
            }
            @catch (NSException *exception) {
                //
            }
            @finally {
                //
            }
        }
        else if (_documentName)
        {
            NSString* documentNameWithExtension = [NSString stringWithFormat: @"%@.html",_documentName];
            NSString* documentsDirectory = @"documentation";
            path = [[NSBundle mainBundle] pathForResource: documentNameWithExtension ofType: nil inDirectory: documentsDirectory];
            if (path)
            {
                [tempDocuments addObject: path];
            }
            else
            {
                NSLog(@"FractalScapes documentation path not found Name:%@, Path: %@",documentName,documentsDirectory);
            }
            
        }
        
        self.documentPaths = [tempDocuments copy];

        if (self.documentPaths.count > 0)
        {
            [self loadDocument: self.currentPage];
        }
    }
}

-(void)loadDocument:(NSUInteger)documentNumber {
    if (self.documentPaths.count > 0)
    {
//        NSString* folderPath = [NSString stringWithFormat: @"helpFiles\%@", documentName];
        NSString *path = self.documentPaths[documentNumber];
        NSURL *fullUrl = [NSURL fileURLWithPath: path];
        NSURL *folderUrl = fullUrl.URLByDeletingLastPathComponent;
        NSError* error;
        NSString* html = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
        if (error)
        {
            NSLog(@"[%@ %@] %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd), error);
        }
        [self.webView loadHTMLString: html baseURL: folderUrl];
    }
}

-(void)setCurrentPage:(NSUInteger)currentPage
{
    _currentPage = currentPage;
    
    if (currentPage == self.documentPaths.count - 1) self.nextPageButton.enabled = NO;
    if (currentPage == 0) self.prevPageButton.enabled = NO;
    
    if (currentPage < self.documentPaths.count - 1) self.nextPageButton.enabled = YES;
    if (currentPage > 0) self.prevPageButton.enabled = YES;
}

- (IBAction)nextPage:(UIBarButtonItem *)sender
{
    if (self.currentPage < self.documentPaths.count - 1)
    {
        self.currentPage += 1;
        [self loadDocument: self.currentPage];
    }
}

- (IBAction)prevPage:(UIBarButtonItem *)sender
{
    if (self.currentPage > 0)
    {
        self.currentPage -= 1;
        [self loadDocument: self.currentPage];
    }
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self nextPage: nil];
    }
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self prevPage: nil];
    }
}

-(void)dealloc
{
    if ([_webView isKindOfClass: [UIWebView class]])
    {
        [((UIWebView*)_webView) setDelegate: nil];
    }
    else if ([_webView isKindOfClass: [WKWebView class]])
    {
        [((WKWebView*)_webView)setUIDelegate: nil];
    }

    _webView = nil;
}

#pragma mark - WKnavigationDelegate
-(void)webView:(nonnull WKWebView *)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler
{
    decisionHandler(WKNavigationActionPolicyAllow);
}
-(void)webView:(nonnull WKWebView *)webView decidePolicyForNavigationResponse:(nonnull WKNavigationResponse *)navigationResponse decisionHandler:(nonnull void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}
-(void)webView:(nonnull WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    
}
-(void)webView:(nonnull WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    if (error)
    {
//        NSLog(@"[%@ %@] %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd), error);
    }
}
-(void)webView:(nonnull WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    if (error)
    {
//        NSLog(@"[%@ %@] %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd), error);
    }
}
-(void)webView:(nonnull WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    self.navigationItem.title = webView.title;
}
-(void)webView:(nonnull WKWebView *)webView didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    
}
-(void)webView:(nonnull WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    
}
-(void)webView:(nonnull WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    
}
-(void)webViewDidClose:(nonnull WKWebView *)webView
{
    
}
-(void)webViewWebContentProcessDidTerminate:(nonnull WKWebView *)webView
{
    
}

#pragma mark - WKUIDelegate
-(WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame)
    {
        [[UIApplication sharedApplication]openURL: navigationAction.request.URL];
    }
    return nil;
}
-(void)webView:(nonnull WKWebView *)webView runJavaScriptAlertPanelWithMessage:(nonnull NSString *)message initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(void))completionHandler
{
    
}
-(void)webView:(nonnull WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(nonnull NSString *)message initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(BOOL))completionHandler
{
    
}
-(void)webView:(nonnull WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(nonnull NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(NSString * _Nullable))completionHandler
{
    
}

@end
