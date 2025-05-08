// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/url_input/slide_transition_animator.h"

@implementation SlideTransitionAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
  return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
  UIViewController* toViewController =
      [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  UIViewController* fromViewController =
      [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  UIView* containerView = [transitionContext containerView];

  if (self.presenting) {
    // Slide from right to left
    toViewController.view.frame = CGRectOffset(containerView.bounds, containerView.bounds.size.width, 0);
    [containerView addSubview:toViewController.view];
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                       toViewController.view.frame = containerView.bounds;
                       fromViewController.view.frame = CGRectOffset(containerView.bounds, -containerView.bounds.size.width / 2, 0);
                     }
                     completion:^(BOOL finished) {
                       [transitionContext completeTransition:finished];
                     }];
  } else {
    // Slide back to right
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                       fromViewController.view.frame = CGRectOffset(containerView.bounds, containerView.bounds.size.width, 0);
                       toViewController.view.frame = containerView.bounds;
                     }
                     completion:^(BOOL finished) {
                       [fromViewController.view removeFromSuperview];
                       [transitionContext completeTransition:finished];
                     }];
  }
}

@end