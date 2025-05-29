// Copyright 2017 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_button_factory.h"

#import "base/ios/ios_util.h"
#import "components/strings/grit/components_strings.h"
#import "ios/chrome/browser/shared/public/features/features.h"
#import "ios/chrome/browser/shared/ui/symbols/symbols.h"
#import "ios/chrome/browser/shared/ui/util/rtl_geometry.h"
#import "ios/chrome/browser/shared/ui/util/uikit_ui_util.h"
#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_button.h"
#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_button_actions_handler.h"
#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_button_visibility_configuration.h"
#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_configuration.h"
#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_tab_grid_button.h"
#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_tab_group_state.h"
#import "ios/chrome/browser/toolbar/ui_bundled/public/toolbar_constants.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/common/ui/util/constraints_ui_util.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ios/chrome/grit/ios_theme_resources.h"
#import "ios/public/provider/chrome/browser/raccoon/raccoon_api.h"
#import "ui/base/l10n/l10n_util.h"

namespace {
const CGFloat kSymbolToolbarPointSize = 24;
const CGFloat kShareIconBalancingHeightPadding = 1;
}  // namespace

@implementation ToolbarButtonFactory

- (instancetype)initWithStyle:(ToolbarStyle)style {
  self = [super init];
  if (self) {
    _style = style;
    _toolbarConfiguration = [[ToolbarConfiguration alloc] initWithStyle:style];
    NSLog(@"ToolbarButtonFactory: Initialized with style=%ld", (long)style);
  }
  return self;
}

#pragma mark - Buttons

- (ToolbarButton*)backButton {
  auto loadImageBlock = ^UIImage* {
    UIImage* image = [UIImage systemImageNamed:kBackSymbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"backButton: systemImageNamed:%@ failed", kBackSymbol);
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    return [image imageFlippedForRightToLeftLayoutDirection];
  };

  ToolbarButton* backButton =
      [[ToolbarButton alloc] initWithImageLoader:loadImageBlock];
  [self configureButton:backButton width:kAdaptiveToolbarButtonWidth];
  backButton.accessibilityLabel = l10n_util::GetNSString(IDS_ACCNAME_BACK);
  backButton.accessibilityHint =
      l10n_util::GetNSString(IDS_IOS_TOOLBAR_ACCESSIBILITY_HINT_BACK);
  [backButton addTarget:self.actionHandler
                 action:@selector(backAction)
       forControlEvents:UIControlEventTouchUpInside];
  backButton.visibilityMask = self.visibilityConfiguration.backButtonVisibility;
  NSLog(@"ToolbarButtonFactory: Created backButton=%@, caller=%@",
        backButton, [[NSThread callStackSymbols] objectAtIndex:1]);
  return backButton;
}

- (ToolbarButton*)forwardButton {
  auto loadImageBlock = ^UIImage* {
    UIImage* image = [UIImage systemImageNamed:kForwardSymbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"forwardButton: systemImageNamed:%@ failed", kForwardSymbol);
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    return [image imageFlippedForRightToLeftLayoutDirection];
  };

  ToolbarButton* forwardButton =
      [[ToolbarButton alloc] initWithImageLoader:loadImageBlock];
  [self configureButton:forwardButton width:kAdaptiveToolbarButtonWidth];
  forwardButton.visibilityMask =
      self.visibilityConfiguration.forwardButtonVisibility;
  forwardButton.accessibilityLabel =
      l10n_util::GetNSString(IDS_ACCNAME_FORWARD);
  forwardButton.accessibilityHint =
      l10n_util::GetNSString(IDS_IOS_TOOLBAR_ACCESSIBILITY_HINT_FORWARD);
  [forwardButton addTarget:self.actionHandler
                    action:@selector(forwardAction)
          forControlEvents:UIControlEventTouchUpInside];
  NSLog(@"ToolbarButtonFactory: Created forwardButton=%@, caller=%@",
        forwardButton, [[NSThread callStackSymbols] objectAtIndex:1]);
  return forwardButton;
}

- (ToolbarTabGridButton*)tabGridButton {
  auto imageBlock = ^UIImage*(ToolbarTabGroupState tabGroupState) {
    NSString* symbol = (tabGroupState == ToolbarTabGroupState::kNormal)
                           ? kSquareNumberSymbol
                           : kSquareFilledOnSquareSymbol;
    UIImage* image = [UIImage systemImageNamed:symbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"tabGridButton: systemImageNamed:%@ failed for state=%ld", symbol, (long)tabGroupState);
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    return image;
  };

  ToolbarTabGridButton* tabGridButton = [[ToolbarTabGridButton alloc]
      initWithTabGroupStateImageLoader:imageBlock];
  tabGridButton.accessibilityHint =
      l10n_util::GetNSString(IDS_IOS_TOOLBAR_ACCESSIBILITY_HINT_TAB_GRID);
  [self configureButton:tabGridButton width:kAdaptiveToolbarButtonWidth];
  [tabGridButton addTarget:self.actionHandler
                    action:@selector(tabGridTouchDown)
          forControlEvents:UIControlEventTouchDown];
  [tabGridButton addTarget:self.actionHandler
                    action:@selector(tabGridTouchUp)
          forControlEvents:UIControlEventTouchUpInside];
  tabGridButton.visibilityMask =
      self.visibilityConfiguration.tabGridButtonVisibility;
  NSLog(@"ToolbarButtonFactory: Created tabGridButton=%@, caller=%@",
        tabGridButton, [[NSThread callStackSymbols] objectAtIndex:1]);
  return tabGridButton;
}

- (ToolbarButton*)toolsMenuButton {
  auto loadImageBlock = ^UIImage* {
    UIImage* image = [UIImage systemImageNamed:kMenuSymbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"toolsMenuButton: systemImageNamed:%@ failed", kMenuSymbol);
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    return image;
  };

  auto loadIPHHighlightedImageBlock = ^UIImage* {
    UIImage* image = [UIImage systemImageNamed:kEllipsisSquareFillSymbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"toolsMenuButton: systemImageNamed:%@ failed for IPH", kEllipsisSquareFillSymbol);
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  };

  ToolbarButton* toolsMenuButton =
      [[ToolbarButton alloc] initWithImageLoader:loadImageBlock
                       IPHHighlightedImageLoader:loadIPHHighlightedImageBlock];
  SetA11yLabelAndUiAutomationName(toolsMenuButton, IDS_IOS_TOOLBAR_SETTINGS,
                                  kToolbarToolsMenuButtonIdentifier);
  [self configureButton:toolsMenuButton width:kAdaptiveToolbarButtonWidth];
  [toolsMenuButton.heightAnchor
      constraintEqualToConstant:kAdaptiveToolbarButtonWidth]
      .active = YES;
  [toolsMenuButton addTarget:self.actionHandler
                      action:@selector(toolsMenuAction)
            forControlEvents:UIControlEventTouchUpInside];
  toolsMenuButton.visibilityMask =
      self.visibilityConfiguration.toolsMenuButtonVisibility;
  NSLog(@"ToolbarButtonFactory: Created toolsMenuButton=%@, caller=%@",
        toolsMenuButton, [[NSThread callStackSymbols] objectAtIndex:1]);
  return toolsMenuButton;
}

- (ToolbarButton*)shareButton {
  auto loadImageBlock = ^UIImage* {
    UIImage* image = [UIImage systemImageNamed:kShareSymbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"shareButton: systemImageNamed:%@ failed", kShareSymbol);
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    UIGraphicsBeginImageContextWithOptions(
        CGSizeMake(image.size.width,
                   image.size.height + kShareIconBalancingHeightPadding),
        NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
  };

  ToolbarButton* shareButton =
      [[ToolbarButton alloc] initWithImageLoader:loadImageBlock];
  [self configureButton:shareButton width:kAdaptiveToolbarButtonWidth];
  SetA11yLabelAndUiAutomationName(shareButton, IDS_IOS_TOOLS_MENU_SHARE,
                                  kToolbarShareButtonIdentifier);
  shareButton.titleLabel.text = @"Share";
  [shareButton addTarget:self.actionHandler
                  action:@selector(shareAction)
        forControlEvents:UIControlEventTouchUpInside];
  shareButton.visibilityMask =
      self.visibilityConfiguration.shareButtonVisibility;
  NSLog(@"ToolbarButtonFactory: Created shareButton=%@, caller=%@",
        shareButton, [[NSThread callStackSymbols] objectAtIndex:1]);
  return shareButton;
}

- (ToolbarButton*)reloadButton {
  auto loadImageBlock = ^UIImage* {
    UIImage* image = [UIImage systemImageNamed:kArrowClockWiseSymbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"reloadButton: systemImageNamed:%@ failed", kArrowClockWiseSymbol);
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    return image;
  };

  ToolbarButton* reloadButton =
      [[ToolbarButton alloc] initWithImageLoader:loadImageBlock];
  [self configureButton:reloadButton width:kAdaptiveToolbarButtonWidth];
  reloadButton.accessibilityLabel =
      l10n_util::GetNSString(IDS_IOS_ACCNAME_RELOAD);
  [reloadButton addTarget:self.actionHandler
                   action:@selector(reloadAction)
         forControlEvents:UIControlEventTouchUpInside];
  reloadButton.visibilityMask =
      self.visibilityConfiguration.reloadButtonVisibility;
  NSLog(@"ToolbarButtonFactory: Created reloadButton=%@, caller=%@",
        reloadButton, [[NSThread callStackSymbols] objectAtIndex:1]);
  return reloadButton;
}

- (ToolbarButton*)stopButton {
  auto loadImageBlock = ^UIImage* {
    UIImage* image = [UIImage systemImageNamed:kXMarkSymbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"stopButton: systemImageNamed:%@ failed", kXMarkSymbol);
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    return image;
  };

  ToolbarButton* stopButton =
      [[ToolbarButton alloc] initWithImageLoader:loadImageBlock];
  [self configureButton:stopButton width:kAdaptiveToolbarButtonWidth];
  stopButton.accessibilityLabel = l10n_util::GetNSString(IDS_IOS_ACCNAME_STOP);
  [stopButton addTarget:self.actionHandler
                 action:@selector(stopAction)
       forControlEvents:UIControlEventTouchUpInside];
  stopButton.visibilityMask = self.visibilityConfiguration.stopButtonVisibility;
  NSLog(@"ToolbarButtonFactory: Created stopButton=%@, caller=%@",
        stopButton, [[NSThread callStackSymbols] objectAtIndex:1]);
  return stopButton;
}

- (ToolbarButton*)openNewTabButton {
  UIColor* buttonTintColor = [UIColor colorNamed:@"toolbar_button_color"];
  NSLog(@"openNewTabButton: Using buttonTintColor=%@", buttonTintColor);

  auto loadImageBlock = ^UIImage* {
    UIImage* image = [UIImage systemImageNamed:kPlusCircleFillSymbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"openNewTabButton: systemImageNamed:%@ failed, trying kPlusSymbol", kPlusCircleFillSymbol);
      image = [UIImage systemImageNamed:kPlusSymbol
                    withConfiguration:[UIImageSymbolConfiguration
                                          configurationWithPointSize:kSymbolToolbarPointSize]];
    }
    if (!image) {
      NSLog(@"openNewTabButton: FATAL: All image attempts failed");
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    NSLog(@"openNewTabButton: loadImageBlock image=%@, size=%@", image, NSStringFromCGSize(image.size));
    return image;
  };

  auto loadIPHHighlightedImageBlock = ^UIImage* {
    UIImage* image = [UIImage systemImageNamed:kPlusCircleFillSymbol
                          withConfiguration:[UIImageSymbolConfiguration
                                                configurationWithPointSize:kSymbolToolbarPointSize]];
    if (!image) {
      NSLog(@"openNewTabButton: systemImageNamed:%@ failed for IPH, trying kPlusSymbol", kPlusCircleFillSymbol);
      image = [UIImage systemImageNamed:kPlusSymbol
                    withConfiguration:[UIImageSymbolConfiguration
                                          configurationWithPointSize:kSymbolToolbarPointSize]];
    }
    if (!image) {
      NSLog(@"openNewTabButton: FATAL: All IPH image attempts failed");
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    NSLog(@"openNewTabButton: loadIPHHighlightedImageBlock image=%@, size=%@", image, NSStringFromCGSize(image.size));
    return image;
  };

  ToolbarButton* newTabButton =
      [[ToolbarButton alloc] initWithImageLoader:loadImageBlock
                       IPHHighlightedImageLoader:loadIPHHighlightedImageBlock];
  newTabButton.tintColor = buttonTintColor;
  [newTabButton addTarget:self.actionHandler
                   action:@selector(newTabAction:)
         forControlEvents:UIControlEventTouchUpInside];
  [self configureButton:newTabButton width:kAdaptiveToolbarButtonWidth];
  newTabButton.accessibilityLabel = [self.toolbarConfiguration
      accessibilityLabelForOpenNewTabButtonInGroup:NO];
  newTabButton.accessibilityIdentifier = kToolbarNewTabButtonIdentifier;
  newTabButton.accessibilityHint =
      l10n_util::GetNSString(IDS_IOS_TOOLBAR_ACCESSIBILITY_HINT_NEW_TAB);
  newTabButton.visibilityMask =
      self.visibilityConfiguration.newTabButtonVisibility;
  newTabButton.tintColor = buttonTintColor;
  NSLog(@"openNewTabButton: Created button=%@, tintColor=%@, image=%@, caller=%@",
        newTabButton, newTabButton.tintColor, newTabButton.imageView.image,
        [[NSThread callStackSymbols] objectAtIndex:1]);
  return newTabButton;
}

- (UIButton*)cancelButton {
  UIButton* cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
  cancelButton.tintColor = [UIColor colorNamed:@"toolbar_button_color"];
  [cancelButton setContentHuggingPriority:UILayoutPriorityRequired
                                  forAxis:UILayoutConstraintAxisHorizontal];
  [cancelButton
      setContentCompressionResistancePriority:UILayoutPriorityRequired
                                      forAxis:UILayoutConstraintAxisHorizontal];
  UIButtonConfiguration* buttonConfiguration =
      [UIButtonConfiguration plainButtonConfiguration];
  buttonConfiguration.contentInsets = NSDirectionalEdgeInsetsMake(
      0, kCancelButtonHorizontalInset, 0, kCancelButtonHorizontalInset);
  UIFont* font = [UIFont fontWithName:@"WFVisualSans-RegularText" size:kLocationBarFontSize];
  NSDictionary* attributes = @{NSFontAttributeName : font};
  NSMutableAttributedString* attributedString =
      [[NSMutableAttributedString alloc]
          initWithString:l10n_util::GetNSString(IDS_CANCEL)
              attributes:attributes];
  buttonConfiguration.attributedTitle = attributedString;
  cancelButton.configuration = buttonConfiguration;
  cancelButton.hidden = YES;
  [cancelButton addTarget:self.actionHandler
                   action:@selector(cancelOmniboxFocusAction)
         forControlEvents:UIControlEventTouchUpInside];
  cancelButton.accessibilityIdentifier =
      kToolbarCancelOmniboxEditButtonIdentifier;
  NSLog(@"ToolbarButtonFactory: Created cancelButton=%@, caller=%@",
        cancelButton, [[NSThread callStackSymbols] objectAtIndex:1]);
  return cancelButton;
}

#pragma mark - Helpers

- (void)configureButton:(ToolbarButton*)button width:(CGFloat)width {
  NSLayoutConstraint* constraint =
      [button.widthAnchor constraintEqualToConstant:width];
  constraint.priority = UILayoutPriorityRequired - 1;
  constraint.active = YES;
  button.toolbarConfiguration = self.toolbarConfiguration;
  button.exclusiveTouch = YES;
  button.pointerInteractionEnabled = YES;
  if (ios::provider::IsRaccoonEnabled()) {
    if (@available(iOS 17.0, *)) {
      button.hoverStyle = [UIHoverStyle
          styleWithShape:[UIShape rectShapeWithCornerRadius:width / 4]];
    }
  }
  button.pointerStyleProvider =
      ^UIPointerStyle*(UIButton* uiButton, UIPointerEffect* proposedEffect,
                       UIPointerShape* proposedShape) {
        CGRect rect = CGRectInset(uiButton.frame, 1, 1);
        UIPointerShape* shape = [UIPointerShape shapeWithRoundedRect:rect];
        return [UIPointerStyle styleWithEffect:proposedEffect shape:shape];
      };
  NSLog(@"ToolbarButtonFactory: Configured button=%@, width=%f, caller=%@",
        button, width, [[NSThread callStackSymbols] objectAtIndex:1]);
}

@end