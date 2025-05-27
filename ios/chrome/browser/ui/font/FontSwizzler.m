// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/font/FontSwizzler.h"
#import "FontSwizzler+Swizzled.h"
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation FontSwizzler

+ (void)initializeFontSwizzling {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *fontURL = [bundle URLForResource:@"MyCustomFont" withExtension:@"ttf"];
    NSLog(@"Font URL: %@", fontURL);
    
    if (!fontURL || ![[NSFileManager defaultManager] fileExistsAtPath:fontURL.path]) {
      NSLog(@"Error: MyCustomFont.ttf not found in bundle");
      return;
    }
    
    NSLog(@"Font file is readable: %d, path: %@", [[NSFileManager defaultManager] isReadableFileAtPath:fontURL.path], fontURL.path);
    
    CFErrorRef error = NULL;
    NSLog(@"Attempting font registration for %@, caller: %@", fontURL.path, [NSThread callStackSymbols]);
    if (!CTFontManagerRegisterFontsForURL((__bridge CFURLRef)fontURL, kCTFontManagerScopeProcess, &error)) {
      NSLog(@"Failed to register font: %@, caller: %@", error, [NSThread callStackSymbols]);
    } else {
      NSLog(@"Successfully registered font: WFVisualSans-RegularText");
    }
    
    NSArray *fontFamilies = [UIFont familyNames];
    for (NSString *family in fontFamilies) {
      NSLog(@"Font family: %@, names: %@", family, [UIFont fontNamesForFamilyName:family]);
    }
    
    [self swizzleUILabel];
    [self swizzleUITextField];
    [self swizzleUITextView];
    [self swizzleUIButton];
    NSLog(@"FontSwizzler: Initialized swizzling for UILabel, UITextField, UITextView, UIButton");
  });
}

+ (void)swizzleUILabel {
  Method original = class_getInstanceMethod([UILabel class], @selector(setFont:));
  Method swizzled = class_getInstanceMethod([UILabel class], @selector(wf_setFont:));
  method_exchangeImplementations(original, swizzled);
}

+ (void)swizzleUITextField {
  Method original = class_getInstanceMethod([UITextField class], @selector(setFont:));
  Method swizzled = class_getInstanceMethod([UITextField class], @selector(wf_setFont:));
  method_exchangeImplementations(original, swizzled);
}

+ (void)swizzleUITextView {
  Method original = class_getInstanceMethod([UITextView class], @selector(setFont:));
  Method swizzled = class_getInstanceMethod([UITextView class], @selector(wf_setFont:));
  method_exchangeImplementations(original, swizzled);
}

+ (void)swizzleUIButton {
  Method original = class_getInstanceMethod([UIButton class], @selector(setFont:));
  Method swizzled = class_getInstanceMethod([UIButton class], @selector(wf_setFont:));
  method_exchangeImplementations(original, swizzled);
}

@end