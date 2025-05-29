// Copyright 2016 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/app/startup/setup_debugging.h"

#import <objc/runtime.h>

#import "base/check.h"
#import "base/logging.h"
#import "base/strings/sys_string_conversions.h"
#include "build/build_config.h"
#include "components/crash/core/common/objc_zombie.h"

namespace {

#if !defined(NDEBUG)

// Swizzles [UIImage imageNamed:] to trigger a warning if an invalid image is
// loaded.
void SwizzleUIImageImageNamed() {
  // Retained by the swizzle block.
  // A set of image names that are exceptions to the 'missing image' check.
  NSMutableSet* exceptions = [NSMutableSet set];

  // TODO(crbug.com/41318097): Add missing image.
  [exceptions addObject:@"card_close_button_pressed_incognito"];
  // TODO(crbug.com/41318110): Add missing image.
  [exceptions addObject:@"find_close_pressed_incognito"];
  // TODO(crbug.com/40519792): Add missing images.
  [exceptions addObject:@"glif-mic-to-dots-small_37"];
  [exceptions addObject:@"glif-mic-to-dots-large_37"];
  [exceptions addObject:@"glif-google-to-dots_140"];
  // TODO(crbug.com/41318906): Add missing image.
  [exceptions addObject:@"voice_icon_keyboard_accessory"];

  // The original implementation of [UIImage imageNamed:].
  // Called by the new implementation.
  static IMP originalImp;
  IMP* originalImpPtr = &originalImp;

  id swizzleBlock = ^(id self, NSString* imageName) {
    // Call the original [UIImage imageNamed:] method.
    UIImage* (*imp)(id, SEL, id) =
        (UIImage * (*)(id, SEL, id)) * originalImpPtr;
    Class aClass = objc_getClass("UIImage");
    UIImage* image = imp(aClass, @selector(imageNamed:), imageName);

    if (![exceptions containsObject:imageName] &&
        ![imageName containsString:@".FAUXBUNDLEID."]) {
      // TODO(crbug.com/40225445): Temporarily turn off warning while bootstrapping
      // Catalyst. Log the error to the console instead.
      #if BUILDFLAG(IS_IOS_MACCATALYST)
        DLOG(WARNING) << "Missing image: " << base::SysNSStringToUTF8(imageName);
      #else
        DLOG(WARNING) << "Missing image: " << base::SysNSStringToUTF8(imageName);
      #endif
    }
    return image;
  };

  Method method = class_getClassMethod([UIImage class], @selector(imageNamed:));
  CHECK(method);

  IMP blockImp = imp_implementationWithBlock(swizzleBlock);
  originalImp = method_setImplementation(method, blockImp);
}

// Swizzles +[UIImage imageWithContentsOfFile:] to trigger a warning if an
// invalid image is attempted to be loaded.
void SwizzleUIImageImageWithContentsOfFile() {
  // The original implementation of [UIImage imageWithContentsOfFile:].
  // Called by the new implementation.
  static IMP original_imp;
  IMP* original_imp_ptr = &original_imp;

  id swizzle_block = ^(id self, NSString* path) {
    // Call the original [UIImage imageWithContentsOfFile:] method.
    UIImage* (*imp)(id, SEL, id) =
        reinterpret_cast<UIImage* (*)(id, SEL, id)>(*original_imp_ptr);
    Class class_object = objc_getClass("UIImage");
    UIImage* image =
        imp(class_object, @selector(imageWithContentsOfFile:), path);
    DLOG(WARNING) << "Missing image at path: " << base::SysNSStringToUTF8(path);
    return image;
  };

  Method method = class_getClassMethod([UIImage class],
                                       @selector(imageWithContentsOfFile:));
  CHECK(method);

  IMP block_imp = imp_implementationWithBlock(swizzle_block);
  original_imp = method_setImplementation(method, block_imp);
}

// Swizzles +[NSData dataWithContentsOfFile:] to trigger a warning if an invalid
// image is attempted to be loaded.
void SwizzleNSDataDataWithContentsOfFile() {
  // The original implementation of [NSData dataWithContentsOfFile:].
  // Called by the new implementation.
  static IMP original_imp;
  IMP* original_imp_ptr = &original_imp;

  // Retained by the swizzle block.
  // A set of file extensions that are exceptions to the 'missing data' check.
  NSMutableSet* exceptions = [NSMutableSet set];
  [exceptions addObject:@"plist"];
  [exceptions addObject:@"png"];
  [exceptions addObject:@"jpg"];
  // Can have no path extension.
  [exceptions addObject:@""];

  id swizzle_block = ^(id self, NSString* path) {
    // Call the original [NSData dataWithContentsOfFile:] method.
    NSData* (*imp)(id, SEL, id) =
        reinterpret_cast<NSData* (*)(id, SEL, id)>(*original_imp_ptr);
    Class class_object = objc_getClass("NSData");
    NSData* data = imp(class_object, @selector(dataWithContentsOfFile:), path);
    if (![exceptions containsObject:[path pathExtension]] &&
        [path pathExtension]) {
      DLOG(WARNING) << "Missing data at path: " << base::SysNSStringToUTF8(path);
    }
    return data;
  };

  Method method =
      class_getClassMethod([NSData class], @selector(dataWithContentsOfFile:));
  CHECK(method);

  IMP block_imp = imp_implementationWithBlock(swizzle_block);
  original_imp = method_setImplementation(method, block_imp);
}

#endif  // !defined(NDEBUG)

}  // namespace

@implementation SetupDebugging

+ (void)setUpDebuggingOptions {
// Enable the zombie treadmill on simulator builds.
// TODO(crbug.com/40492640): Consider enabling this on device builds too.
#if TARGET_IPHONE_SIMULATOR
#if !defined(ADDRESS_SANITIZER) && !defined(MEMORY_SANITIZER)
  CHECK(ObjcEvilDoers::ZombieEnable(true, 10000));
#endif
#endif

#if !defined(NDEBUG)
  // Enable the detection of missing assets.
  SwizzleUIImageImageNamed();
  SwizzleUIImageImageWithContentsOfFile();
  SwizzleNSDataDataWithContentsOfFile();
#endif
}

@end