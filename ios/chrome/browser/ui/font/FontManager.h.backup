#ifndef IOS_CHROME_APP_FONT_MANAGER_H_
#define IOS_CHROME_APP_FONT_MANAGER_H_

#import <UIKit/UIKit.h>

@interface FontManager : NSObject

+ (FontManager *)sharedManager;
- (BOOL)registerCustomFont;
- (void)applyCustomFontToTextElementsInView:(UIView *)view;
- (void)applyCustomFontToAllTextFields;
@property(nonatomic, readonly, strong) UIFont* customFont;

@end

#endif  // IOS_CHROME_APP_FONT_MANAGER_H_