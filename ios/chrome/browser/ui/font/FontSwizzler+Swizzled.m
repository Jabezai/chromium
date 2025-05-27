// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FontSwizzler+Swizzled.h"

@implementation UILabel (Swizzled)
- (void)wf_setFont:(UIFont *)font {
  UIFont *customFont = [UIFont fontWithName:@"WFVisualSans-RegularText" size:font.pointSize];
  if (!customFont) {
    NSLog(@"Failed to create WFVisualSans-RegularText for %@, size: %.1f, using: %@, caller: %@", 
          NSStringFromClass([self class]), font.pointSize, font.fontName, [NSThread callStackSymbols]);
    [self wf_setFont:font];
    return;
  }
  [self wf_setFont:customFont];
  NSLog(@"Applied WFVisualSans-RegularText to %@, size: %.1f", NSStringFromClass([self class]), font.pointSize);
}
@end

@implementation UITextField (Swizzled)
- (void)wf_setFont:(UIFont *)font {
  UIFont *customFont = [UIFont fontWithName:@"WFVisualSans-RegularText" size:font.pointSize];
  if (!customFont) {
    NSLog(@"Failed to create WFVisualSans-RegularText for %@, size: %.1f, using: %@, caller: %@", 
          NSStringFromClass([self class]), font.pointSize, font.fontName, [NSThread callStackSymbols]);
    [self wf_setFont:font];
    return;
  }
  [self wf_setFont:customFont];
  NSLog(@"Applied WFVisualSans-RegularText to %@, size: %.1f", NSStringFromClass([self class]), font.pointSize);
}
@end

@implementation UITextView (Swizzled)
- (void)wf_setFont:(UIFont *)font {
  UIFont *customFont = [UIFont fontWithName:@"WFVisualSans-RegularText" size:font.pointSize];
  if (!customFont) {
    NSLog(@"Failed to create WFVisualSans-RegularText for %@, size: %.1f, using: %@, caller: %@", 
          NSStringFromClass([self class]), font.pointSize, font.fontName, [NSThread callStackSymbols]);
    [self wf_setFont:font];
    return;
  }
  [self wf_setFont:customFont];
  NSLog(@"Applied WFVisualSans-RegularText to %@, size: %.1f", NSStringFromClass([self class]), font.pointSize);
}
@end

@implementation UIButton (Swizzled)
- (void)wf_setFont:(UIFont *)font {
  UIFont *customFont = [UIFont fontWithName:@"WFVisualSans-RegularText" size:font.pointSize];
  if (!customFont) {
    NSLog(@"Failed to create WFVisualSans-RegularText for %@, size: %.1f, using: %@, caller: %@", 
          NSStringFromClass([self class]), font.pointSize, font.fontName, [NSThread callStackSymbols]);
    [self wf_setFont:font];
    return;
  }
  [self wf_setFont:customFont];
  NSLog(@"Applied WFVisualSans-RegularText to %@, size: %.1f", NSStringFromClass([self class]), font.pointSize);
}
@end