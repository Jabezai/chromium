// Copyright 2020 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_button.h"

#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_configuration.h"
#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_style.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/common/ui/util/constraints_ui_util.h"

@interface ToolbarButton ()

@property(nonatomic, strong) UIImage* image;
@property(nonatomic, copy) ToolbarButtonImageLoader imageLoader;
@property(nonatomic, copy) ToolbarButtonImageLoader iphHighlightedImageLoader;

@end

@implementation ToolbarButton {
  ToolbarStyle _style;
  BOOL _alwaysHiddenInCurrentSizeClass;
}

@synthesize toolbarConfiguration = _toolbarConfiguration;
@synthesize visibilityMask = _visibilityMask;
@synthesize hiddenInCurrentSizeClass = _hiddenInCurrentSizeClass;
@synthesize hiddenInCurrentState = _hiddenInCurrentState;
@synthesize guideName = _guideName;
@synthesize layoutGuideCenter = _layoutGuideCenter;
@synthesize iphHighlighted = _iphHighlighted;
@synthesize spotlightView = _spotlightView;
@synthesize hasBlueDot = _hasBlueDot;

+ (instancetype)toolbarButtonWithImageLoader:(ToolbarButtonImageLoader)imageLoader {
  return [[self alloc] initWithImageLoader:imageLoader];
}

- (instancetype)initWithImageLoader:(ToolbarButtonImageLoader)imageLoader {
  return [self initWithImageLoader:imageLoader IPHHighlightedImageLoader:nil];
}

- (instancetype)initWithImageLoader:(ToolbarButtonImageLoader)imageLoader
          IPHHighlightedImageLoader:(ToolbarButtonImageLoader)iphHighlightedImageLoader {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    _imageLoader = [imageLoader copy];
    _iphHighlightedImageLoader = [iphHighlightedImageLoader copy];
    self.accessibilityLabel = @"Toolbar Button";
    _style = ToolbarStyle::kNormal;

    // Load image and ensure it's not nil
    if (imageLoader) {
      self.image = imageLoader();
      if (!self.image) {
        NSLog(@"ToolbarButton: Image loader returned nil, using fallback");
        self.image = [ToolbarButton fallbackImage];
      }
    } else {
      NSLog(@"ToolbarButton: No image loader provided, using fallback");
      self.image = [ToolbarButton fallbackImage];
    }

    [self setImage:self.image forState:UIControlStateNormal];
    self.tintColor = [UIColor colorNamed:kToolbarButtonColor];
    NSLog(@"ToolbarButton: Initialized button=%@ with image=%@, tintColor=%@, caller=%@",
          self, self.image, self.tintColor, [[NSThread callStackSymbols] objectAtIndex:1]);
  }
  return self;
}

+ (UIImage*)fallbackImage {
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
  UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (void)dealloc {
  _imageLoader = nil;
  _iphHighlightedImageLoader = nil;
}

#pragma mark - Public

- (void)updateHiddenInCurrentSizeClass {
  BOOL shouldBeHidden = _alwaysHiddenInCurrentSizeClass ||
                       [self isHiddenInCurrentSizeClassForTraitCollection:self.traitCollection];
  if (self.hidden != shouldBeHidden) {
    self.hidden = shouldBeHidden;
    NSLog(@"ToolbarButton: Updated hiddenInCurrentSizeClass=%d for button=%@", shouldBeHidden, self);
  }
}

- (void)setHiddenInCurrentSizeClass:(BOOL)hiddenInCurrentSizeClass {
  _hiddenInCurrentSizeClass = hiddenInCurrentSizeClass;
  [self updateHiddenInCurrentSizeClass];
}

- (void)updateStyle:(ToolbarStyle)style {
  _style = style;
  [self setNeedsUpdateConfiguration];
}

- (void)setImageLoader:(ToolbarButtonImageLoader)imageLoader {
  _imageLoader = [imageLoader copy];
  if (_imageLoader) {
    UIImage* newImage = _imageLoader();
    if (newImage) {
      self.image = newImage;
      [self setImage:self.image forState:UIControlStateNormal];
    } else {
      NSLog(@"ToolbarButton: New image loader returned nil, using fallback");
      self.image = [ToolbarButton fallbackImage];
      [self setImage:self.image forState:UIControlStateNormal];
    }
  } else {
    NSLog(@"ToolbarButton: New image loader is nil, using fallback");
    self.image = [ToolbarButton fallbackImage];
    [self setImage:self.image forState:UIControlStateNormal];
  }
  NSLog(@"ToolbarButton: Set imageLoader, new image=%@ for button=%@", self.image, self);
}

- (void)setIphHighlighted:(BOOL)iphHighlighted {
  _iphHighlighted = iphHighlighted;
  if (iphHighlighted && _iphHighlightedImageLoader) {
    UIImage* highlightedImage = _iphHighlightedImageLoader();
    if (highlightedImage) {
      [self setImage:highlightedImage forState:UIControlStateNormal];
    }
    NSLog(@"ToolbarButton: Set iphHighlighted=%d, image=%@ for button=%@", iphHighlighted, highlightedImage, self);
  } else {
    [self setImage:self.image forState:UIControlStateNormal];
    NSLog(@"ToolbarButton: Set iphHighlighted=%d, reverted to image=%@ for button=%@", iphHighlighted, self.image, self);
  }
}

#pragma mark - UIButton

- (void)updateConfiguration {
  self.configuration = [self buttonConfiguration];
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement {
  return YES;
}

#pragma mark - Private

- (UIButtonConfiguration*)buttonConfiguration {
  UIButtonConfiguration* configuration = [UIButtonConfiguration plainButtonConfiguration];
  configuration.image = self.image;
  configuration.imagePadding = 8;
  configuration.baseForegroundColor = [self foregroundColor];
  configuration.contentInsets = NSDirectionalEdgeInsetsMake(8, 8, 8, 8);
  return configuration;
}

- (UIColor*)foregroundColor {
  if (self.toolbarConfiguration) {
    return self.toolbarConfiguration.buttonsTintColor;
  }
  switch (_style) {
    case ToolbarStyle::kNormal:
      return [UIColor colorNamed:kToolbarButtonColor];
    case ToolbarStyle::kIncognito:
      // Fallback since kToolbarButtonColorIncognito is undefined
      return [UIColor colorNamed:kToolbarButtonColor] ?: [UIColor whiteColor];
  }
}

- (BOOL)isHiddenInCurrentSizeClassForTraitCollection:(UITraitCollection*)traitCollection {
  return NO;
}

@end