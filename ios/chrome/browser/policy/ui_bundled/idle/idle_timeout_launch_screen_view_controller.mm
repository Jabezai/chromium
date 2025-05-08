// Copyright 2024 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/policy/ui_bundled/idle/idle_timeout_launch_screen_view_controller.h"

#import "ios/chrome/browser/policy/ui_bundled/idle/constants.h"

@interface IdleTimeoutLaunchScreenViewController ()

// Text displayed during the loading.
@property(nonatomic, strong) UILabel* loadingLabel;

@end

@implementation IdleTimeoutLaunchScreenViewController

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self beginAppearanceTransition:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self endAppearanceTransition];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self beginAppearanceTransition:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self endAppearanceTransition];
}

- (void)viewDidLoad {
    self.detailView = [self createSpinnerView];
    [super viewDidLoad];
    // Override the accessibility ID defined in LaunchScreenViewController.
    self.view.accessibilityIdentifier =
        kIdleTimeoutLaunchScreenAccessibilityIdentifier;
}

#pragma mark - Private

// Creates the activity indicator view and starts its animation.
- (UIView*)createSpinnerView {
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] init];
    [spinner startAnimating];
    return spinner;
}

@end