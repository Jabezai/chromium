  // Copyright 2012 The Chromium Authors
  // Use of this source code is governed by a BSD-style license that can be
  // found in the LICENSE file.

  #import <UIKit/UIKit.h>
  #import "ios/chrome/browser/ui/font/FontSwizzler.h"

  extern "C" int ChromeMain(int argc, char* argv[]);

  int main(int argc, char* argv[]) {
    @autoreleasepool {
      // Initialize font swizzling before app launch
      [FontSwizzler initializeFontSwizzling];
      return ChromeMain(argc, argv);
    }
  }