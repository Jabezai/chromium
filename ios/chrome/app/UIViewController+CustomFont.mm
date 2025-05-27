// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/app/UIViewController+CustomFont.h"
#import "ios/chrome/browser/ui/font/FontSwizzler.h"
#import <objc/runtime.h>

@implementation UIViewController (CustomFont)

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Swizzle viewDidLoad to ensure font application
    Method originalMethod = class_getInstanceMethod(self, @selector(viewDidLoad));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(wf_viewDidLoad));
    method_exchangeImplementations(originalMethod, swizzledMethod);
  });
}

- (void)wf_viewDidLoad {
  // Call original viewDidLoad
  [self wf_viewDidLoad];

  // Initialize FontSwizzler to ensure global font swizzling
  [FontSwizzler initializeFontSwizzling];
  NSLog(@"Swizzling viewDidLoad for %@, ensuring WFVisualSans-RegularText", NSStringFromClass([self class]));
}

@end