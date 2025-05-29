// Copyright 2022 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/shared/ui/symbols/symbol_helpers.h"

#import "base/check.h"
#import "ios/chrome/browser/shared/public/features/features.h"
#import "ios/chrome/browser/shared/ui/symbols/symbol_configurations.h"

namespace {

UIImageConfiguration* DefaultSymbolConfigurationWithPointSize(CGFloat point_size) {
  NSLog(@"SymbolHelpers: Creating configuration with point_size=%f", point_size);
  return [UIImageSymbolConfiguration
      configurationWithPointSize:point_size
                          weight:UIImageSymbolWeightMedium
                           scale:UIImageSymbolScaleMedium];
}

UIImage* FallbackBlankImage() {
  NSLog(@"SymbolHelpers: Generating fallback blank image");
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), NO, 0.0);
  UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

UIImage* SymbolWithConfiguration(NSString* symbol_name,
                                 UIImageConfiguration* configuration,
                                 BOOL system_symbol) {
  NSLog(@"SymbolHelpers: Loading symbol=%@, system=%d", symbol_name, system_symbol);
  UIImage* symbol;
  if (system_symbol) {
    symbol = [UIImage systemImageNamed:symbol_name
                     withConfiguration:configuration];
  } else {
    symbol = [UIImage imageNamed:symbol_name
                        inBundle:nil
               withConfiguration:configuration];
  }
  if (!symbol) {
    NSLog(@"SymbolHelpers: Failed to load symbol=%@, system=%d, returning fallback", symbol_name, system_symbol);
    symbol = FallbackBlankImage();
  }
  return symbol;
}

}  // namespace

extern "C" {

UIImage* DefaultSymbolWithConfiguration(NSString* symbol_name,
                                        UIImageConfiguration* configuration) {
  return SymbolWithConfiguration(symbol_name, configuration, true);
}

UIImage* CustomSymbolWithConfiguration(NSString* symbol_name,
                                       UIImageConfiguration* configuration) {
  return SymbolWithConfiguration(symbol_name, configuration, false);
}

UIImage* DefaultSymbolWithPointSize(NSString* symbol_name, CGFloat point_size) {
  return DefaultSymbolWithConfiguration(
      symbol_name, DefaultSymbolConfigurationWithPointSize(point_size));
}

UIImage* CustomSymbolWithPointSize(NSString* symbol_name, CGFloat point_size) {
  return CustomSymbolWithConfiguration(
      symbol_name, DefaultSymbolConfigurationWithPointSize(point_size));
}

UIImage* DefaultSymbolTemplateWithPointSize(NSString* symbol_name,
                                            CGFloat point_size) {
  return [DefaultSymbolWithPointSize(symbol_name, point_size)
      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

UIImage* CustomSymbolTemplateWithPointSize(NSString* symbol_name,
                                           CGFloat point_size) {
  return [CustomSymbolWithPointSize(symbol_name, point_size)
      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

UIImage* MakeSymbolMonochrome(UIImage* symbol) {
  return [symbol
      imageByApplyingSymbolConfiguration:
          [UIImageSymbolConfiguration configurationPreferringMonochrome]];
}

UIImage* MakeSymbolMulticolor(UIImage* symbol) {
  return [symbol
      imageByApplyingSymbolConfiguration:
          [UIImageSymbolConfiguration configurationPreferringMulticolor]];
}

UIImage* SymbolWithPalette(UIImage* symbol, NSArray<UIColor*>* colors) {
  return [symbol
      imageByApplyingSymbolConfiguration:
          [UIImageSymbolConfiguration configurationWithPaletteColors:colors]];
}

UIImage* DefaultSettingsRootSymbol(NSString* symbol_name) {
  return DefaultSymbolWithPointSize(symbol_name,
                                    kSettingsRootSymbolImagePointSize);
}

UIImage* CustomSettingsRootSymbol(NSString* symbol_name) {
  return CustomSymbolWithPointSize(symbol_name,
                                   kSettingsRootSymbolImagePointSize);
}

UIImage* CustomSettingsRootMulticolorSymbol(NSString* symbol_name) {
  return MakeSymbolMulticolor(CustomSymbolWithPointSize(
      symbol_name, kSettingsRootSymbolImagePointSize));
}

UIImage* DefaultAccessorySymbolConfigurationWithRegularWeight(
    NSString* symbol_name) {
  return DefaultSymbolWithConfiguration(
      symbol_name, [UIImageSymbolConfiguration
                       configurationWithPointSize:kSymbolAccessoryPointSize
                                           weight:UIImageSymbolWeightRegular
                                            scale:UIImageSymbolScaleMedium]);
}

}  // extern "C"