//
//  ABXFeedbackViewController.m
//  Sample Project
//
//  Created by Stuart Hall on 30/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXFeedbackViewController.h"

#import "ABXKeychain.h"
#import "ABXTextView.h"
#import "ABXIssue.h"
#import "NSString+ABXSizing.h"
#import "ABXAttachment.h"
#import "NSString+ABXLocalized.h"

#import <AssetsLibrary/AssetsLibrary.h>

@interface ABXFeedbackViewController ()<UITextViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) ABXTextView *textView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) ABXKeychain *keychain;

@property (nonatomic, strong) UIView *overlayView;

@property (nonatomic, strong) UIView *attachmentsView;
@property (nonatomic, strong) UIButton *attachmentsButton;
@property (nonatomic, strong) UIImageView *attachmentsImageView;
@property (nonatomic, strong) ABXAttachment *attachment;

@property (nonatomic, assign) BOOL sending;

@end

@implementation ABXFeedbackViewController

static NSInteger const kEmailAlert = 0;
static NSInteger const kCloseAlert = 1;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Listen for keyboard events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboard:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Scroll view
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:scrollView];
    
    // Email label
    NSString *promptText = [@"Your Email:" localizedString];
    UIFont *promptFont = [UIFont systemFontOfSize:15];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, [promptText widthToFitFont:promptFont], 50)];
    label.textColor = [UIColor grayColor];
    label.text = promptText;
    label.font = promptFont;
    [scrollView addSubview:label];
    
    // Field for their email
    CGFloat labelWidth = CGRectGetWidth(label.frame);
    CGRect tfRect = CGRectMake(labelWidth + 25, 0, CGRectGetWidth(self.view.frame) - labelWidth - 30, 50);
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] == NSOrderedAscending) {
        tfRect = CGRectMake(labelWidth + 25, 15, CGRectGetWidth(self.view.frame) - labelWidth - 30, 31);
    }
    UITextField *textField = [[UITextField alloc] initWithFrame:tfRect];
    textField.placeholder = [@"Email Placeholder" localizedString];
    textField.font = [UIFont systemFontOfSize:15];
    textField.keyboardType = UIKeyboardTypeEmailAddress;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.returnKeyType = UIReturnKeyNext;
    textField.delegate = self;
    [scrollView addSubview:textField];
    self.textField = textField;
    
    UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(20, 50, CGRectGetWidth(self.view.frame), [UIScreen mainScreen].scale >= 2.0f ? 0.5 : 1)];
    seperator.backgroundColor = [UIColor lightGrayColor];
    seperator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:seperator];
    
    // Text view
    self.textView = [[ABXTextView alloc] initWithFrame:CGRectMake(15, 51, CGRectGetWidth(self.view.frame) - 30, CGRectGetHeight(self.view.frame) - 51)];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textView.font = [UIFont systemFontOfSize:15];
    self.textView.placeholder = self.placeholder ?: [@"How can we help?" localizedString];
    self.textView.delegate = self;
    [scrollView addSubview:self.textView];
    
    // Attachments
    self.attachmentsView = [[UIView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.textView.frame), CGRectGetWidth(self.view.frame) - 30, 22)];
    self.attachmentsView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:self.attachmentsView];
    
    // Attachment button
    self.attachmentsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.attachmentsButton setTitle:[@"attach a file" localizedString] forState:UIControlStateNormal];
    CGFloat width = [[self.attachmentsButton titleForState:UIControlStateNormal] widthToFitFont:self.attachmentsButton.titleLabel.font];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] == NSOrderedAscending) {
        self.attachmentsButton.frame = CGRectMake(CGRectGetWidth(self.attachmentsView.frame) - width - 10, 6, width + 20, 32);
    }
    else {
        self.attachmentsButton.frame = CGRectMake(CGRectGetWidth(self.attachmentsView.frame) - width, 0, width, 22);
    }
    self.attachmentsButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.attachmentsButton addTarget:self action:@selector(onAttachment:) forControlEvents:UIControlEventTouchUpInside];
    [self.attachmentsView addSubview:self.attachmentsButton];
    
    // Preview image
    self.attachmentsImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.attachmentsView.frame) - 22, 0, 22, 22)];
    self.attachmentsImageView.hidden = YES;
    self.attachmentsImageView.clipsToBounds = YES;
    self.attachmentsImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.attachmentsImageView.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
    self.attachmentsImageView.layer.borderWidth = 1;
    self.attachmentsImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.attachmentsView addSubview:self.attachmentsImageView];
    
    // Title
    self.title = [@"Contact" localizedString];
    
    // Buttons
    [self showButtons];
    
    if (self.defaultEmail.length > 0) {
        // An email has been provided
        self.textField.text = self.defaultEmail;
    }
    else {
        // Set the email from the keychain if has been entered before
        self.keychain = [[ABXKeychain alloc] initWithService:@"appbot.co" accessGroup:nil accessibility:ABXKeychainAccessibleWhenUnlocked];
        self.textField.text = self.keychain[@"FeedbackEmail"];
    }
    
    [self openKeyboard];
    
    // Warn if there is no internet connection
    if (![ABXApiClient isInternetReachable]) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[@"No Internet" localizedString]
                                   delegate:nil
                          cancelButtonTitle:[@"OK" localizedString]
                          otherButtonTitles:nil] show];
    }
}

+ (void)showFromController:(UIViewController*)controller
               placeholder:(NSString*)placeholder
                     email:(NSString*)email
                  metaData:(NSDictionary*)metaData
                     image:(UIImage*)image
{
    ABXFeedbackViewController *viewController = [[self alloc] init];
    viewController.placeholder = placeholder;
    viewController.defaultEmail = email;
    viewController.metaData = metaData;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Show as a sheet on iPad
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [controller presentViewController:nav animated:YES completion:nil];
    
    if (image) {
        [viewController view];
        [viewController uploadImage:image];
    }
}

+ (void)showFromController:(UIViewController*)controller placeholder:(NSString*)placeholder
{
    [self showFromController:controller placeholder:placeholder email:nil metaData:nil image:nil];
}

#pragma mark - Keyboard

- (void)openKeyboard
{
    if (self.textField.text.length > 0) {
        // There is an email set, start on the details
        [self.textView becomeFirstResponder];
    }
    else {
        // Start on the email
        [self.textField becomeFirstResponder];
    }
}

- (void)onKeyboard:(NSNotification*)notification
{
    CGRect keyboardWinRect = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    CGFloat topOffset = 0;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        // Determine the status bar size
        CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
        CGRect statusBarWindowRect = [self.view.window convertRect:statusBarFrame fromWindow: nil];
        CGRect statusBarViewRect = [self.view convertRect:statusBarWindowRect fromView: nil];
        
        // Determine the navigation bar size
        CGFloat navbarHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
        
        topOffset = CGRectGetHeight(statusBarViewRect) + navbarHeight;
    }
    
    // Convert it to suit us
    CGRect keyboardRect = [self.textView.superview convertRect:keyboardWinRect fromView:self.view.window];
    
    // Move the textView so the bottom doesn't extend beyound the keyboard
    CGRect tvFrame = self.textView.frame;
    CGRect attachFrame = self.attachmentsView.frame;
    tvFrame.size.height = CGRectGetHeight(self.textView.superview.bounds) - (CGRectGetHeight(keyboardRect) + CGRectGetMinY(tvFrame) + topOffset) - CGRectGetHeight(attachFrame) + 5;
    self.textView.frame = tvFrame;
    
    // Move the seperator
    attachFrame.origin.y = CGRectGetMaxY(tvFrame) - 5;
    self.attachmentsView.frame = attachFrame;
}

- (void)showButtons
{
    if (self.navigationItem.leftBarButtonItem == nil && self.navigationController.viewControllers.count == 1) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(onDone)];
    }
    
    if (self.textView.text.length > 0 && self.navigationItem.rightBarButtonItem == nil) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[@"Send" localizedString]
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(onSend)];
    }
    else if (self.textView.text.length == 0 && self.navigationItem.rightBarButtonItem != nil) {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)onDone
{
    if (self.textView.text.length > 0) {
        // Prompt to ensure they want to close
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[@"Are you sure?" localizedString]
                                                        message:[@"Your message will be lost." localizedString]
                                                       delegate:self
                                              cancelButtonTitle:[@"Cancel" localizedString]
                                              otherButtonTitles:[@"Close" localizedString], nil];
        alert.tag = kCloseAlert;
        [alert show];
    }
    else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)onSend
{
    [self validateAndSend];
}

#pragma mark - Validation

- (BOOL)validateEmail
{
    NSString *regex1 = @"\\A[a-z0-9]+([-._][a-z0-9]+)*@([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,4}\\z";
    NSString *regex2 = @"^(?=.{1,64}@.{4,64}$)(?=.{6,100}$).*";
    NSPredicate *test1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex1];
    NSPredicate *test2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex2];
    return [test1 evaluateWithObject:self.textField.text] && [test2 evaluateWithObject:self.textField.text];
}

- (void)validateAndSend
{
    self.sending = NO;
    
    [self.textView resignFirstResponder];
    [self.textField resignFirstResponder];
    
    if (self.textView.text.length == 0) {
        // Needs a body
        [self.textView becomeFirstResponder];
        [[[UIAlertView alloc] initWithTitle:[@"No Message." localizedString]
                                    message:[@"Please enter a message." localizedString]
                                   delegate:nil
                          cancelButtonTitle:[@"OK" localizedString]
                          otherButtonTitles:nil] show];
        
    }
    else if (self.textField.text.length == 0) {
        // Ensure they want to submit without an email
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[@"No Email." localizedString]
                                    message:[@"Are you sure you want to send without your email? We won't be able reply to you." localizedString]
                                   delegate:self
                          cancelButtonTitle:[@"Cancel" localizedString]
                                               otherButtonTitles:[@"Send" localizedString], nil];
        alert.tag = kEmailAlert;
        [alert show];
    }
    else if (![self validateEmail]) {
        // Invalid email
        [self.textField becomeFirstResponder];
        [[[UIAlertView alloc] initWithTitle:[@"Invalid Email Address." localizedString]
                                    message:[@"Please check your email address, it appears to be invalid." localizedString]
                                   delegate:nil
                          cancelButtonTitle:[@"OK" localizedString]
                          otherButtonTitles:nil] show];
    }
    else {
        // All good!
        [self send];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kEmailAlert: {
            if (buttonIndex == 1) {
                [self send];
            }
            else {
                [self.textField becomeFirstResponder];
            }
        }
            break;
            
        case kCloseAlert: {
            if (buttonIndex == 1) {
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }

}

#pragma mark - Submission

- (void)send
{
    if (self.textField.text.length > 0) {
        // Save the email in the keychain
        self.keychain[@"FeedbackEmail"] = self.textField.text;
    }
    
    if (self.navigationController.viewControllers.count == 1) {
        self.navigationItem.leftBarButtonItem = nil;
    }
    self.navigationItem.rightBarButtonItem = nil;
    
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    overlay.backgroundColor = [UIColor clearColor];
    [self.view addSubview:overlay];
    
    UIView *smoke = [[UIView alloc] initWithFrame:self.view.bounds];
    smoke.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    smoke.backgroundColor = [UIColor blackColor];
    smoke.alpha = 0.5;
    [overlay addSubview:smoke];
    self.overlayView = overlay;
    
    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(overlay.frame), 50)];
    content.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    content.center = smoke.center;
    [overlay addSubview:content];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activity.center = CGPointMake(CGRectGetMidX(content.bounds), CGRectGetMidY(content.bounds) - 10);
    [activity startAnimating];
    [content addSubview:activity];
    
    UILabel *label = [[UILabel alloc] initWithFrame:content.bounds];
    label.center = CGPointMake(CGRectGetMidX(content.bounds), CGRectGetMidY(content.bounds) + 30);
    label.textColor = [UIColor whiteColor];
    label.text = [@"Sending..." localizedString];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:15];
    label.backgroundColor = [UIColor clearColor];
    [content addSubview:label];
    
    // Ensure the attachment has finished, otherwise we need to wait for it
    if (self.attachment == nil || self.attachment.identifier != nil) {
        [self submit];
    }
    else {
        self.sending = YES;
    }
}

- (void)submit
{
    [ABXIssue submit:self.textField.text
            feedback:self.textView.text
         attachments:self.attachment ? @[ self.attachment ] : nil
            metaData:self.metaData
            complete:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error) {
                switch (responseCode) {
                    case ABXResponseCodeSuccess: {
                        [self.navigationController dismissViewControllerAnimated:YES
                                                                      completion:^{
                                                                          [self showConfirm];
                                                                      }];
                    }
                        break;
                        
                    default: {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[@"Error" localizedString]
                                                                        message:[@"There was an error sending your feedback, please try again." localizedString]
                                                                       delegate:nil
                                                              cancelButtonTitle:[@"Cancel" localizedString]
                                                              otherButtonTitles:nil];
                        [alert show];
                        [self showButtons];
                        [self.overlayView removeFromSuperview];
                    }
                        break;
                }
            }];
}

- (void)showConfirm
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[@"Thanks" localizedString]
                                                    message:[@"We have received your feedback and will be in contact soon." localizedString]
                                                   delegate:nil
                                          cancelButtonTitle:[@"OK" localizedString]
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    [self showButtons];
    
    // http://stackoverflow.com/questions/18966675/uitextview-in-ios7-clips-the-last-line-of-text-string
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height - ( textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top );
    if ( overflow > 0 ) {
        // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.textView becomeFirstResponder];
    
    return NO;
}

#pragma mark - Attachments

- (void)onAttachment:(UIButton*)button
{
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.title = nil;
    sheet.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addButtonWithTitle:[@"Take Photo" localizedString]];
    }
    [sheet addButtonWithTitle:[@"Choose Photo" localizedString]];
    [sheet addButtonWithTitle:[@"Use Latest Photo" localizedString]];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:[@"Cancel" localizedString]];
    [sheet showFromRect:button.frame inView:button.superview animated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // Allow for there being no camera
        buttonIndex++;
    }
    
    switch (buttonIndex) {
        case 0: {
            // Camera
            [self showPhotoPicker:UIImagePickerControllerSourceTypeCamera];
        }
            break;
            
        case 1: {
            // Choose
            [self showPhotoPicker:UIImagePickerControllerSourceTypePhotoLibrary];
        }
            break;
            
        case 2: {
            // Latest
            [self getLatestPhoto];
        }
            break;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)showPhotoPicker:(UIImagePickerControllerSourceType)type
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = type;
    imagePicker.allowsEditing = YES;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (image) {
        [self uploadImage:image];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self openKeyboard];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self openKeyboard];
}

- (void)getLatestPhoto
{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        NSInteger numberOfAssets = [group numberOfAssets];
        if (numberOfAssets > 0) {
            NSInteger lastIndex = numberOfAssets - 1;
            [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:lastIndex] options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                ALAssetRepresentation *rep = [result defaultRepresentation];
                UIImage *image = [UIImage imageWithCGImage:[rep fullResolutionImage]];
                if (image && image.size.width > 0) {
                    *stop = YES;
                    
                    [self uploadImage:image];
                }
            }];
            
            *stop = YES;
        }
    } failureBlock:^(NSError *error) {
        [[[UIAlertView alloc] initWithTitle:[@"Can't Access." localizedString]
                                    message:[@"We can't access your photos, please ensure this application has access in Settings." localizedString]
                                   delegate:nil
                          cancelButtonTitle:[@"OK" localizedString]
                          otherButtonTitles:nil] show];
    }];
}

#pragma mark - Images

- (void)uploadImage:(UIImage*)image
{
    self.attachmentsButton.hidden = YES;
    self.attachmentsImageView.image = image;
    self.attachmentsImageView.hidden = NO;
    
    self.attachment = [ABXAttachment new];
    self.attachment.image = image;
    [self.attachment upload:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error) {
        if (self.attachment.identifier == nil) {
            self.attachment = nil;
            [[[UIAlertView alloc] initWithTitle:[@"Error uploading." localizedString]
                                        message:[@"We couldn't upload the photo, please try again." localizedString]
                                       delegate:nil
                              cancelButtonTitle:[@"OK" localizedString]
                              otherButtonTitles:nil] show];
            self.attachmentsButton.hidden = NO;
            [self showButtons];
        }
        else {
            // They already hit the send button
            if (self.sending) {
                [self submit];
            }
        }
    }];
}

@end

