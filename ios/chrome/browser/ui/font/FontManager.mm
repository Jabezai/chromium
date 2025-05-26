#import "ios/chrome/browser/ui/font/FontManager.h"
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

@interface FontManager ()
@property(nonatomic, strong) UIFont* customFont;
@property(nonatomic, strong) NSString* customFontName;
@end

@implementation FontManager

+ (FontManager *)sharedManager {
  static FontManager *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [[FontManager alloc] init];
  });
  return sharedManager;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    if ([self registerCustomFont]) {
      [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(applyCustomFontToAllTextFields)
                                                  name:UIApplicationDidBecomeActiveNotification
                                                object:nil];
    } else {
      NSLog(@"Failed to initialize FontManager due to font registration failure");
    }
  }
  return self;
}

- (BOOL)registerCustomFont {
  // Debug bundle resources
  NSArray *ttfFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"ttf" inDirectory:nil];
  NSLog(@"Available .ttf files in bundle: %@", ttfFiles);
  
  NSString *fontPath = [[NSBundle mainBundle] pathForResource:@"MyCustomFont" ofType:@"ttf"];
  BOOL isReadable = [[NSFileManager defaultManager] isReadableFileAtPath:fontPath];
  NSLog(@"Font file is readable: %d, path: %@", isReadable, fontPath);
  
  if (!fontPath || !isReadable) {
    NSLog(@"Error: Font file not found or not readable at path: %@", fontPath);
    return NO;
  }

  NSURL *fontURL = [NSURL fileURLWithPath:fontPath];
  CFErrorRef error;
  if (!CTFontManagerRegisterFontsForURL((__bridge CFURLRef)fontURL, kCTFontManagerScopeProcess, &error)) {
    CFStringRef errorDescription = CFErrorCopyDescription(error);
    NSLog(@"Failed to register font: %@", errorDescription);
    CFRelease(errorDescription);
    return NO;
  }

  // Extract PostScript name
  CGDataProviderRef provider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontURL);
  CGFontRef font = CGFontCreateWithDataProvider(provider);
  if (!font) {
    NSLog(@"Error: Failed to create CGFont from provider");
    CGDataProviderRelease(provider);
    return NO;
  }
  NSString *fontName = (__bridge NSString *)CGFontCopyPostScriptName(font);
  NSLog(@"Font PostScript name: %@", fontName);
  self.customFontName = fontName;
  self.customFont = [UIFont fontWithName:fontName size:17.0];
  CGFontRelease(font);
  CGDataProviderRelease(provider);

  if (!self.customFont) {
    NSLog(@"Error: Failed to create font with name: %@", fontName);
    return NO;
  }
  
  NSLog(@"Successfully registered font: %@ at path: %@", fontName, fontPath);
  return YES;
}

- (void)applyCustomFontToTextElementsInView:(UIView *)view {
  NSLog(@"Applying font to view: %@, class: %@", view, NSStringFromClass([view class]));
  
  // Retry font registration if customFont is nil
  if (!self.customFont) {
    [self registerCustomFont];
  }
  
  if ([view isKindOfClass:[UITextField class]]) {
    UITextField *textField = (UITextField *)view;
    if (self.customFont) {
      textField.font = self.customFont;
      NSLog(@"Applied %@ to UITextField: %@, font: %@, view: %p", self.customFontName, textField.text, textField.font.fontName, textField);
      // Add observer for font and bounds changes
      if ([textField isKindOfClass:NSClassFromString(@"OmniboxTextFieldIOS")]) {
        [textField addObserver:self
                    forKeyPath:@"font"
                       options:NSKeyValueObservingOptionNew
                       context:nil];
        [textField addObserver:self
                    forKeyPath:@"bounds"
                       options:NSKeyValueObservingOptionNew
                       context:nil];
      }
    } else {
      NSLog(@"Warning: Failed to create %@ for UITextField: %@", self.customFontName, textField.text);
    }
  } else if ([view isKindOfClass:[UIButton class]]) {
    UIButton *button = (UIButton *)view;
    if (self.customFont) {
      button.titleLabel.font = self.customFont;
      NSLog(@"Applied %@ to UIButton: %@, font: %@", self.customFontName, [button titleForState:UIControlStateNormal], button.titleLabel.font.fontName);
    } else {
      NSLog(@"Warning: Failed to create %@ for UIButton: %@", self.customFontName, [button titleForState:UIControlStateNormal]);
    }
  } else if ([view isKindOfClass:[UILabel class]]) {
    UILabel *label = (UILabel *)view;
    if (self.customFont) {
      label.font = self.customFont;
      NSLog(@"Applied %@ to UILabel: %@, font: %@", self.customFontName, label.text, label.font.fontName);
    } else {
      NSLog(@"Warning: Failed to create %@ for UILabel: %@", self.customFontName, label.text);
    }
  } else if ([view isKindOfClass:NSClassFromString(@"OmniboxContainerView")]) {
    if (self.customFont) {
      NSLog(@"Applying %@ to OmniboxContainerView: %@", self.customFontName, view);
    }
  } else {
    NSLog(@"Skipping view, not a supported class: %@", NSStringFromClass([view class]));
  }
  
  for (UIView *subview in view.subviews) {
    [self applyCustomFontToTextElementsInView:subview];
  }
}

- (void)applyCustomFontToAllTextFields {
  UIWindow *keyWindow = nil;
  if (@available(iOS 15.0, *)) {
    for (UIWindowScene *windowScene in UIApplication.sharedApplication.connectedScenes) {
      if ([windowScene isKindOfClass:[UIWindowScene class]]) {
        keyWindow = windowScene.windows.firstObject;
        if (keyWindow) break;
      }
    }
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    keyWindow = UIApplication.sharedApplication.windows.firstObject;
#pragma clang diagnostic pop
  }
  if (keyWindow) {
    [self applyCustomFontToTextElementsInView:keyWindow];
    NSLog(@"Reapplied %@ to all text fields in key window", self.customFontName);
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"font"] && [object isKindOfClass:[UITextField class]]) {
    UITextField *textField = (UITextField *)object;
    UIFont *newFont = change[NSKeyValueChangeNewKey];
    if (self.customFont && ![newFont.fontName isEqualToString:self.customFontName]) {
      textField.font = self.customFont;
      NSLog(@"Reapplied %@ to UITextField in font KVO: %@, font: %@", self.customFontName, textField.text, textField.font.fontName);
    }
  } else if ([keyPath isEqualToString:@"bounds"] && [object isKindOfClass:[UITextField class]]) {
    UITextField *textField = (UITextField *)object;
    if (self.customFont && ![textField.font.fontName isEqualToString:self.customFontName]) {
      textField.font = self.customFont;
      NSLog(@"Reapplied %@ to UITextField in bounds KVO: %@, font: %@", self.customFontName, textField.text, textField.font.fontName);
    }
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  // Remove KVO observers
  UIWindow *keyWindow = nil;
  if (@available(iOS 15.0, *)) {
    for (UIWindowScene *windowScene in UIApplication.sharedApplication.connectedScenes) {
      if ([windowScene isKindOfClass:[UIWindowScene class]]) {
        keyWindow = windowScene.windows.firstObject;
        if (keyWindow) break;
      }
    }
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    keyWindow = UIApplication.sharedApplication.windows.firstObject;
#pragma clang diagnostic pop
  }
  if (keyWindow) {
    [self removeObserversFromView:keyWindow];
  }
}

- (void)removeObserversFromView:(UIView *)view {
  if ([view isKindOfClass:[UITextField class]] && [view isKindOfClass:NSClassFromString(@"OmniboxTextFieldIOS")]) {
    UITextField *textField = (UITextField *)view;
    @try {
      [textField removeObserver:self forKeyPath:@"font"];
      [textField removeObserver:self forKeyPath:@"bounds"];
      NSLog(@"Removed KVO observers for UITextField: %@", textField);
    } @catch (NSException *exception) {
      NSLog(@"Error removing KVO observer for UITextField: %@", exception);
    }
  }
  for (UIView *subview in view.subviews) {
    [self removeObserversFromView:subview];
  }
}

@end