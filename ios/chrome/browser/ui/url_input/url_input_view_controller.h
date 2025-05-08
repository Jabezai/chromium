// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_URL_INPUT_URL_INPUT_VIEW_CONTROLLER_H_
#define IOS_CHROME_BROWSER_UI_URL_INPUT_URL_INPUT_VIEW_CONTROLLER_H_

#import <UIKit/UIKit.h>

#import "ios/chrome/browser/omnibox/ui_bundled/omnibox_text_field_ios.h"
#import "ios/chrome/browser/toolbar/ui_bundled/toolbar_coordinator.h"

// Protocol for handling URL submission from the swipe menu.
@protocol URLInputViewControllerDelegate <NSObject>
- (void)urlInputViewController:(UIViewController*)controller
                  didEnterURL:(NSURL*)url;
@end

// View controller displaying the primary and secondary toolbars.
@interface URLInputViewController : UIViewController <UIGestureRecognizerDelegate>

// The toolbar coordinator providing the primary and secondary toolbars.
@property(nonatomic, strong) ToolbarCoordinator* toolbarCoordinator;

// Delegate to handle URL submission.
@property(nonatomic, weak) id<URLInputViewControllerDelegate> delegate;

@end

#endif  // IOS_CHROME_BROWSER_UI_URL_INPUT_URL_INPUT_VIEW_CONTROLLER_H_