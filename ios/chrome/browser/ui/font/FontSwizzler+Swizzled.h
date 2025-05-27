// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@interface UILabel (Swizzled)
- (void)wf_setFont:(UIFont *)font;
@end

@interface UITextField (Swizzled)
- (void)wf_setFont:(UIFont *)font;
@end

@interface UITextView (Swizzled)
- (void)wf_setFont:(UIFont *)font;
@end

@interface UIButton (Swizzled)
- (void)wf_setFont:(UIFont *)font;
@end