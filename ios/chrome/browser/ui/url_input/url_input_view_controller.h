// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_URL_INPUT_URL_INPUT_VIEW_CONTROLLER_H_
#define IOS_CHROME_BROWSER_UI_URL_INPUT_URL_INPUT_VIEW_CONTROLLER_H_

#import <UIKit/UIKit.h>

// Protocol for handling URL input actions.
@protocol URLInputViewControllerDelegate <NSObject>
- (void)urlInputViewController:(UIViewController*)controller
                  didEnterURL:(NSURL*)url;
@end

// View controller displaying a URL input bar.
@interface URLInputViewController : UIViewController
@property(nonatomic, weak) id<URLInputViewControllerDelegate> delegate;
@end

#endif  // IOS_CHROME_BROWSER_UI_URL_INPUT_URL_INPUT_VIEW_CONTROLLER_H_