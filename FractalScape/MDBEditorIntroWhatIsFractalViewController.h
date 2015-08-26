//
//  MDBEditorIntroWhatIsFractalViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/17/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;
@import WebKit;

@protocol WebViewProtocol <NSObject>

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

@end

@interface MDBEditorIntroWhatIsFractalViewController : UIViewController <UIWebViewDelegate,WKUIDelegate, WKNavigationDelegate>

@property (nonatomic,strong)  UIView<WebViewProtocol>   *webView;
@property (strong, nonatomic) IBOutlet UIView           *webContainer;
@property (strong, nonatomic) IBInspectable NSString    *documentName;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextPageButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *prevPageButton;

@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      pushTransition;
@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      popTransition;

- (IBAction)nextPage:(UIBarButtonItem *)sender;
- (IBAction)prevPage:(UIBarButtonItem *)sender;
- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender;
- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender;
@end
