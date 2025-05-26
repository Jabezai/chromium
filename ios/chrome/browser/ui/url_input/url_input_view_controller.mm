// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/url_input/url_input_view_controller.h"
#import "ios/chrome/app/UIViewController+CustomFont.h"
#import "ios/chrome/browser/ui/font/FontManager.h"
#import "ios/chrome/browser/omnibox/ui_bundled/omnibox_text_field_ios.h"
#import "ios/chrome/browser/ui/url_input/slide_transition_animator.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"

@interface URLInputViewController () <UIViewControllerTransitioningDelegate>
@property(nonatomic, strong) OmniboxTextFieldIOS* urlField; // Store URL field for notification
@property(nonatomic, strong) UITapGestureRecognizer* primaryTap; // Store for cleanup
@property(nonatomic, strong) UITapGestureRecognizer* secondaryTap; // Store for cleanup
@property(nonatomic, strong) UITapGestureRecognizer* urlTap; // Tap to force focus
@property(nonatomic, strong) UISwipeGestureRecognizer* swipeRecognizer; // For swipe detection
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
  NSLog(@"URLInputViewController viewDidLoad called");

  // Add primary toolbar (top status bar) as a child view controller
  UIViewController* primaryToolbarVC = self.toolbarCoordinator.primaryToolbarViewController;
  [self addChildViewController:primaryToolbarVC];
  UIView* primaryToolbar = primaryToolbarVC.view;
  primaryToolbar.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:primaryToolbar];
  [primaryToolbarVC didMoveToParentViewController:self];
  NSLog(@"Primary toolbar view controller: %@", NSStringFromClass([primaryToolbarVC class]));

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

  // Add swipe gesture recognizer for debugging
  self.swipeRecognizer = [[UISwipeGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(handleSwipe:)];
  self.swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
  self.swipeRecognizer.delegate = self;
  [self.view addGestureRecognizer:self.swipeRecognizer];
  NSLog(@"Added swipe gesture recognizer to URLInputViewController view");

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
    // Add text change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(textDidChange:)
                                                name:UITextFieldTextDidChangeNotification
                                              object:self.urlField];
    // Add tap gesture to force focus
    self.urlTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(focusURLField:)];
    self.urlTap.delegate = self;
    [self.urlField addGestureRecognizer:self.urlTap];
    // Force WF Visual Sans font
    UIFont *customFont = [[FontManager sharedManager] customFont];
    if (customFont) {
      self.urlField.font = customFont;
      NSLog(@"Forced WF Visual Sans on urlField in viewDidLoad, font: %@", self.urlField.font.fontName);
    }
    NSLog(@"URL input field configured: %@, editable: %d, can become first responder: %d, delegate: %@, preEditing: %d, font: %@", self.urlField, self.urlField.isEnabled, [self.urlField canBecomeFirstResponder], self.urlField.delegate, self.urlField.isPreEditing, self.urlField.font.fontName);
    [self.urlField becomeFirstResponder]; // Ensure field is focused
    NSLog(@"URL field first responder after focus: %d, font: %@", [self.urlField isFirstResponder], self.urlField.font.fontName);
    // Add KVO observer for font changes
    [self.urlField addObserver:self
                    forKeyPath:@"font"
                       options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                       context:nil];
    NSLog(@"Added KVO observer for urlField font");
    // Add KVO for Cancel button label
    for (UIView *subview in primaryToolbar.subviews) {
      if ([subview isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)subview;
        if ([[button titleForState:UIControlStateNormal] isEqualToString:@"Cancel"]) {
          [button.titleLabel addObserver:self
                             forKeyPath:@"font"
                                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                context:nil];
          NSLog(@"Added KVO observer for Cancel button label font");
        }
      }
    }
    // Add notification observer for text field editing end
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(handleKeyboardReturn:)
                                                name:UITextFieldTextDidEndEditingNotification
                                              object:self.urlField];
  } else {
    NSLog(@"Warning: URL input field not found in primary toolbar");
    // Debug: Log primary toolbar view hierarchy
    NSLog(@"Primary toolbar view hierarchy: %@", [self debugViewHierarchy:primaryToolbar]);
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

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // Force WF Visual Sans font again
  if (self.urlField) {
    UIFont *customFont = [[FontManager sharedManager] customFont];
    if (customFont && ![self.urlField.font.fontName isEqualToString:@"WFVisualSans-RegularText"]) {
      self.urlField.font = customFont;
      NSLog(@"Forced WF Visual Sans on urlField in viewDidAppear, font: %@", self.urlField.font.fontName);
    }
  }
  // Trigger font reapplication via swizzled viewDidLoad
  SEL swizzledSelector = NSSelectorFromString(@"swizzled_viewDidLoad");
  if ([self respondsToSelector:swizzledSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:swizzledSelector];
#pragma clang diagnostic pop
    NSLog(@"Reapplied fonts via swizzled_viewDidLoad in viewDidAppear, urlField font: %@", self.urlField.font.fontName);
  }
  NSLog(@"URLInputViewController presented with frame: %@", NSStringFromCGRect(self.view.frame));
  NSLog(@"URLInputViewController view hierarchy: %@", [self debugViewHierarchy:self.view]);
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if (self.urlField) {
    NSLog(@"viewDidLayoutSubviews, urlField font: %@", self.urlField.font.fontName);
  }
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
  if (gesture.state == UIGestureRecognizerStateRecognized) {
    NSLog(@"Right-to-left swipe detected in URLInputViewController, direction: %lu", (unsigned long)gesture.direction);
  }
}

- (void)textDidChange:(NSNotification *)notification {
  UITextField *textField = notification.object;
  // Force WF Visual Sans font on text change
  UIFont *customFont = [[FontManager sharedManager] customFont];
  if (customFont && ![textField.font.fontName isEqualToString:@"WFVisualSans-RegularText"]) {
    textField.font = customFont;
    NSLog(@"Forced WF Visual Sans on urlField in textDidChange, font: %@", textField.font.fontName);
  }
  NSLog(@"textDidChange, urlField text: %@, font: %@", textField.text, textField.font.fontName);
}

// Helper to debug view hierarchy
- (NSString *)debugViewHierarchy:(UIView *)view {
  NSMutableString *hierarchy = [NSMutableString stringWithFormat:@"<%@: %p; frame = %@>", NSStringFromClass([view class]), view, NSStringFromCGRect(view.frame)];
  for (UIView *subview in view.subviews) {
    [hierarchy appendFormat:@"\n  %@", [self debugViewHierarchy:subview]];
  }
  return hierarchy;
}

- (void)dealloc {
  if (self.urlField) {
    [self.urlField removeObserver:self forKeyPath:@"font"];
  }
  // Clean up Cancel button KVO
  UIView *primaryToolbar = self.toolbarCoordinator.primaryToolbarViewController.view;
  for (UIView *subview in primaryToolbar.subviews) {
    if ([subview isKindOfClass:[UIButton class]]) {
      UIButton *button = (UIButton *)subview;
      if ([[button titleForState:UIControlStateNormal] isEqualToString:@"Cancel"]) {
        [button.titleLabel removeObserver:self forKeyPath:@"font"];
      }
    }
  }
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
  if (self.swipeRecognizer && self.swipeRecognizer.view) {
    [self.swipeRecognizer.view removeGestureRecognizer:self.swipeRecognizer];
    self.swipeRecognizer = nil;
  }
  // Resign first responder
  if (self.urlField) {
    [self.urlField resignFirstResponder];
  }
  NSLog(@"URLInputViewController will disappear, cleaned up gesture recognizers and resigned first responder");
}

// Helper to find the URL text field (OmniboxTextFieldIOS) in the toolbar view
- (UITextField*)findURLTextFieldInView:(UIView*)view {
  NSLog(@"Inspecting view: %@, class: %@", view, NSStringFromClass([view class]));
  if ([view isKindOfClass:[OmniboxTextFieldIOS class]]) {
    NSLog(@"Found OmniboxTextFieldIOS: %@", view);
    return (UITextField*)view;
  }
  if ([view isKindOfClass:[UITextField class]]) {
    NSLog(@"Found UITextField (not OmniboxTextFieldIOS): %@", NSStringFromClass([view class]));
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
  UITextField* textField = (UITextField*)gesture.view;
  if ([textField isKindOfClass:[OmniboxTextFieldIOS class]]) {
    [(OmniboxTextFieldIOS*)textField exitPreEditState]; // Ensure pre-edit state is exited
  }
  [textField becomeFirstResponder];
  // Force WF Visual Sans font on focus
  UIFont *customFont = [[FontManager sharedManager] customFont];
  if (customFont && ![textField.font.fontName isEqualToString:@"WFVisualSans-RegularText"]) {
    textField.font = customFont;
    NSLog(@"Forced WF Visual Sans on urlField in focusURLField, font: %@", textField.font.fontName);
  }
  NSLog(@"URL field focused via tap, first responder: %d, font: %@", [textField isFirstResponder], textField.font.fontName);
}

- (void)handleEditingDidBegin:(UITextField*)textField {
  if ([textField isKindOfClass:[OmniboxTextFieldIOS class]]) {
    [(OmniboxTextFieldIOS*)textField exitPreEditState]; // Ensure pre-edit state is exited
  }
  // Force WF Visual Sans font on editing
  UIFont *customFont = [[FontManager sharedManager] customFont];
  if (customFont && ![textField.font.fontName isEqualToString:@"WFVisualSans-RegularText"]) {
    textField.font = customFont;
    NSLog(@"Forced WF Visual Sans on urlField in handleEditingDidBegin, font: %@", textField.font.fontName);
  }
  NSLog(@"URL field editing began, first responder: %d, font: %@", [textField isFirstResponder], textField.font.fontName);
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

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"font"]) {
    UIFont *newFont = change[NSKeyValueChangeNewKey];
    UIFont *oldFont = change[NSKeyValueChangeOldKey];
    if (object == self.urlField) {
      NSLog(@"urlField font changed from %@ to %@", oldFont.fontName, newFont.fontName);
      // Force WF Visual Sans if overridden
      UIFont *customFont = [[FontManager sharedManager] customFont];
      if (customFont && ![newFont.fontName isEqualToString:@"WFVisualSans-RegularText"]) {
        self.urlField.font = customFont;
        NSLog(@"Forced WF Visual Sans on urlField in KVO, font: %@", self.urlField.font.fontName);
      }
    } else {
      NSLog(@"Cancel button label font changed from %@ to %@", oldFont.fontName, newFont.fontName);
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
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
  }
  return YES;
}

@end