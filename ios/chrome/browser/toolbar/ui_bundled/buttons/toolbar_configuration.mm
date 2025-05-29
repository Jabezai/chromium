// Copyright 2017 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_configuration.h"

#import "ios/chrome/browser/content_suggestions/ui_bundled/ntp_home_constant.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ui/base/l10n/l10n_util.h"

@implementation ToolbarConfiguration

- (instancetype)initWithStyle:(ToolbarStyle)style {
  self = [super init];
  if (self) {
    _style = style;
  }
  return self;
}

- (UIColor*)NTPBackgroundColor {
  return ntp_home::NTPBackgroundColor();
}

- (UIColor*)backgroundColor {
  return [UIColor colorNamed:kBackgroundColor];
}

- (UIColor*)focusedBackgroundColor {
  return [UIColor colorNamed:kGroupedPrimaryBackgroundColor];
}

- (UIColor*)focusedLocationBarBackgroundColor {
  return [UIColor colorNamed:kTextfieldFocusedBackgroundColor];
}

- (UIColor*)buttonsTintColor {
  UIColor* color = [UIColor colorNamed:kToolbarButtonColor];
  if (!color) {
    NSLog(@"ToolbarConfiguration: Failed to load toolbar_button_color from Assets.xcassets, style=%ld", (long)_style);
  }
  NSLog(@"ToolbarConfiguration: buttonsTintColor=%@, style=%ld", color, (long)_style);
  return color ?: [UIColor blackColor]; // Fallback to black if nil
}

- (UIColor*)buttonsTintColorHighlighted {
  UIColor* color = [UIColor colorNamed:kToolbarButtonColor];
  if (!color) {
    NSLog(@"ToolbarConfiguration: Failed to load toolbar_button_color from Assets.xcassets for highlighted, style=%ld", (long)_style);
  }
  NSLog(@"ToolbarConfiguration: buttonsTintColorHighlighted=%@, style=%ld", color, (long)_style);
  return color ?: [UIColor blackColor]; // Fallback to black if nil
}

- (UIColor*)buttonsTintColorIPHHighlighted {
  UIColor* color = [UIColor colorNamed:kToolbarButtonColor];
  if (!color) {
    NSLog(@"ToolbarConfiguration: Failed to load toolbar_button_color from Assets.xcassets for IPH highlighted, style=%ld", (long)_style);
  }
  NSLog(@"ToolbarConfiguration: buttonsTintColorIPHHighlighted=%@, style=%ld", color, (long)_style);
  return color ?: [UIColor blackColor]; // Fallback to black if nil
}

- (UIColor*)buttonsIPHHighlightColor {
  return [UIColor colorNamed:kBlueColor];
}

- (UIColor*)locationBarBackgroundColorWithVisibility:(CGFloat)visibilityFactor {
  switch (self.style) {
    case ToolbarStyle::kNormal:
      return [[UIColor colorNamed:kTextfieldBackgroundColor]
          colorWithAlphaComponent:visibilityFactor];
    case ToolbarStyle::kIncognito:
      return [[UIColor colorNamed:kStaticGrey900Color]
          colorWithAlphaComponent:visibilityFactor];
  }
}

- (NSString*)accessibilityLabelForOpenNewTabButtonInGroup:(BOOL)inGroup {
  switch (self.style) {
    case ToolbarStyle::kNormal:
      return l10n_util::GetNSString(inGroup
                                      ? IDS_IOS_TOOLBAR_OPEN_NEW_TAB_IN_GROUP
                                      : IDS_IOS_TOOLBAR_OPEN_NEW_TAB);
    case ToolbarStyle::kIncognito:
      return l10n_util::GetNSString(
          inGroup ? IDS_IOS_TOOLBAR_OPEN_NEW_TAB_INCOGNITO_IN_GROUP
                  : IDS_IOS_TOOLBAR_OPEN_NEW_TAB_INCOGNITO);
  }
}

- (NSString*)accessibilityLabelForCollapsedPrimaryToolbarButton {
  return l10n_util::GetNSString(IDS_IOS_COLLAPSED_PRIMARY_TOOLBAR_BUTTON);
}

@end