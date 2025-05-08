// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/url_input/url_input_view_controller.h"

#import "ios/chrome/browser/omnibox/ui_bundled/omnibox_text_field_ios.h"
#import "ios/chrome/browser/ui/url_input/slide_transition_animator.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"

@interface URLInputViewController () <UIViewControllerTransitioningDelegate>
@property(nonatomic, strong) OmniboxTextFieldIOS* urlField; // Store URL field for notification
@property(nonatomic, strong) UITapGestureRecognizer* primaryTap; // Store for cleanup
@property(nonatomic, strong) UITapGestureRecognizer* secondaryTap; // Store for cleanup
@property(nonatomic, strong) UITapGestureRecognizer* urlTap; // Tap to force focus
@end

@implementation URLInputViewController

@synthesize delegate = _delegate;
@synthesize urlField = _urlField;
@synthesize primaryTap = _primaryTap;
@synthesize secondaryTap = _secondaryTap;
@synthesize urlTap = _urlTap;

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorNamed:kBackgroundColor];

  // Add primary toolbar (top status bar) as a child view controller
  UIViewController* primaryToolbarVC = self.toolbarCoordinator.primaryToolbarViewController;
  [self addChildViewController:primaryToolbarVC];
  UIView* primaryToolbar = primaryToolbarVC.view;
  primaryToolbar.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:primaryToolbar];
  [primaryToolbarVC didMoveToParentViewController:self];

  // Add secondary toolbar (bottom bar) as a child view controller
  UIViewController* secondaryToolbarVC = self.toolbarCoordinator.secondaryToolbarViewController;
  [self addChildViewController:secondaryToolbarVC];
  UIView* secondaryToolbar = secondaryToolbarVC.view;
  secondaryToolbar.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:secondaryToolbar];
  [secondaryToolbarVC didMoveToParentViewController:self];

  // Add tap gesture recognizers to dismiss on interaction
  self.primaryTap = [[UITapGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(dismissMenu:)];
  self.primaryTap.delegate = self;
  self.primaryTap.cancelsTouchesInView = NO; // Allow toolbar actions
  [primaryToolbar addGestureRecognizer:self.primaryTap];

  self.secondaryTap = [[UITapGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(dismissMenu:)];
  self.secondaryTap.delegate = self;
  self.secondaryTap.cancelsTouchesInView = NO; // Allow toolbar actions
  [secondaryToolbar addGestureRecognizer:self.secondaryTap];

  // Configure the URL input field
  self.urlField = (OmniboxTextFieldIOS*)[self findURLTextFieldInView:primaryToolbar];
  if (self.urlField) {
    self.urlField.userInteractionEnabled = YES;
    self.urlField.enabled = YES;
    self.urlField.returnKeyType = UIReturnKeyGo;
    // Exit pre-edit state to prevent clearsOnInsertion
    [self.urlField exitPreEditState];
    // Add control event to verify focus
    [self.urlField addTarget:self
                      action:@selector(handleEditingDidBegin:)
            forControlEvents:UIControlEventEditingDidBegin];
    // Add tap gesture to force focus
    self.urlTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(focusURLField:)];
    self.urlTap.delegate = self;
    [self.urlField addGestureRecognizer:self.urlTap];
    NSLog(@"URL input field configured: %@, editable: %d, can become first responder: %d, delegate: %@, preEditing: %d", self.urlField, self.urlField.isEnabled, [self.urlField canBecomeFirstResponder], self.urlField.delegate, self.urlField.isPreEditing);
    [self.urlField becomeFirstResponder]; // Ensure field is focused
    NSLog(@"URL field first responder after focus: %d", [self.urlField isFirstResponder]);
    // Add notification observer for text field editing end
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(handleKeyboardReturn:)
                                                name:UITextFieldTextDidEndEditingNotification
                                              object:self.urlField];
  } else {
    NSLog(@"Warning: URL input field not found in primary toolbar");
  }

  // Layout constraints
  [NSLayoutConstraint activateConstraints:@[
    [primaryToolbar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
    [primaryToolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [primaryToolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    
    [secondaryToolbar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    [secondaryToolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [secondaryToolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
  ]];

  // Use custom presentation with slide animation
  self.modalPresentationStyle = UIModalPresentationCustom;
  self.transitioningDelegate = self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  // Clean up gesture recognizers to prevent interference
  if (self.primaryTap && self.primaryTap.view) {
    [self.primaryTap.view removeGestureRecognizer:self.primaryTap];
    self.primaryTap = nil;
  }
  if (self.secondaryTap && self.secondaryTap.view) {
    [self.secondaryTap.view removeGestureRecognizer:self.secondaryTap];
    self.secondaryTap = nil;
  }
  if (self.urlTap && self.urlTap.view) {
    [self.urlTap.view removeGestureRecognizer:self.urlTap];
    self.urlTap = nil;
  }
  // Resign first responder
  if (self.urlField) {
    [self.urlField resignFirstResponder];
  }
  NSLog(@"URLInputViewController will disappear, cleaned up gesture recognizers and resigned first responder");
}

// Helper to find the URL text field (OmniboxTextFieldIOS) in the toolbar view
- (UITextField*)findURLTextFieldInView:(UIView*)view {
  if ([view isKindOfClass:[OmniboxTextFieldIOS class]]) {
    return (UITextField*)view;
  }
  for (UIView* subview in view.subviews) {
    UITextField* textField = [self findURLTextFieldInView:subview];
    if (textField) {
      return textField;
    }
  }
  return nil;
}

- (void)dismissMenu:(UITapGestureRecognizer*)gesture {
  NSLog(@"Dismissing swipe menu due to tap on view: %@", gesture.view);
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)focusURLField:(UITapGestureRecognizer*)gesture {
  OmniboxTextFieldIOS* textField = (OmniboxTextFieldIOS*)gesture.view;
  [textField exitPreEditState]; // Ensure pre-edit state is exited
  [textField becomeFirstResponder];
  NSLog(@"URL field focused via tap, first responder: %d, preEditing: %d", [textField isFirstResponder], textField.isPreEditing);
}

- (void)handleEditingDidBegin:(UITextField*)textField {
  OmniboxTextFieldIOS* omniboxField = (OmniboxTextFieldIOS*)textField;
  [omniboxField exitPreEditState]; // Ensure pre-edit state is exited
  NSLog(@"URL field editing began, first responder: %d, preEditing: %d", [textField isFirstResponder], omniboxField.isPreEditing);
}

- (void)handleKeyboardReturn:(NSNotification*)notification {
  UITextField* textField = notification.object;
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
      NSLog(@"URL submitted via notification: %@", url);
      [self.delegate urlInputViewController:self didEnterURL:url];
      [self dismissViewControllerAnimated:YES completion:nil];
    } else {
      NSLog(@"Invalid URL: %@", urlString);
    }
  } else {
    NSLog(@"Empty URL input, not submitting");
  }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController*)presented
                                                                presentingController:(UIViewController*)presenting
                                                                    sourceController:(UIViewController*)source {
  SlideTransitionAnimator* animator = [[SlideTransitionAnimator alloc] init];
  animator.presenting = YES;
  return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController*)dismissed {
  SlideTransitionAnimator* animator = [[SlideTransitionAnimator alloc] init];
  animator.presenting = NO;
  return animator;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  NSLog(@"Gesture recognizer: %@, other: %@", gestureRecognizer, otherGestureRecognizer);
  // Prevent simultaneous recognition with text field gestures
  if ([otherGestureRecognizer.view isKindOfClass:[UITextField class]]) {
    return NO;
  }
  return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
  // Prevent dismissal if the tap is on the URL input field, its subviews, or omnibox container
  CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view];
  UIView* hitView = [gestureRecognizer.view hitTest:location withEvent:nil];
  UIView* currentView = hitView;
  while (currentView) {
    NSString* viewClass = NSStringFromClass([currentView class]);
    if ([viewClass isEqualToString:@"OmniboxTextFieldIOS"] ||
        [viewClass isEqualToString:@"LocationBarSteadyView"]) {
      NSLog(@"Tap on omnibox view (%@), not dismissing: %@", viewClass, hitView);
      return NO;
    }
    currentView = currentView.superview;
  }
  NSLog(@"Tap on non-omnibox view, dismissing: %@", hitView);
  return YES;
}

@end