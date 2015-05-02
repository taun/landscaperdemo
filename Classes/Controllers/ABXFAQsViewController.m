//
//  ABXFAQsViewController.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXFAQsViewController.h"

#import "ABXFaq.h"
#import "ABXFAQViewController.h"
#import "ABXFeedbackViewController.h"
#import "ABXFAQTableViewCell.h"
#import "ABXNavigationController.h"
#import "NSString+ABXLocalized.h"


@interface ABXFAQsViewController ()<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSArray *faqs;
@property (nonatomic, strong) NSArray *filteredFaqs;

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation ABXFAQsViewController

+ (void)showFromController:(UIViewController*)controller hideContactButton:(BOOL)hideContactButton contactMetaData:(NSDictionary*)contactMetaData initialSearch:(NSString*)initialSearch
{
    ABXFAQsViewController *viewController = [[self alloc] init];
    viewController.hideContactButton = hideContactButton;
    viewController.contactMetaData = contactMetaData;
    viewController.initialSearch = initialSearch;
    UINavigationController *nav = [[ABXNavigationController alloc] initWithRootViewController:viewController];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Show as a sheet on iPad
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [controller presentViewController:nav animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Title
    self.title = [@"FAQs" localizedString];
    
    // Setup our UI components
    [self setupFaqUI];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Fetch
    if (![ABXApiClient isInternetReachable]) {
        [self.activityView stopAnimating];
        [self showError:[@"No Internet" localizedString]];
    }
    else {
        if (self.errorLabel) {
            [self.errorLabel removeFromSuperview];
        }
        [self fetchFAQs];
    }

    // Show the keyboard again if it was before
    if (self.searchBar.text.length > 0) {
        [self.searchBar becomeFirstResponder];
        [self searchBar:self.searchBar textDidChange:self.searchBar.text];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (void)setupFaqUI
{
    // Search bar
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
    self.searchBar.delegate = self;
    self.searchBar.text = self.initialSearch;
    self.searchBar.placeholder = [@"Search..." localizedString];
    self.tableView.tableHeaderView = self.searchBar;
    CGFloat topBarOffset = 64.0;//self.topLayoutGuide.length;
    UIEdgeInsets edgeInset = self.tableView.contentInset;
    UIEdgeInsets newInsets = UIEdgeInsetsMake(topBarOffset, edgeInset.left, edgeInset.bottom, edgeInset.right);
    self.tableView.contentInset = newInsets;
    self.tableView.contentOffset = CGPointMake(0.0, -20.0);
    self.navigationItem.leftBarButtonItem = nil;
    
    // Nav buttons
    if (!self.hideContactButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithTitle:[@"Contact" localizedString]
                                                  style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(onContact)];
    }
}

#pragma mark - Fetching

- (void)fetchFAQs
{
    self.tableView.hidden = YES;
    [self.activityView startAnimating];
    [ABXFaq fetch:^(NSArray *faqs, ABXResponseCode responseCode, NSInteger httpCode, NSError *error) {
        [self.activityView stopAnimating];
        if (responseCode == ABXResponseCodeSuccess) {
            self.faqs = faqs;
            
            if (faqs.count == 0) {
                [self showError:[@"No FAQs" localizedString]];
            }
            else {
                [self applySearch:self.searchBar.text];
                self.tableView.hidden = NO;
            }
        }
        else {
            [self showError:[@"FAQ Error" localizedString]];
        }
    }];
}

#pragma mark - Buttons

- (void)onContact
{
    [ABXFeedbackViewController showFromController:self
                                      placeholder:[@"How can we help?" localizedString]
                                            email:nil
                                         metaData:self.contactMetaData
                                            image:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredFaqs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FAQCell";
    
    ABXFAQTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[ABXFAQTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row < self.filteredFaqs.count) {
        [cell setFAQ:[self.filteredFaqs objectAtIndex:indexPath.row]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.filteredFaqs.count) {
        return [ABXFAQTableViewCell heightForFAQ:[self.filteredFaqs objectAtIndex:indexPath.row]
                                       withWidth:CGRectGetWidth(self.tableView.bounds)];
    }
    
    return 0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.filteredFaqs.count) {
        // Fix weird keyboard transition lag in iOS 7
        if ([self.searchBar isFirstResponder]) {
            [self.searchBar resignFirstResponder];
        }
        
        // Show the details
        [ABXFAQViewController pushOnNavController:self.navigationController
                                              faq:self.filteredFaqs[indexPath.row]
                                hideContactButton:self.hideContactButton];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)applySearch:(NSString*)searchText
{
    if (self.faqs.count > 0) {
        if (searchText.length > 0) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.question contains[cd] %@ OR SELF.answer contains[cd] %@", searchText, searchText];
            self.filteredFaqs = [self.faqs filteredArrayUsingPredicate:predicate];
            
            if (self.filteredFaqs.count > 0) {
                self.errorLabel.hidden = YES;
            }
            else {
                [self showError:[@"No matches found" localizedString]];
            }
        }
        else {
            self.filteredFaqs = self.faqs;
        }
        [self.tableView reloadData];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self applySearch:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    searchBar.text = @"";
    
    self.errorLabel.hidden = YES;
    self.filteredFaqs = self.faqs;
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

@end
