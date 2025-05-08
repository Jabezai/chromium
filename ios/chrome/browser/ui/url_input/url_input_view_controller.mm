// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/url_input/url_input_view_controller.h"

#import "ios/chrome/common/ui/colors/semantic_color_names.h"

@interface URLInputViewController () <UITextFieldDelegate>
@property(nonatomic, strong) UITextField* urlField;
@end

@implementation URLInputViewController

@synthesize delegate = _delegate;
@synthesize urlField = _urlField;

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorNamed:kBackgroundColor];
  
  // Create URL input field
  self.urlField = [[UITextField alloc] init];
  self.urlField.translatesAutoresizingMaskIntoConstraints = NO;
  self.urlField.backgroundColor = [UIColor colorNamed:kTextfieldBackgroundColor];
  self.urlField.textColor = [UIColor colorNamed:kTextPrimaryColor];
  self.urlField.placeholder = @"Enter URL";
  self.urlField.borderStyle = UITextBorderStyleRoundedRect;
  self.urlField.delegate = self;
  self.urlField.returnKeyType = UIReturnKeyGo;
  [self.view addSubview:self.urlField];

  // Create Done button
  UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                           target:self
                           action:@selector(doneButtonTapped:)];
  self.navigationItem.rightBarButtonItem = doneButton;

  // Layout constraints
  [NSLayoutConstraint activateConstraints:@[
    [self.urlField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.urlField.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [self.urlField.widthAnchor constraintEqualToConstant:300],
    [self.urlField.heightAnchor constraintEqualToConstant:40]
  ]];
}

- (void)doneButtonTapped:(UIBarButtonItem*)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
  [textField resignFirstResponder];
  NSString* input = textField.text;
  if (input.length > 0) {
    // Ensure URL has a scheme
    NSString* urlString = input;
    if (![input hasPrefix:@"http://"] && ![input hasPrefix:@"https://"]) {
      urlString = [@"https://" stringByAppendingString:input];
    }
    NSURL* url = [NSURL URLWithString:urlString];
    if (url) {
      [self.delegate urlInputViewController:self didEnterURL:url];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
  return YES;
}

@end