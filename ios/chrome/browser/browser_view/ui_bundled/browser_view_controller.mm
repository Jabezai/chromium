// Copyright 2012 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/browser_view/ui_bundled/browser_view_controller.h"

#import "base/apple/bundle_locations.h"
#import "base/apple/foundation_util.h"
#import "base/memory/raw_ptr.h"
#import "base/metrics/histogram_functions.h"
#import "base/metrics/user_metrics.h"
#import "base/metrics/user_metrics_action.h"
#import "base/strings/sys_string_conversions.h"
#import "base/task/sequenced_task_runner.h"
#import "components/enterprise/idle/idle_pref_names.h"
#import "components/prefs/pref_service.h"
#import "components/signin/public/identity_manager/identity_manager.h"
#import "components/strings/grit/components_strings.h"
#import "ios/chrome/browser/authentication/ui_bundled/re_signin_infobar_delegate.h"
#import "ios/chrome/browser/bookmarks/ui_bundled/home/bookmarks_coordinator.h"
#import "ios/chrome/browser/browser_container/ui_bundled/browser_container_view_controller.h"
#import "ios/chrome/browser/browser_view/model/browser_view_visibility_audience.h"
#import "ios/chrome/browser/browser_view/public/browser_view_visibility_state.h"
#import "ios/chrome/browser/browser_view/ui_bundled/browser_view_controller+private.h"
#import "ios/chrome/browser/browser_view/ui_bundled/key_commands_provider.h"
#import "ios/chrome/browser/browser_view/ui_bundled/safe_area_provider.h"
#import "ios/chrome/browser/content_suggestions/ui_bundled/ntp_home_constant.h"
#import "ios/chrome/browser/crash_report/model/crash_keys_helper.h"
#import "ios/chrome/browser/default_promo/ui_bundled/default_promo_non_modal_presentation_delegate.h"
#import "ios/chrome/browser/discover_feed/model/feed_constants.h"
#import "ios/chrome/browser/find_in_page/model/util.h"
#import "ios/chrome/browser/first_run/ui_bundled/first_run_util.h"
#import "ios/chrome/browser/fullscreen/ui_bundled/fullscreen_animator.h"
#import "ios/chrome/browser/fullscreen/ui_bundled/fullscreen_reason.h"
#import "ios/chrome/browser/fullscreen/ui_bundled/fullscreen_ui_element.h"
#import "ios/chrome/browser/fullscreen/ui_bundled/fullscreen_ui_updater.h"
#import "ios/chrome/browser/incognito_reauth/ui_bundled/features.h"
#import "ios/chrome/browser/incognito_reauth/ui_bundled/incognito_reauth_constants.h"
#import "ios/chrome/browser/incognito_reauth/ui_bundled/incognito_reauth_scene_agent.h"
#import "ios/chrome/browser/incognito_reauth/ui_bundled/incognito_reauth_view.h"
#import "ios/chrome/browser/intents/model/intents_donation_helper.h"
#import "ios/chrome/browser/main_content/ui_bundled/main_content_ui.h"
#import "ios/chrome/browser/main_content/ui_bundled/main_content_ui_broadcasting_util.h"
#import "ios/chrome/browser/main_content/ui_bundled/main_content_ui_state.h"
#import "ios/chrome/browser/main_content/ui_bundled/web_scroll_view_main_content_ui_forwarder.h"
#import "ios/chrome/browser/metrics/model/tab_usage_recorder_browser_agent.h"
#import "ios/chrome/browser/ntp/model/new_tab_page_tab_helper.h"
#import "ios/chrome/browser/ntp/model/new_tab_page_util.h"
#import "ios/chrome/browser/ntp/ui_bundled/new_tab_page_coordinator.h"
#import "ios/chrome/browser/omnibox/public/omnibox_ui_features.h"
#import "ios/chrome/browser/popup_menu/ui_bundled/overflow_menu/feature_flags.h"
#import "ios/chrome/browser/popup_menu/ui_bundled/popup_menu_coordinator.h"
#import "ios/chrome/browser/reading_list/model/reading_list_browser_agent.h"
#import "ios/chrome/browser/shared/model/application_context/application_context.h"
#import "ios/chrome/browser/shared/model/url/chrome_url_constants.h"
#import "ios/chrome/browser/shared/public/commands/application_commands.h"
#import "ios/chrome/browser/shared/public/commands/find_in_page_commands.h"
#import "ios/chrome/browser/shared/public/commands/help_commands.h"
#import "ios/chrome/browser/shared/public/commands/omnibox_commands.h"
#import "ios/chrome/browser/shared/public/commands/popup_menu_commands.h"
#import "ios/chrome/browser/shared/public/commands/reading_list_add_command.h"
#import "ios/chrome/browser/shared/public/commands/settings_commands.h"
#import "ios/chrome/browser/shared/public/commands/text_zoom_commands.h"
#import "ios/chrome/browser/shared/ui/util/named_guide.h"
#import "ios/chrome/browser/shared/ui/util/uikit_ui_util.h"
#import "ios/chrome/browser/shared/ui/util/url_with_title.h"
#import "ios/chrome/browser/side_swipe/ui_bundled/card_swipe_view_delegate.h"
#import "ios/chrome/browser/side_swipe/ui_bundled/side_swipe_coordinator.h"
#import "ios/chrome/browser/side_swipe/ui_bundled/side_swipe_mediator.h"
#import "ios/chrome/browser/side_swipe/ui_bundled/side_swipe_ui_controller_delegate.h"
#import "ios/chrome/browser/side_swipe/ui_bundled/swipe_view.h"
#import "ios/chrome/browser/signin/model/identity_manager_factory.h"
#import "ios/chrome/browser/snapshots/model/snapshot_tab_helper.h"
#import "ios/chrome/browser/tab_switcher/ui_bundled/tab_strip/coordinator/tab_strip_coordinator.h"
#import "ios/chrome/browser/tab_switcher/ui_bundled/tab_strip/ui/swift_constants_for_objective_c.h"
#import "ios/chrome/browser/tab_switcher/ui_bundled/tab_strip/ui/tab_strip_utils.h"
#import "ios/chrome/browser/tabs/ui_bundled/background_tab_animation_view.h"
#import "ios/chrome/browser/tabs/ui_bundled/foreground_tab_animation_view.h"
#import "ios/chrome/browser/tabs/ui_bundled/switch_to_tab_animation_view.h"
#import "ios/chrome/browser/toolbar/ui_bundled/accessory/toolbar_accessory_presenter.h"
#import "ios/chrome/browser/toolbar/ui_bundled/buttons/toolbar_configuration.h"
#import "ios/chrome/browser/toolbar/ui_bundled/fullscreen/toolbars_size.h"
#import "ios/chrome/browser/toolbar/ui_bundled/fullscreen/toolbars_size_broadcasting_util.h"
#import "ios/chrome/browser/toolbar/ui_bundled/toolbar_coordinator.h"
#import "ios/chrome/browser/ui/url_input/url_input_view_controller.h"
#import "ios/chrome/browser/url_loading/model/url_loading_browser_agent.h"
#import "ios/chrome/browser/url_loading/model/url_loading_params.h"
#import "ios/chrome/browser/voice/ui_bundled/voice_search_notification_names.h"
#import "ios/chrome/browser/web/model/page_placeholder_browser_agent.h"
#import "ios/chrome/browser/web/model/page_placeholder_tab_helper.h"
#import "ios/chrome/browser/web/model/web_navigation_browser_agent.h"
#import "ios/chrome/browser/web/model/web_navigation_util.h"
#import "ios/chrome/browser/web_state_list/model/web_usage_enabler/web_usage_enabler_browser_agent.h"
#import "ios/chrome/browser/webui/model/show_mail_composer_context.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/common/ui/promo_style/promo_style_view_controller.h"
#import "ios/chrome/common/ui/util/constraints_ui_util.h"
#import "ios/chrome/common/ui/util/ui_util.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ios/public/provider/chrome/browser/fullscreen/fullscreen_api.h"
#import "ios/public/provider/chrome/browser/voice_search/voice_search_controller.h"
#import "ios/web/public/ui/crw_web_view_proxy.h"
#import "net/base/apple/url_conversions.h"
#import "services/metrics/public/cpp/ukm_builders.h"
#import "ui/base/device_form_factor.h"
#import "ui/base/l10n/l10n_util.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

// File-level constant for top padding below Dynamic Island/status bar
static const CGFloat kTopPadding = 8.0;

namespace {

enum HeaderBehaviour {
  // The header moves completely out of the screen.
  Hideable = 0,
  // This header stays on screen and covers part of the content.
  Overlap
};

}  // namespace

#pragma mark - HeaderDefinition helper

// Class used to define a header, an object displayed at the top of the browser.
@interface HeaderDefinition : NSObject

// The header view.
@property(nonatomic, strong) UIView* view;
// How to place the view, and its behaviour when the headers move.
@property(nonatomic, assign) HeaderBehaviour behaviour;

- (instancetype)initWithView:(UIView*)view
             headerBehaviour:(HeaderBehaviour)behaviour;

+ (instancetype)definitionWithView:(UIView*)view
                   headerBehaviour:(HeaderBehaviour)behaviour;

@end

@implementation HeaderDefinition
@synthesize view = _view;
@synthesize behaviour = _behaviour;

+ (instancetype)definitionWithView:(UIView*)view
                   headerBehaviour:(HeaderBehaviour)behaviour {
  return [[self alloc] initWithView:view headerBehaviour:behaviour];
}

- (instancetype)initWithView:(UIView*)view
             headerBehaviour:(HeaderBehaviour)behaviour {
  self = [super init];
  if (self) {
    _view = view;
    _behaviour = behaviour;
  }
  return self;
}

@end

#pragma mark - YourCustomSlideAnimator

// Custom animator for sliding URLInputViewController in from the right.
@interface YourCustomSlideAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property(nonatomic, assign) BOOL isPresenting;
- (instancetype)initWithIsPresenting:(BOOL)isPresenting;
@end

@implementation YourCustomSlideAnimator

- (instancetype)initWithIsPresenting:(BOOL)isPresenting {
  self = [super init];
  if (self) {
    _isPresenting = isPresenting;
  }
  return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
  return 0.3; // Duration of the animation
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
  UIView *containerView = transitionContext.containerView;
  UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];

  if (self.isPresenting) {
    // Slide in from the right
    toViewController.view.frame = CGRectOffset(containerView.bounds, containerView.bounds.size.width, 0);
    [containerView addSubview:toViewController.view];

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                       toViewController.view.frame = containerView.bounds;
                     }
                     completion:^(BOOL finished) {
                       [transitionContext completeTransition:finished];
                     }];
  } else {
    // Slide out to the right
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                       fromViewController.view.frame = CGRectOffset(containerView.bounds, containerView.bounds.size.width, 0);
                     }
                     completion:^(BOOL finished) {
                       [fromViewController.view removeFromSuperview];
                       [transitionContext completeTransition:finished];
                     }];
  }
}

@end

#pragma mark - URLInputTransitioningDelegate

// Transitioning delegate for URLInputViewController to manage custom slide animations.
@interface URLInputTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>
@end

@implementation URLInputTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
  return [[YourCustomSlideAnimator alloc] initWithIsPresenting:YES];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
  return [[YourCustomSlideAnimator alloc] initWithIsPresenting:NO];
}

@end

#pragma mark - BVC

// Note other delegates defined in the Delegates category header.
@interface BrowserViewController () <CardSwipeViewDelegate, FullscreenUIElement, MainContentUI, SideSwipeUIControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, URLInputViewControllerDelegate> {
  // Identifier for each animation of an NTP opening.
  NSInteger _NTPAnimationIdentifier;

  // Mediator for edge swipe gestures for page and tab navigation.
  SideSwipeCoordinator* _sideSwipeCoordinator;

  // Keyboard commands provider. It offloads most of the keyboard commands
  // management off of the BVC.
  KeyCommandsProvider* _keyCommandsProvider;

  // Used to display the Voice Search UI. Nil if not visible.
  id<VoiceSearchController> _voiceSearchController;

  // YES if Voice Search should be started when the new tab animation is
  // finished.
  BOOL _startVoiceSearchAfterNewTabAnimation;

  // Whether or not -shutdown has been called.
  BOOL _isShutdown;

  // Whether or not Incognito* is enabled.
  BOOL _isOffTheRecord;

  // The Browser's WebStateList.
  base::WeakPtr<WebStateList> _webStateList;

  // Whether the current content is incognito and requires biometric
  // authentication from the user before it can be accessed.
  BOOL _itemsRequireAuthentication;

  // The last point within `contentArea` that's received a touch.
  CGPoint _lastTapPoint;

  // The time at which `_lastTapPoint` was most recently set.
  CFTimeInterval _lastTapTime;

  // The coordinator that shows the bookmarking UI after the user taps the star
  // button.
  BookmarksCoordinator* _bookmarksCoordinator;

  // Toolbars size that broadcasts changes to min and max heights.
  ToolbarsSize* _toolbarsSize;

  // The main content UI updater for the content displayed by this BVC.
  MainContentUIStateUpdater* _mainContentUIUpdater;

  // The forwarder for web scroll view interaction events.
  WebScrollViewMainContentUIForwarder* _webMainContentUIForwarder;

  // The updater that adjusts the toolbar's layout for fullscreen events.
  std::unique_ptr<FullscreenUIUpdater> _fullscreenUIUpdater;

  // Fake status bar view used to blend the toolbar into the status bar.
  UIView* _fakeStatusBarView;

  // Used to load url parameters in current or new tab.
  raw_ptr<UrlLoadingBrowserAgent> _urlLoadingBrowserAgent;

  // Used to report usage of a single Browser's tab.
  raw_ptr<TabUsageRecorderBrowserAgent> _tabUsageRecorderBrowserAgent;

  // Used to get the layout guide center.
  LayoutGuideCenter* _layoutGuideCenter;

  // Used to add or cancel a page placeholder for next navigation.
  raw_ptr<PagePlaceholderBrowserAgent> _pagePlaceholderBrowserAgent;

  // Backing ivar for mainContentUIState property.
  MainContentUIState* _mainContentUIState;

  // Backing ivar for logoAnimationControllerOwner property.
  id<LogoAnimationControllerOwner> _logoAnimationControllerOwner;

  UIPanGestureRecognizer* _contentPanGestureRecognizer;

  // Tracks the last known contentOffset to restore after frame updates.
  CGPoint _lastContentOffset;
}

// Activates/deactivates the object. This will enable/disable the ability for
// this object to browse, and to have live UIWebViews associated with it. While
// not active, the UI will not react to changes in the active web state, so
// generally an inactive BVC should not be visible.
@property(nonatomic, assign, getter=isActive) BOOL active;
// Consumer that gets notified of the visibility of the browser view.
@property(nonatomic, weak) id<BrowserViewVisibilityAudience>
    browserViewVisibilityAudience;
// Browser container view controller.
@property(nonatomic, strong)
    BrowserContainerViewController* browserContainerViewController;
// Invisible button used to dismiss the keyboard.
@property(nonatomic, strong) UIButton* typingShield;
// The visibility state of the browser view. Value will be set to `kVisible` on
// viewDidAppear and to `kNotInViewHierarchy` on viewWillDisappear.
@property(nonatomic, assign) BrowserViewVisibilityState visibilityState;
// Whether the controller should broadcast its UI.
@property(nonatomic, assign, getter=isBroadcasting) BOOL broadcasting;
// A view to obscure incognito content when the user isn't authorized to
// see it.
@property(nonatomic, strong) IncognitoReauthView* blockingView;
// Whether the controller is currently dismissing a presented view controller.
@property(nonatomic, assign, getter=isDismissingModal) BOOL dismissingModal;
// Whether a new tab animation is occurring.
@property(nonatomic, assign, getter=isInNewTabAnimation) BOOL inNewTabAnimation;
// Whether BVC prefers to hide the status bar. This value is used to determine
// the response from the `prefersStatusBarHidden` method.
@property(nonatomic, assign) BOOL hideStatusBar;
// A block to be run when the `tabWasAdded:` method completes the animation
// for the presentation of a new tab. Can be used to record performance metrics.
@property(nonatomic, strong, nullable)
    ProceduralBlock foregroundTabWasAddedCompletionBlock;
// Coordinator for the tablet tab strip.
@property(nonatomic, strong) TabStripCoordinator* tabStripCoordinator;
// A weak reference to the view of the tab strip on tablet.
@property(nonatomic, weak) UIView* tabStripView;
// Container view to enforce web view size
@property(nonatomic, strong) UIView *containerView;

// Returns the header views, all the chrome on top of the page, including the
// ones that cannot be scrolled off screen by full screen.
@property(nonatomic, strong, readonly) NSArray<HeaderDefinition*>* headerViews;

// Coordinator for the popup menus.
@property(nonatomic, strong) PopupMenuCoordinator* popupMenuCoordinator;

// Presenter used to display accessories over the toolbar (e.g. Find In Page).
@property(nonatomic, strong)
    ToolbarAccessoryPresenter* toolbarAccessoryPresenter;

// Command handler for text zoom commands.
@property(nonatomic, weak) id<TextZoomCommands> textZoomHandler;

// Command handler for help commands.
@property(nonatomic, weak) id<HelpCommands> helpHandler;

// Command handler for popup menu commands.
@property(nonatomic, weak) id<PopupMenuCommands> popupMenuCommandsHandler;

// Command handler for application commands.
@property(nonatomic, weak) id<ApplicationCommands> applicationCommandsHandler;

// Command handler for find in page commands.
@property(nonatomic, weak) id<FindInPageCommands> findInPageCommandsHandler;

// The FullscreenController.
@property(nonatomic, assign) FullscreenController* fullscreenController;

// Coordinator of primary and secondary toolbars.
@property(nonatomic, strong) ToolbarCoordinator* toolbarCoordinator;

// Vertical offset for the primary toolbar, used for fullscreen.
@property(nonatomic, strong) NSLayoutConstraint* primaryToolbarOffsetConstraint;
// Height constraint for the primary toolbar.
@property(nonatomic, strong) NSLayoutConstraint* primaryToolbarHeightConstraint;
// Height constraint for the secondary toolbar.
@property(nonatomic, strong) NSLayoutConstraint* secondaryToolbarHeightConstraint;
// Current Fullscreen progress for the footers.
@property(nonatomic, assign) CGFloat footerFullscreenProgress;
// Y-dimension offset for placement of the header.
@property(nonatomic, readonly) CGFloat headerOffset;
// Height of the header view.
@property(nonatomic, readonly) CGFloat headerHeight;

// The webState of the active tab.
@property(nonatomic, readonly) web::WebState* currentWebState;

// A gesture recognizer to track the last tapped window and the coordinates of
// the last tap.
@property(nonatomic, strong) UIGestureRecognizer* contentAreaGestureRecognizer;

// The coordinator for all NTPs in the BVC. Only used if kSingleNtp is enabled.
@property(nonatomic, strong) NewTabPageCoordinator* ntpCoordinator;

// Provider used to offload SceneStateBrowserAgent usage from BVC.
@property(nonatomic, strong) SafeAreaProvider* safeAreaProvider;

@property(nonatomic, strong) UIPanGestureRecognizer* contentPanGestureRecognizer;

// Declare missing selectors
- (void)updateOverlayContainerOrder;
- (void)bringOverlayContainerToFront:(UIViewController*)containerViewController;
- (UIViewController *)viewControllerToPresent;
- (void)voiceSearchWillAppear;
- (void)voiceSearchWillHide;
- (void)updateBroadcastState;
- (UIView *)viewForWebState:(web::WebState *)webState;
- (void)setLastTapPointFromCommand:(CGPoint)originPoint;
- (void)updateToolbarState;
- (void)dismissPopups;
- (void)updateUIOnTraitChange:(UITraitCollection *)previousTraitCollection;
- (void)showTabStripView:(UIView *)tabStripView;
- (CGRect)ntpFrameForCurrentWebState;
- (void)handleRightToLeftSwipe:(UISwipeGestureRecognizer *)gesture;
- (void)saveContentAreaTapLocation:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateBrowserViewportForFullscreenProgress:(CGFloat)progress;

@end

@implementation BrowserViewController

@synthesize mainContentUIState = _mainContentUIState;
@synthesize logoAnimationControllerOwner = _logoAnimationControllerOwner;

#pragma mark - Object lifecycle

- (instancetype)
    initWithBrowserContainerViewController:
        (BrowserContainerViewController*)browserContainerViewController
                       keyCommandsProvider:
                           (KeyCommandsProvider*)keyCommandsProvider
                              dependencies:(BrowserViewControllerDependencies)
                                               dependencies {
  self = [super initWithNibName:nil bundle:base::apple::FrameworkBundle()];
  if (self) {
    _browserContainerViewController = browserContainerViewController;
    _keyCommandsProvider = keyCommandsProvider;
    _sideSwipeCoordinator = dependencies.sideSwipeCoordinator;
    self.hideToolbars = YES;
    [_sideSwipeCoordinator setSideSwipeUIControllerDelegate:self];
    [_sideSwipeCoordinator setCardSwipeViewDelegate:self];
    _bookmarksCoordinator = dependencies.bookmarksCoordinator;
    self.toolbarAccessoryPresenter = dependencies.toolbarAccessoryPresenter;
    self.ntpCoordinator = dependencies.ntpCoordinator;
    self.popupMenuCoordinator = dependencies.popupMenuCoordinator;
    self.toolbarCoordinator = dependencies.toolbarCoordinator;
    self.tabStripCoordinator = dependencies.tabStripCoordinator;

    self.textZoomHandler = dependencies.textZoomHandler;
    self.helpHandler = dependencies.helpHandler;
    self.popupMenuCommandsHandler = dependencies.popupMenuCommandsHandler;
    self.applicationCommandsHandler = dependencies.applicationCommandsHandler;
    self.findInPageCommandsHandler = dependencies.findInPageCommandsHandler;
    _isOffTheRecord = dependencies.isOffTheRecord;
    _visibilityState = BrowserViewVisibilityState::kNotInViewHierarchy;
    _urlLoadingBrowserAgent = dependencies.urlLoadingBrowserAgent;
    _tabUsageRecorderBrowserAgent = dependencies.tabUsageRecorderBrowserAgent;
    _layoutGuideCenter = dependencies.layoutGuideCenter;
    _webStateList = dependencies.webStateList;
    _voiceSearchController = dependencies.voiceSearchController;
    self.safeAreaProvider = dependencies.safeAreaProvider;
    _pagePlaceholderBrowserAgent = dependencies.pagePlaceholderBrowserAgent;

    self.inNewTabAnimation = NO;
    self.fullscreenController = dependencies.fullscreenController;
    _footerFullscreenProgress = 1.0;

    // Initialize backing ivars for properties
    _mainContentUIState = [[MainContentUIState alloc] init];
    _logoAnimationControllerOwner = nil;
    _lastContentOffset = CGPointZero;

    // When starting the browser with an open tab, it is necessary to reset the
    // clipsToBounds property of the WKWebView's scroll view so the page can bleed
    // behind the toolbar.
    if (self.currentWebState) {
      UIView *webView = self.currentWebState->GetView();
      if ([webView isKindOfClass:[WKWebView class]]) {
        [(WKWebView *)webView scrollView].clipsToBounds = NO;
      }
    }
  }
  return self;
}

- (void)dealloc {
  [self removeObserver:self forKeyPath:@"containerView.frame"];
  if (self.currentWebState) {
    UIView *webView = self.currentWebState->GetView();
    if ([webView isKindOfClass:[WKWebView class]]) {
      [(WKWebView *)webView scrollView].delegate = nil;
      [[(WKWebView *)webView scrollView] removeObserver:self forKeyPath:@"contentSize"];
    }
    if (webView) {
      [webView removeObserver:self forKeyPath:@"frame"];
    }
  }
  DCHECK(_isShutdown) << "-shutdown must be called before dealloc.";
}

#pragma mark - Public Properties

- (UIView*)contentArea {
  return self.browserContainerViewController.view;
}

- (void)setInfobarBannerOverlayContainerViewController:
    (UIViewController*)infobarBannerOverlayContainerViewController {
  if (_infobarBannerOverlayContainerViewController ==
      infobarBannerOverlayContainerViewController) {
    return;
  }

  _infobarBannerOverlayContainerViewController =
      infobarBannerOverlayContainerViewController;
  if (!_infobarBannerOverlayContainerViewController) {
    return;
  }

  DCHECK_EQ(_infobarBannerOverlayContainerViewController.parentViewController,
            self);
  DCHECK_EQ(_infobarBannerOverlayContainerViewController.view.superview,
            self.view);
  [self updateOverlayContainerOrder];
}

- (void)setInfobarModalOverlayContainerViewController:
    (UIViewController*)infobarModalOverlayContainerViewController {
  if (_infobarModalOverlayContainerViewController ==
      infobarModalOverlayContainerViewController) {
    return;
  }

  _infobarModalOverlayContainerViewController =
      infobarModalOverlayContainerViewController;
  if (!_infobarModalOverlayContainerViewController) {
    return;
  }

  DCHECK_EQ(_infobarModalOverlayContainerViewController.parentViewController,
            self);
  DCHECK_EQ(_infobarModalOverlayContainerViewController.view.superview,
            self.view);
  [self updateOverlayContainerOrder];
}

#pragma mark - Private Properties

- (void)setVisibilityState:(BrowserViewVisibilityState)state {
  if (_visibilityState == state) {
    return;
  }
  BrowserViewVisibilityState previousState = _visibilityState;
  _visibilityState = state;
  [self.browserViewVisibilityAudience
      browserViewDidTransitionToVisibilityState:state
                                      fromState:previousState];
  [self updateBroadcastState];
  self.contentArea.accessibilityElementsHidden =
      state == BrowserViewVisibilityState::kCoveredByOmniboxPopup ||
      state == BrowserViewVisibilityState::kCoveredByVoiceSearch;
}

- (void)setBroadcasting:(BOOL)broadcasting {
  if (_broadcasting == broadcasting) {
    return;
  }
  _broadcasting = broadcasting;

  ChromeBroadcaster* broadcaster = self.fullscreenController->broadcaster();
  if (_broadcasting) {
    _toolbarsSize = [[ToolbarsSize alloc] init];
    // Must update _toolbarsSize with current toolbar height state before
    // starting broadcasting.
    [self updateToolbarState];
    self.fullscreenController->SetToolbarsSize(_toolbarsSize);

    StartBroadcastingToolbarsSize(_toolbarsSize, broadcaster);
    _mainContentUIUpdater = [[MainContentUIStateUpdater alloc]
        initWithState:_mainContentUIState];
    _webMainContentUIForwarder = [[WebScrollViewMainContentUIForwarder alloc]
        initWithUpdater:_mainContentUIUpdater
           webStateList:self.webStateList];
    StartBroadcastingMainContentUI(self, broadcaster);

    _fullscreenUIUpdater =
        std::make_unique<FullscreenUIUpdater>(self.fullscreenController, self);
    [self updateForFullscreenProgress:self.fullscreenController->GetProgress()];
  } else {
    StopBroadcastingToolbarsSize(broadcaster);
    StopBroadcastingMainContentUI(broadcaster);
    _mainContentUIUpdater = nil;
    _toolbarsSize = nil;
    [_webMainContentUIForwarder disconnect];
    _webMainContentUIForwarder = nil;

    _fullscreenUIUpdater = nullptr;
  }
}

- (void)setInNewTabAnimation:(BOOL)inNewTabAnimation {
  if (_inNewTabAnimation == inNewTabAnimation) {
    return;
  }
  _inNewTabAnimation = inNewTabAnimation;
  [self updateBroadcastState];
}

- (void)setHideStatusBar:(BOOL)hideStatusBar {
  if (_hideStatusBar == hideStatusBar) {
    return;
  }
  _hideStatusBar = hideStatusBar;
  [self setNeedsStatusBarAppearanceUpdate];
}

- (NSArray<HeaderDefinition*>*)headerViews {
  NSMutableArray<HeaderDefinition*>* results = [[NSMutableArray alloc] init];
  if (![self isViewLoaded]) {
    return results;
  }

  if (!IsRegularXRegularSizeClass(self)) {
    if (self.toolbarCoordinator.primaryToolbarViewController.view && !self.hideToolbars) {
      [results
          addObject:[HeaderDefinition
                        definitionWithView:self.toolbarCoordinator
                                               .primaryToolbarViewController
                                               .view
                           headerBehaviour:Hideable]];
    }
  } else {
    if (self.tabStripView) {
      [results addObject:[HeaderDefinition definitionWithView:self.tabStripView
                                              headerBehaviour:Hideable]];
    }
    if (self.toolbarCoordinator.primaryToolbarViewController.view && !self.hideToolbars) {
      [results
          addObject:[HeaderDefinition
                        definitionWithView:self.toolbarCoordinator
                                               .primaryToolbarViewController
                                               .view
                           headerBehaviour:Hideable]];
    }
    if (self.toolbarAccessoryPresenter.isPresenting) {
      [results addObject:[HeaderDefinition
                             definitionWithView:self.toolbarAccessoryPresenter
                                                    .backgroundView
                                headerBehaviour:Overlap]];
    }
  }
  return [results copy];
}

// Returns the safeAreaInsets of the root window for self.view. In some cases,
// the self.view.safeAreaInsets are cleared when the view is unattached (for
// example on the incognito BVC when the normal BVC is the one active or vice
// versa). Attached or unattached, going to the window through the SceneState
// for the self.browser solves both issues.
- (UIEdgeInsets)rootSafeAreaInsets {
  if (_isShutdown) {
    return UIEdgeInsetsZero;
  }
  UIEdgeInsets safeArea = self.safeAreaProvider.safeArea;
  NSLog(@"rootSafeAreaInsets: %@", NSStringFromUIEdgeInsets(safeArea));
  return UIEdgeInsetsEqualToEdgeInsets(safeArea, UIEdgeInsetsZero)
             ? self.view.safeAreaInsets
             : safeArea;
}

- (CGFloat)headerOffset {
  CGFloat headerOffset = self.rootSafeAreaInsets.top;
  return IsRegularXRegularSizeClass(self) ? headerOffset : 0.0;
}

- (CGFloat)headerHeight {
  NSArray<HeaderDefinition*>* views = [self headerViews];

  CGFloat height = self.headerOffset;
  for (HeaderDefinition* header in views) {
    if (header.view && header.behaviour == Hideable) {
      height += CGRectGetHeight([header.view frame]);
    }
  }

  CGFloat statusBarOffset = 0;
  return height - statusBarOffset;
}

- (UIView*)viewForCurrentWebState {
  UIView *view = [self viewForWebState:self.currentWebState];
  if (!view) {
    NSLog(@"viewForCurrentWebState: No view available, creating fallback");
    view = [[WKWebView alloc] initWithFrame:self.contentArea.bounds configuration:[self webViewConfiguration]];
    view.backgroundColor = [UIColor lightGrayColor];
  }
  return view;
}

- (WKWebViewConfiguration *)webViewConfiguration {
  WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];

  // Inject CSS to ensure full viewport height and robust fixed element positioning
  NSString *cssSource = @"html, body {"
                       @"  height: 100vh !important;"
                       @"  min-height: 100vh !important;"
                       @"  margin: 0 !important;"
                       @"  padding: 0 !important;"
                       @"  overflow-x: hidden !important;"
                       @"  overflow-y: auto !important;"
                       @"  width: 100% !important;"
                       @"  -webkit-overflow-scrolling: touch !important;"
                       @"  overscroll-behavior: none !important;"
                       @"  box-sizing: border-box !important;"
                       @"}"
                       @"header, [role='banner'], [id*='header' i], [class*='header' i], nav, [role='navigation'], [id*='nav' i], [class*='nav' i], [style*='position: fixed; top' i], [style*='position: sticky; top' i], .fixed-top, .sticky-top {"
                       @"  position: fixed !important;"
                       @"  top: 0 !important;"
                       @"  width: 100% !important;"
                       @"  max-width: 100% !important;"
                       @"  margin: 0 !important;"
                       @"  padding: 0 !important;"
                       @"  z-index: 10000 !important;"
                       @"  transform: none !important;"
                       @"  -webkit-transform: none !important;"
                       @"  inset-block-start: 0 !important;"
                       @"  left: 0 !important;"
                       @"  right: 0 !important;"
                       @"  box-sizing: border-box !important;"
                       @"}"
                       @"footer, [role='contentinfo'], [id*='footer' i], [class*='footer' i], [style*='position: fixed; bottom' i], [style*='position: sticky; bottom' i], .fixed-bottom, .sticky-bottom {"
                       @"  position: fixed !important;"
                       @"  bottom: 0 !important;"
                       @"  width: 100% !important;"
                       @"  max-width: 100% !important;"
                       @"  margin: 0 !important;"
                       @"  padding: 0 !important;"
                       @"  z-index: 10000 !important;"
                       @"  transform: none !important;"
                       @"  -webkit-transform: none !important;"
                       @"  inset-block-end: 0 !important;"
                       @"  left: 0 !important;"
                       @"  right: 0 !important;"
                       @"  box-sizing: border-box !important;"
                       @"}"
                       @"@supports (padding: env(safe-area-inset-bottom)) {"
                       @"  html, body, header, footer {"
                       @"    padding-top: env(safe-area-inset-top) !important;"
                       @"    padding-bottom: env(safe-area-inset-bottom) !important;"
                       @"    margin: 0 !important;"
                       @"  }"
                       @"}";
  WKUserScript *cssScriptStart = [[WKUserScript alloc] initWithSource:[NSString stringWithFormat:@"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style);", cssSource]
                                                       injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                    forMainFrameOnly:YES];
  WKUserScript *cssScriptEnd = [[WKUserScript alloc] initWithSource:[NSString stringWithFormat:@"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style);", cssSource]
                                                     injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                  forMainFrameOnly:YES];
  [configuration.userContentController addUserScript:cssScriptStart];
  [configuration.userContentController addUserScript:cssScriptEnd];

  // Inject JavaScript to enforce fixed header/footer positioning and monitor DOM changes
  NSString *scriptSource = @"(function() {"
                          @"  function enforceFixedElements(isTouchEvent) {"
                          @"    var vh = Math.max(window.innerHeight, document.documentElement.clientHeight);"
                          @"    document.documentElement.style.height = vh + 'px';"
                          @"    document.body.style.height = vh + 'px';"
                          @"    document.documentElement.style.overflowY = 'auto';"
                          @"    document.body.style.overflowY = 'auto';"
                          @"    var headers = document.querySelectorAll('header, [role=\"banner\"], [id*=\"header\" i], [class*=\"header\" i], nav, [role=\"navigation\"], [id*=\"nav\" i], [class*=\"nav\" i], [style*=\"position: fixed; top\" i], [style*=\"position: sticky; top\" i], .fixed-top, .sticky-top');"
                          @"    headers.forEach(el => {"
                          @"      var style = window.getComputedStyle(el);"
                          @"      el.style.position = 'fixed';"
                          @"      el.style.top = '0';"
                          @"      el.style.width = '100%';"
                          @"      el.style.maxWidth = '100%';"
                          @"      el.style.zIndex = '10000';"
                          @"      el.style.transform = 'none';"
                          @"      el.style.webkitTransform = 'none';"
                          @"      el.style.insetBlockStart = '0';"
                          @"      el.style.left = '0';"
                          @"      el.style.right = '0';"
                          @"      el.style.margin = '0';"
                          @"      el.style.padding = '0';"
                          @"      el.style.boxSizing = 'border-box';"
                          @"      console.log('Fixed header: ', el.tagName, el.id, el.className, 'top: ' + style.top, 'position: ' + style.position, 'offsetTop: ' + el.offsetTop, 'scrollY: ' + window.scrollY, 'time: ' + Date.now(), 'isTouchEvent: ' + isTouchEvent, 'computedStyle: ' + JSON.stringify({top: style.top, bottom: style.bottom, transform: style.transform, left: style.left, right: style.right}));"
                          @"    });"
                          @"    var footers = document.querySelectorAll('footer, [role=\"contentinfo\"], [id*=\"footer\" i], [class*=\"footer\" i], [style*=\"position: fixed; bottom\" i], [style*=\"position: sticky; bottom\" i], .fixed-bottom, .sticky-bottom');"
                          @"    footers.forEach(el => {"
                          @"      var style = window.getComputedStyle(el);"
                          @"      el.style.position = 'fixed';"
                          @"      el.style.bottom = '0';"
                          @"      el.style.width = '100%';"
                          @"      el.style.maxWidth = '100%';"
                          @"      el.style.zIndex = '10000';"
                          @"      el.style.transform = 'none';"
                          @"      el.style.webkitTransform = 'none';"
                          @"      el.style.insetBlockEnd = '0';"
                          @"      el.style.left = '0';"
                          @"      el.style.right = '0';"
                          @"      el.style.margin = '0';"
                          @"      el.style.padding = '0';"
                          @"      el.style.boxSizing = 'border-box';"
                          @"      console.log('Fixed footer: ', el.tagName, el.id, el.className, 'bottom: ' + style.bottom, 'position: ' + style.position, 'offsetTop: ' + el.offsetTop, 'scrollY: ' + window.scrollY, 'time: ' + Date.now(), 'isTouchEvent: ' + isTouchEvent, 'computedStyle: ' + JSON.stringify({top: style.top, bottom: style.bottom, transform: style.transform, left: style.left, right: style.right}));"
                          @"    });"
                          @"    if (window.scrollY < 0 || window.scrollY > (document.body.scrollHeight - vh)) {"
                          @"      window.scrollTo(0, Math.min(Math.max(window.scrollY, 0), document.body.scrollHeight - vh));"
                          @"      console.log('Corrected overscroll, scrollY: ' + window.scrollY, 'time: ' + Date.now());"
                          @"    }"
                          @"    console.log('Enforced fixed elements, viewport height: ' + vh, 'scrollY: ' + window.scrollY, 'clientHeight: ' + document.documentElement.clientHeight, 'time: ' + Date.now(), 'isTouchEvent: ' + isTouchEvent);"
                          @"  }"
                          @"  function monitorDOMChanges() {"
                          @"    const observer = new MutationObserver((mutations) => {"
                          @"      mutations.forEach((mutation) => {"
                          @"        if (mutation.addedNodes.length || mutation.removedNodes.length) {"
                          @"          enforceFixedElements(false);"
                          @"        }"
                          @"      });"
                          @"    });"
                          @"    observer.observe(document.body, { childList: true, subtree: true });"
                          @"    return observer;"
                          @"  }"
                          @"  enforceFixedElements(false);"
                          @"  const observer = monitorDOMChanges();"
                          @"  window.addEventListener('touchstart', () => enforceFixedElements(true));"
                          @"  window.addEventListener('touchmove', () => enforceFixedElements(true));"
                          @"  window.addEventListener('resize', () => enforceFixedElements(false));"
                          @"  window.addEventListener('load', () => enforceFixedElements(false));"
                          @"  window.addEventListener('scroll', () => enforceFixedElements(true));"
                          @"  if (!document.querySelector('meta[name=viewport]')) {"
                          @"    let meta = document.createElement('meta');"
                          @"    meta.name = 'viewport';"
                          @"    meta.content = 'width=device-width, height=device-height, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';"
                          @"    document.head.appendChild(meta);"
                          @"    console.log('Added viewport meta tag');"
                          @"  }"
                          @"})();";
  WKUserScript *stretchScript = [[WKUserScript alloc] initWithSource:scriptSource
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                   forMainFrameOnly:YES];
  [configuration.userContentController addUserScript:stretchScript];
  return configuration;
}

- (void)updateWebStateVisibility:(BOOL)isVisible {
  if (self.currentWebState) {
    if (isVisible) {
      self.currentWebState->WasShown();
    } else {
      self.currentWebState->WasHidden();
    }
  }
}

- (web::WebState*)currentWebState {
  return self.webStateList ? _webStateList->GetActiveWebState() : nullptr;
}

- (WebStateList*)webStateList {
  WebStateList* webStateList = _webStateList.get();
  return webStateList ? webStateList : nullptr;
}

- (UIView*)containerView {
  return _containerView;
}

#pragma mark - Public methods

- (void)shieldWasTapped:(id)sender {
  [self.omniboxCommandsHandler cancelOmniboxEdit];
}

- (void)openNewTabFromOriginPoint:(CGPoint)originPoint
                     focusOmnibox:(BOOL)focusOmnibox
                    inheritOpener:(BOOL)inheritOpener {
  const BOOL offTheRecord = _isOffTheRecord;
  ProceduralBlock oldForegroundTabWasAddedCompletionBlock =
      self.foregroundTabWasAddedCompletionBlock;
  id<OmniboxCommands> omniboxCommandHandler = self.omniboxCommandsHandler;
  self.foregroundTabWasAddedCompletionBlock = ^{
    if (oldForegroundTabWasAddedCompletionBlock) {
      oldForegroundTabWasAddedCompletionBlock();
    }
    if (focusOmnibox) {
      [omniboxCommandHandler focusOmnibox];
    }
  };

  [self setLastTapPointFromCommand:originPoint];

  // In most cases, we want to take a snapshot of the current tab before opening
  // a new tab. However, if the current tab is not fully visible (did not finish
  // `-viewDidAppear:`, then we must not take an empty snapshot, replacing an
  // existing snapshot for the tab. This can happen when a new regular tab is
  // opened from an incognito tab. A different BVC is displayed, which may not
  // have enough time to finish appearing before a snapshot is requested.
  if (self.currentWebState && self.visibilityState == BrowserViewVisibilityState::kVisible) {
    SnapshotTabHelper::FromWebState(self.currentWebState)
        ->UpdateSnapshotWithCallback(nil);
  }

  UrlLoadParams params = UrlLoadParams::InNewTab(GURL(kChromeUINewTabURL));
  params.web_params.transition_type = ui::PAGE_TRANSITION_TYPED;
  params.in_incognito = offTheRecord;
  params.inherit_opener = inheritOpener;
  _urlLoadingBrowserAgent->Load(params);
}

- (void)appendTabAddedCompletion:(ProceduralBlock)tabAddedCompletion {
  if (tabAddedCompletion) {
    if (self.foregroundTabWasAddedCompletionBlock) {
      ProceduralBlock oldForegroundTabWasAddedCompletionBlock =
          self.foregroundTabWasAddedCompletionBlock;
      self.foregroundTabWasAddedCompletionBlock = ^{
        oldForegroundTabWasAddedCompletionBlock();
        tabAddedCompletion();
      };
    } else {
      self.foregroundTabWasAddedCompletionBlock = tabAddedCompletion;
    }
  }
}

- (void)startVoiceSearch {
  // Delay Voice Search until new tab animations have finished.
  if (self.inNewTabAnimation) {
    _startVoiceSearchAfterNewTabAnimation = YES;
    return;
  }

  // Keyboard shouldn't overlay the ecoutez window, so dismiss find in page and
  // dismiss the keyboard.
  [self.findInPageCommandsHandler closeFindInPage];
  [self.textZoomHandler closeTextZoom];
  [self.viewForCurrentWebState endEditing:NO];

  // Present voice search.
  [_voiceSearchController
      startRecognitionOnViewController:self
                              webState:self.currentWebState];
  [self.omniboxCommandsHandler cancelOmniboxEdit];
}

#pragma mark - browser_view_controller+private.h

- (void)setActive:(BOOL)active {
  if (_active == active) {
    return;
  }
  _active = active;

  [self updateBroadcastState];

  if (active) {
    // Force loading the view in case it was not loaded yet.
    [self loadViewIfNeeded];
    _pagePlaceholderBrowserAgent->AddPagePlaceholder();
    // Only call displayTabView if there is a valid web state
    if (self.currentWebState && self.viewForCurrentWebState) {
      [self displayTabView];
    } else {
      NSLog(@"setActive: Skipping displayTabView due to null currentWebState");
    }
  }
  [self setNeedsStatusBarAppearanceUpdate];
}

// TODO(crbug.com/40842434): Federate ClearPresentedState.
- (void)clearPresentedStateWithCompletion:(ProceduralBlock)completion
                           dismissOmnibox:(BOOL)dismissOmnibox {
  [_bookmarksCoordinator dismissBookmarkModalControllerAnimated:NO];
  [_bookmarksCoordinator dismissSnackbar];
  if (dismissOmnibox) {
    [self.omniboxCommandsHandler cancelOmniboxEdit];
  }
  [self.helpHandler hideAllHelpBubbles];
  [_voiceSearchController dismissMicPermissionHelp];
  [self.findInPageCommandsHandler closeFindInPage];
  [self.textZoomHandler closeTextZoom];

  [self.popupMenuCommandsHandler dismissPopupMenuAnimated:NO];

  if (self.presentedViewController) {
    // Dismisses any other modal controllers that may be present, e.g. Recent
    // Tabs.
    //
    // Note that currently, some controllers like the bookmark ones were already
    // dismissed (in this example in -dismissBookmarkModalControllerAnimated:),
    // but are still reported as the presentedViewController. Calling
    // `dismissViewControllerAnimated:completion:` again would dismiss the BVC
    // itself, so instead check the value of `self.dismissingModal` and only
    // call dismiss if one of the above calls has not already triggered a
    // dismissal.
    //
    // To ensure the completion is called, nil is passed to the call to dismiss,
    // and the completion is called explicitly below.
    if (!self.dismissingModal) {
      [self dismissViewControllerAnimated:NO completion:nil];
    }
    // Dismissed controllers will be so after a delay. Queue the completion
    // callback after that.
    if (completion) {
      base::SequencedTaskRunner::GetCurrentDefault()->PostDelayedTask(
          FROM_HERE, base::BindOnce(completion), base::Milliseconds(400));
    }
  } else if (completion) {
    // If no view controllers are presented, we should be ok with dispatching
    // the completion block directly.
    base::SequencedTaskRunner::GetCurrentDefault()->PostTask(
        FROM_HERE, base::BindOnce(completion));
  }
}

- (void)animateOpenBackgroundTabFromOriginPoint:(CGPoint)originPoint
                                     completion:(void (^)())completion {
  if (IsRegularXRegularSizeClass(self) ||
      CGPointEqualToPoint(originPoint, CGPointZero)) {
    completion();
  } else {
    self.inNewTabAnimation = YES;
    // Exit fullscreen if needed.
    self.fullscreenController->ExitFullscreen(
        FullscreenExitReason::kForcedByCode);
    const CGFloat kAnimatedViewSize = 50;
    BackgroundTabAnimationView* animatedView =
        [[BackgroundTabAnimationView alloc]
            initWithFrame:CGRectMake(0, 0, kAnimatedViewSize, kAnimatedViewSize)
                incognito:_isOffTheRecord];
    animatedView.layoutGuideCenter = _layoutGuideCenter;
    __weak UIView* weakAnimatedView = animatedView;
    auto completionBlock = ^() {
      self.inNewTabAnimation = NO;
      [weakAnimatedView removeFromSuperview];
      completion();
    };
    [self.view addSubview:animatedView];
    [animatedView animateFrom:originPoint toTabGridButtonWithCompletion:completionBlock];
  }
}

- (void)shutdown {
  DCHECK(!_isShutdown);
  _isShutdown = YES;

  // Disconnect child coordinators.
  [self.tabStripCoordinator stop];
  self.tabStripCoordinator = nil;
  self.tabStripView = nil;

  [self.contentArea removeGestureRecognizer:self.contentAreaGestureRecognizer];

  [self.toolbarCoordinator stop];
  self.toolbarCoordinator = nil;
  _sideSwipeCoordinator = nil;
  [_voiceSearchController disconnect];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  _bookmarksCoordinator = nil;
}

#pragma mark - NSObject

- (BOOL)accessibilityPerformEscape {
  [self dismissPopups];
  return YES;
}

#pragma mark - UIResponder

// To always be able to register key commands, the VC must be able to become
// first responder.
- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (UIResponder*)nextResponder {
  UIResponder* nextResponder = [super nextResponder];
  if (_keyCommandsProvider && [self shouldSupportKeyCommands]) {
    [_keyCommandsProvider respondBetweenViewController:self
                                          andResponder:nextResponder];
    return _keyCommandsProvider;
  } else {
    return nextResponder;
  }
}

#pragma mark - UIResponder Helpers

// Whether the BVC should declare keyboard commands.
// Since `-keyCommands` can be called by UIKit at any time, no assumptions
// about the state of `self` can be made; accordingly, if there's anything
// not initialized (or being torn down), this method should return NO.
- (BOOL)shouldSupportKeyCommands {
  if (_isShutdown) {
    return NO;
  }

  if (self.presentedViewController) {
    return NO;
  }

  return self.visibilityState == BrowserViewVisibilityState::kVisible;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  [self registerNotifications];

  CGRect initialViewsRect = self.view.bounds;
  UIViewAutoresizing initialViewAutoresizing =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  self.contentArea.frame = initialViewsRect;
  self.contentArea.translatesAutoresizingMaskIntoConstraints = YES;
  [NSLayoutConstraint deactivateConstraints:self.contentArea.constraints];

  self.typingShield = [[UIButton alloc] initWithFrame:initialViewsRect];
  self.typingShield.hidden = YES;
  self.typingShield.autoresizingMask = initialViewAutoresizing;
  self.typingShield.accessibilityIdentifier = @"Typing Shield";
  self.typingShield.accessibilityLabel = l10n_util::GetNSString(IDS_CANCEL);
  // Ensure typing shield doesn’t block touches when hidden
  self.typingShield.userInteractionEnabled = NO;
  if (ui::GetDeviceFormFactor() == ui::DEVICE_FORM_FACTOR_TABLET) {
    self.typingShield.backgroundColor =
        [UIColor colorNamed:kOmniboxPopoutOverlayColor];
  }
  [self.typingShield addTarget:self
                        action:@selector(shieldWasTapped:)
              forControlEvents:UIControlEventTouchUpInside];
  self.view.autoresizingMask = initialViewAutoresizing;

  [self addChildViewController:self.browserContainerViewController];
  [self.view addSubview:self.contentArea];
  [self.browserContainerViewController didMoveToParentViewController:self];
  [self.view addSubview:self.typingShield];
  [super viewDidLoad];

  [self installFakeStatusBar];

  [self buildToolbarAndTabStrip];
  [self setUpViewLayout:YES];
  [self addConstraintsToToolbar];

  [_sideSwipeCoordinator addHorizontalGesturesToView:self.view];

  // Add custom right-to-left swipe gesture recognizer
  UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(handleRightToLeftSwipe:)];
  swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
  swipeGesture.delegate = self;
  [self.view addGestureRecognizer:swipeGesture];

  // Add a tap gesture recognizer to save the last tap location for the source
  // location of the new tab animation.
  self.contentAreaGestureRecognizer = [[UITapGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(saveContentAreaTapLocation:)];
  [self.contentAreaGestureRecognizer setDelegate:self];
  [self.contentAreaGestureRecognizer setCancelsTouchesInView:NO];
  [self.contentArea addGestureRecognizer:self.contentAreaGestureRecognizer];

  // Add a pan gesture recognizer to log swipe gestures
  self.contentPanGestureRecognizer = [[UIPanGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(handleContentPanGesture:)];
  self.contentPanGestureRecognizer.delegate = self;
  [self.contentArea addGestureRecognizer:self.contentPanGestureRecognizer];

  self.view.backgroundColor = [UIColor blueColor];
  self.contentArea.backgroundColor = [UIColor greenColor];
  if (_isOffTheRecord) {
    self.view.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
  }

  // Set up KVO for container view frame
  [self addObserver:self
         forKeyPath:@"containerView.frame"
            options:NSKeyValueObservingOptionNew
            context:nil];

  if (@available(iOS 17, *)) {
    NSArray<UITrait>* traits = TraitCollectionSetForTraits(nil);
    __weak __typeof(self) weakSelf = self;
    UITraitChangeHandler handler = ^(id<UITraitEnvironment> traitEnvironment,
                                     UITraitCollection* previousCollection) {
      [weakSelf updateUIOnTraitChange:previousCollection];
    };
    [self registerForTraitChanges:traits withHandler:handler];
  }
}

- (void)handleContentPanGesture:(UIPanGestureRecognizer *)gesture {
  if (gesture.state == UIGestureRecognizerStateChanged) {
    CGPoint translation = [gesture translationInView:self.contentArea];
    NSString *swipeDirection = translation.y > 0 ? @"Down" : @"Up";
    NSLog(@"Swipe detected: %@", swipeDirection);
    NSLog(@"Translation: %@", NSStringFromCGPoint(translation));

    // Log and update scroll view state if a web view is present
    if (self.currentWebState) {
      UIView *webView = self.currentWebState->GetView();
      if ([webView isKindOfClass:[WKWebView class]]) {
        UIScrollView *scrollView = [(WKWebView *)webView scrollView];
        NSLog(@"ScrollView contentOffset: %@", NSStringFromCGPoint(scrollView.contentOffset));
        NSLog(@"ScrollView contentSize: %@", NSStringFromCGSize(scrollView.contentSize));
        NSLog(@"ScrollView scrollEnabled: %d", scrollView.scrollEnabled);
        _lastContentOffset = scrollView.contentOffset; // Update last known offset
        [self configureScrollView:scrollView]; // Ensure consistent scroll view settings
      }
    }
  } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
    // Reset web view frame after gesture ends to prevent drift
    if (self.currentWebState && !self.ntpCoordinator.isNTPActiveForCurrentWebState) {
      UIView *webView = self.viewForCurrentWebState;
      if (webView && self.containerView) {
        CGFloat topInset = self.rootSafeAreaInsets.top + kTopPadding;
        CGRect viewFrame = self.contentArea.bounds;
        viewFrame.origin.y = topInset;
        viewFrame.size.height = self.contentArea.bounds.size.height - topInset;

        self.containerView.frame = viewFrame;
        self.containerView.bounds = viewFrame;
        webView.frame = self.containerView.bounds;
        webView.bounds = self.containerView.bounds;

        if ([webView isKindOfClass:[WKWebView class]]) {
          UIScrollView *scrollView = [(WKWebView *)webView scrollView];
          [self configureScrollView:scrollView]; // Reapply scroll view settings
          scrollView.contentOffset = _lastContentOffset; // Restore offset
        }

        NSLog(@"handleContentPanGesture: Reset container view frame: %@", NSStringFromCGRect(viewFrame));
        NSLog(@"handleContentPanGesture: Web view frame: %@", NSStringFromCGRect(webView.frame));
      }
    }
  }
}

- (void)viewSafeAreaInsetsDidChange {
  [super viewSafeAreaInsetsDidChange];
  [self setUpViewLayout:NO];
  // Update the heights of the toolbars to account for the new insets.
  self.primaryToolbarHeightConstraint.constant =
      [self primaryToolbarHeightWithInset];
  self.secondaryToolbarHeightConstraint.constant =
      [self secondaryToolbarHeightWithInset];

  // Update the tab strip placement.
  if (self.tabStripView) {
    [self showTabStripView:self.tabStripView];
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.primaryToolbarHeightConstraint.constant = [self primaryToolbarHeightWithInset];

  // Adjust web view for non-NTP pages, respecting toolbars
  if (self.currentWebState && !self.ntpCoordinator.isNTPActiveForCurrentWebState) {
    // Start web view below Dynamic Island/status bar + padding
    CGFloat topInset = self.rootSafeAreaInsets.top + kTopPadding;

    // Calculate frame to span full content area height starting at topInset
    CGRect viewFrame = self.contentArea.bounds;
    viewFrame.origin.y = topInset;
    viewFrame.size.height = self.contentArea.bounds.size.height - topInset;

    UIView *webView = self.viewForCurrentWebState;

    // Wrap the web view in a container to enforce size
    if (!self.containerView || self.containerView != webView.superview) {
      self.containerView = [[UIView alloc] initWithFrame:viewFrame];
      self.containerView.clipsToBounds = NO; // Allow content to extend for scrolling
      [webView removeFromSuperview];
      [self.containerView addSubview:webView];
      self.browserContainerViewController.contentView = self.containerView;
      // Add KVO for web view frame
      if (webView) {
        [webView addObserver:self
                  forKeyPath:@"frame"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
      }
    }

    // Store current contentOffset if available
    CGPoint currentOffset = _lastContentOffset;
    if ([webView isKindOfClass:[WKWebView class]]) {
      currentOffset = [(WKWebView *)webView scrollView].contentOffset;
    }

    // Always update frame to enforce correct positioning
    self.containerView.translatesAutoresizingMaskIntoConstraints = YES;
    [NSLayoutConstraint deactivateConstraints:self.containerView.constraints];
    webView.translatesAutoresizingMaskIntoConstraints = YES;
    [NSLayoutConstraint deactivateConstraints:webView.constraints];
    [webView.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
      subview.translatesAutoresizingMaskIntoConstraints = YES;
      [NSLayoutConstraint deactivateConstraints:subview.constraints];
    }];
    self.containerView.frame = viewFrame;
    self.containerView.bounds = viewFrame;
    webView.frame = self.containerView.bounds;
    webView.bounds = self.containerView.bounds;

    // Adjust scroll view properties
    if ([webView isKindOfClass:[WKWebView class]]) {
      UIScrollView *scrollView = [(WKWebView *)webView scrollView];
      scrollView.contentInset = UIEdgeInsetsZero;
      scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
      scrollView.clipsToBounds = NO;
      scrollView.scrollEnabled = YES;
      scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
      scrollView.bounces = NO;
      scrollView.alwaysBounceVertical = NO;
      scrollView.delegate = self;
      // Enforce contentSize to at least match frame height
      if (scrollView.contentSize.height < viewFrame.size.height) {
        scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, viewFrame.size.height);
        NSLog(@"viewDidLayoutSubviews: Forced contentSize height to %f", viewFrame.size.height);
      }
      // Restore contentOffset to prevent jump
      scrollView.contentOffset = currentOffset;
      // Add KVO for scroll view contentSize
      [scrollView addObserver:self
                   forKeyPath:@"contentSize"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    }

    NSLog(@"viewDidLayoutSubviews: Set container view frame: %@", NSStringFromCGRect(viewFrame));
    NSLog(@"viewDidLayoutSubviews: Web view frame: %@", NSStringFromCGRect(webView.frame));
    NSLog(@"viewDidLayoutSubviews: Restored contentOffset: %@", NSStringFromCGPoint(currentOffset));
    NSLog(@"viewDidLayoutSubviews: Web view constraints: %@", webView.constraints);
    NSLog(@"viewDidLayoutSubviews: Container view superview: %@", self.containerView.superview);
    dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"viewDidLayoutSubviews: Container view frame after layout: %@", NSStringFromCGRect(self.containerView.frame));
      NSLog(@"viewDidLayoutSubviews: Web view frame after layout: %@", NSStringFromCGRect(webView.frame));
    });
  }

  if (self.ntpCoordinator.isNTPActiveForCurrentWebState && self.webUsageEnabled) {
    UIViewController *ntpViewController = self.ntpCoordinator.viewController;
    ntpViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
    [NSLayoutConstraint deactivateConstraints:ntpViewController.view.constraints];
    ntpViewController.view.frame = [self ntpFrameForCurrentWebState];
    ntpViewController.view.clipsToBounds = NO; // Prevent clipping for NTP
    NSLog(@"viewDidLayoutSubviews: NTP view controller frame: %@", NSStringFromCGRect(ntpViewController.view.frame));
    NSLog(@"viewDidLayoutSubviews: NTP view hierarchy: %@", ntpViewController.view.subviews);
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.visibilityState = BrowserViewVisibilityState::kVisible;
  [self updateBroadcastState];
  NSLog(@"viewDidAppear: Calling displayTabView");
  if (!self.currentWebState) {
    NSLog(@"viewDidAppear: No active web state, opening new tab");
    [self openNewTabFromOriginPoint:CGPointZero focusOmnibox:NO inheritOpener:NO];
  }
  [self displayTabView];

  // If there is no first responder, try to make the webview the first
  // responder to have it answer keyboard commands (e.g. space bar to scroll
  // and respond to gamepad controllers). The WKContentView must be the first
  // responder before (or very shortly after) a load starts in order for
  // gamepads to work. (Ref: crbug.com/325307469)
  web::WebState* activeWebState = self.currentWebState;
  if (activeWebState && !GetFirstResponder()) {
    NewTabPageTabHelper* NTPHelper =
        NewTabPageTabHelper::FromWebState(activeWebState);
    if (!NTPHelper || !NTPHelper->IsActive()) {
      UIView *webView = activeWebState->GetView();
      if ([webView isKindOfClass:[WKWebView class]]) {
        [webView becomeFirstResponder];
      }
    }
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  self.visibilityState = BrowserViewVisibilityState::kAppearing;

  // If the controller is suspended, or has been paged out due to low memory,
  // updating the view will be handled when it's displayed again.
  if (!self.webUsageEnabled || !self.contentArea) {
    return;
  }
  // Update the displayed view (if any; the switcher may not have created
  // one yet) in case it changed while showing the switcher.
  if (self.currentWebState && self.viewForCurrentWebState) {
    [self displayTabView];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  self.visibilityState = BrowserViewVisibilityState::kNotInViewHierarchy;
  [self updateBroadcastState];
  web::WebState* activeWebState = self.currentWebState;
  if (activeWebState) {
    [self updateWebStateVisibility:NO];
    if (!self.presentedViewController) {
      activeWebState->SetKeepRenderProcessAlive(false);
    }
  }

  [_bookmarksCoordinator dismissSnackbar];
  [super viewWillDisappear:animated];
}

- (BOOL)prefersStatusBarHidden {
  return self.hideStatusBar || [super prefersStatusBarHidden];
}

// Called when in the foreground and the OS needs more memory. Release as much
// as possible.
- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];

  if (![self isViewLoaded]) {
    self.typingShield = nil;
    _voiceSearchController.dispatcher = nil;
    [self.toolbarCoordinator stop];
    self.toolbarCoordinator = nil;
    _toolbarsSize = nil;
    [self.tabStripCoordinator stop];
    self.tabStripCoordinator = nil;
    self.tabStripView = nil;
    [_sideSwipeCoordinator stop];
    _sideSwipeCoordinator = nil;
  }
}

#if !defined(__IPHONE_17_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_17_0
- (void)traitCollectionDidChange:(UITraitCollection*)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];
  if (@available(iOS 17, *)) {
    return;
  }
  [self updateUIOnTraitChange:previousTraitCollection];
}
#endif

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:
           (id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

  // After `-shutdown` is called, browser is invalid and will cause a crash.
  if (_isShutdown) {
    return;
  }

  // TODO(crbug.com/40432185): Support size changes for all popups and modal
  // dialogs.
  [self.helpHandler hideAllHelpBubbles];
  if (!IsNewOverflowMenuEnabled()) {
    [self.popupMenuCommandsHandler dismissPopupMenuAnimated:NO];
  }

  __weak BrowserViewController* weakSelf = self;

  [coordinator
      animateAlongsideTransition:^(
          id<UIViewControllerTransitionCoordinatorContext>) {
        [weakSelf animateTransition];
      }
                      completion:nil];

  crash_keys::SetCurrentOrientation(GetInterfaceOrientation(),
                                    [[UIDevice currentDevice] orientation]);
}

- (void)animateTransition {
  // Force updates of the toolbars' size as the toolbar height might
  // change on rotation.
  [self updateToolbarState];
  // Resize horizontal viewport if Smooth Scrolling is on.
  if (ios::provider::IsFullscreenSmoothScrollingSupported()) {
    self.fullscreenController->ResizeHorizontalViewport();
  }

  [self.popupMenuCommandsHandler adjustPopupSize];
}

- (void)dismissViewControllerAnimated:(BOOL)flag
                           completion:(void (^)())completion {
  if (!self.presentedViewController) {
    // TODO(crbug.com/41364311): On iOS10, UIDocumentMenuViewController and
    // WKFileUploadPanel somehow combine to call dismiss twice instead of one.
    // The second call would dismiss the BVC itself, so look for that case and
    // return early.
    //
    // TODO(crbug.com/41370278): A similar bug exists on all iOS versions with
    // WKFileUploadPanel and UIDocumentPickerViewController.
    //
    // To make M65 as safe as possible, return early whenever this method is
    // invoked but no VC appears to be presented. These cases will always end
    // up dismissing the BVC itself, which would put the app into an
    // unresponsive state.
    return;
  }

  // Some calling code invokes `dismissViewControllerAnimated:completion:`
  // multiple times. Because the BVC is presented, subsequent calls end up
  // dismissing the BVC itself. This is never what should happen, so check for
  // this case and return early. It is not enough to check
  // `self.dismissingModal` because some dismissals do not go through
  // -[BrowserViewController dismissViewControllerAnimated:completion:`.
  // TODO(crbug.com/40548564): Fix callers and remove this early return.
  if (self.dismissingModal || self.presentedViewController.isBeingDismissed) {
    return;
  }

  self.dismissingModal = YES;
  self.visibilityState = BrowserViewVisibilityState::kVisible;
  __weak BrowserViewController* weakSelf = self;
  [super dismissViewControllerAnimated:flag
                            completion:^{
                              BrowserViewController* strongSelf = weakSelf;
                              strongSelf.dismissingModal = NO;
                              if (completion) {
                                completion();
                              }
                            }];
}

// The BVC does not define its own presentation context, so any presentation
// here ultimately travels up the chain for presentation.
- (void)presentViewController:(UIViewController*)viewControllerToPresent
                     animated:(BOOL)flag
                   completion:(void (^)())completion {
  ProceduralBlock finalCompletionHandler = [completion copy];
  // TODO(crbug.com/41235932) This is an interim fix for the flicker between the
  // launch screen and the FRE Animation. The fix is, if the FRE is about to be
  // presented, to show a temporary view of the launch screen and then remove it
  // when the controller for the FRE has been presented. This fix should be
  // removed when the FRE startup code is rewritten.
  const bool firstRunLaunch = ShouldPresentFirstRunExperience();
  // These if statements check that `presentViewController` is being called for
  // the FRE case.
  if (firstRunLaunch &&
      [viewControllerToPresent isKindOfClass:[UINavigationController class]]) {
    UINavigationController* navController =
        base::apple::ObjCCastStrict<UINavigationController>(
            viewControllerToPresent);
    if ([navController.topViewController
            isKindOfClass:[PromoStyleViewController class]]) {
      self.hideStatusBar = YES;

      // Load view from Launch Screen and add it to window.
      NSBundle* mainBundle = base::apple::FrameworkBundle();
      NSArray* topObjects = [mainBundle loadNibNamed:@"LaunchScreen"
                                               owner:self
                                             options:nil];
      UIViewController* launchScreenController =
          base::apple::ObjCCastStrict<UIViewController>(
              [topObjects lastObject]);
      // `launchScreenView` is loaded as an autoreleased object, and is retained
      // by the `completion` block below.
      UIView* launchScreenView = launchScreenController.view;
      launchScreenView.userInteractionEnabled = NO;
      // TODO(crbug.com/40101769): Displaying the launch screen is a hack to
      // hide the build up of the UI from the user. To implement the hack, this
      // view controller uses information that it should not know or care about:
      // this BVC is contained and its parent bounds to the full screen.
      launchScreenView.frame = self.parentViewController.view.bounds;
      [self.parentViewController.view addSubview:launchScreenView];
      [launchScreenView setNeedsLayout];
      [launchScreenView layoutIfNeeded];

      // Replace the completion handler sent to the superclass with one which
      // removes `launchScreenView` and resets the status bar. If `completion`
      // exists, it is called from within the new completion handler.
      __weak BrowserViewController* weakSelf = self;
      finalCompletionHandler = ^{
        [launchScreenView removeFromSuperview];
        weakSelf.hideStatusBar = NO;
        if (completion) {
          completion();
        }
      };
    }
  }

  [_sideSwipeCoordinator stopActiveSideSwipeAnimation];
  // TODO(crbug.com/406544789): Currently, some of the views are presented with
  // `browserViewController` but not dismissed with this, therefore we cannot
  // update the visibility state to `kCoveredByModal` without being sure that it
  // would be changed back to `kVisible` afterwards. Fix the bug and update the
  // visibility state.

  void (^superCall)() = ^{
    [super presentViewController:viewControllerToPresent
                        animated:flag
                      completion:finalCompletionHandler];
  };
  // TODO(crbug.com/40628488): The Default Browser Promo is
  // currently the only presented controller that allows interaction with the
  // rest of the App while they are being presented. Dismiss it in case the user
  // or system has triggered another presentation.
  if ([self.nonModalPromoPresentationDelegate defaultNonModalPromoIsShowing]) {
    self.visibilityState = BrowserViewVisibilityState::kVisible;
    [self.presentedViewController
        dismissViewControllerAnimated:NO
                           completion:superCall];

  } else {
    superCall();
  }
}

- (BOOL)shouldAutorotate {
  if (self.presentedViewController.beingPresented ||
      self.presentedViewController.beingDismissed) {
    // Don't rotate while a presentation or dismissal animation is occurring.
    return NO;
  } else if (_sideSwipeCoordinator.swipeInProgress) {
    // Don't auto rotate if a side swipe is in progress.
    return NO;
  } else {
    return [super shouldAutorotate];
  }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return _isOffTheRecord ? UIStatusBarStyleLightContent
                         : UIStatusBarStyleDefault;
}

#pragma mark - Missing Selector Implementations

- (UIViewController *)viewControllerToPresent {
  return self.presentedViewController ?: self;
}

#pragma mark - KVO Observation

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"containerView.frame"] && object == self.containerView) {
    CGRect newFrame = [change[NSKeyValueChangeNewKey] CGRectValue];
    NSLog(@"KVO: Container view frame changed to: %@", NSStringFromCGRect(newFrame));
  } else if ([keyPath isEqualToString:@"contentSize"] && [object isKindOfClass:[UIScrollView class]]) {
    CGSize newContentSize = [change[NSKeyValueChangeNewKey] CGSizeValue];
    NSLog(@"KVO: Scroll view contentSize changed to: %@", NSStringFromCGSize(newContentSize));
    // Enforce full contentSize for NTP only
    if (self.ntpCoordinator.isNTPActiveForCurrentWebState) {
      CGSize expectedContentSize = CGSizeMake(self.containerView.bounds.size.width, self.containerView.bounds.size.height);
      if (!CGSizeEqualToSize(newContentSize, expectedContentSize)) {
        NSLog(@"KVO: Correcting scroll view contentSize from %@ to %@", NSStringFromCGSize(newContentSize), NSStringFromCGSize(expectedContentSize));
        UIScrollView *scrollView = (UIScrollView *)object;
        scrollView.contentSize = expectedContentSize;
      }
    }
  } else if ([keyPath isEqualToString:@"frame"] && [object isKindOfClass:[UIView class]]) {
    CGRect newFrame = [change[NSKeyValueChangeNewKey] CGRectValue];
    NSLog(@"KVO: Web view frame changed to: %@", NSStringFromCGRect(newFrame));
  }
}

#pragma mark - UIScrollViewDelegate

// Helper method to configure scroll view consistently
- (void)configureScrollView:(UIScrollView *)scrollView {
  // Calculate expected content size
  CGSize expectedContentSize;
  if (self.ntpCoordinator.isNTPActiveForCurrentWebState) {
    expectedContentSize = CGSizeMake(self.containerView.bounds.size.width, self.containerView.bounds.size.height);
  } else {
    expectedContentSize = CGSizeMake(scrollView.contentSize.width, MAX(self.containerView.bounds.size.height, scrollView.contentSize.height));
  }

  // Enforce content size
  if (!CGSizeEqualToSize(scrollView.contentSize, expectedContentSize)) {
    NSLog(@"configureScrollView: Correcting contentSize from %@ to %@", NSStringFromCGSize(scrollView.contentSize), NSStringFromCGSize(expectedContentSize));
    scrollView.contentSize = expectedContentSize;
  }

  // Clamp contentOffset.y to prevent overscroll
  CGFloat maxOffsetY = MAX(0, scrollView.contentSize.height - scrollView.bounds.size.height);
  CGFloat clampedOffsetY = MIN(MAX(scrollView.contentOffset.y, 0), maxOffsetY);
  if (fabs(scrollView.contentOffset.y - clampedOffsetY) > 0.01) {
    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, clampedOffsetY);
    NSLog(@"configureScrollView: Clamped contentOffset.y from %f to %f", scrollView.contentOffset.y, clampedOffsetY);
  }

  // Enforce consistent settings
  scrollView.contentInset = UIEdgeInsetsZero;
  scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
  scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  scrollView.bounces = NO;
  scrollView.alwaysBounceVertical = NO;
  scrollView.scrollEnabled = YES;
  scrollView.delegate = self;

  _lastContentOffset = scrollView.contentOffset;
  NSLog(@"configureScrollView: contentOffset: %@, contentSize: %@, bounds: %@", NSStringFromCGPoint(scrollView.contentOffset), NSStringFromCGSize(scrollView.contentSize), NSStringFromCGRect(scrollView.bounds));
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  // Clamp contentOffset.y to ensure fixed elements stay in place
  CGFloat maxOffsetY = MAX(0, scrollView.contentSize.height - scrollView.bounds.size.height);
  CGFloat clampedOffsetY = MIN(MAX(scrollView.contentOffset.y, 0), maxOffsetY);
  if (fabs(scrollView.contentOffset.y - clampedOffsetY) > 0.01) {
    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, clampedOffsetY);
    NSLog(@"scrollViewDidEndDragging: Clamped contentOffset.y from %f to %f", scrollView.contentOffset.y, clampedOffsetY);
  }

  // Enforce contentSize to match container bounds
  if (!self.ntpCoordinator.isNTPActiveForCurrentWebState) {
    CGFloat expectedHeight = self.containerView.bounds.size.height;
    if (fabs(scrollView.contentSize.height - expectedHeight) > 0.01) {
      NSLog(@"scrollViewDidEndDragging: Correcting contentSize height from %f to %f", scrollView.contentSize.height, expectedHeight);
      scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, expectedHeight);
    }
  } else {
    CGSize expectedContentSize = CGSizeMake(self.containerView.bounds.size.width, self.containerView.bounds.size.height);
    if (!CGSizeEqualToSize(scrollView.contentSize, expectedContentSize)) {
      NSLog(@"scrollViewDidEndDragging: Correcting NTP contentSize from %@ to %@", NSStringFromCGSize(scrollView.contentSize), NSStringFromCGSize(expectedContentSize));
      scrollView.contentSize = expectedContentSize;
    }
  }

  // Ensure consistent scroll view settings
  scrollView.contentInset = UIEdgeInsetsZero;
  scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
  scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  scrollView.bounces = NO;
  scrollView.alwaysBounceVertical = NO;

  _lastContentOffset = scrollView.contentOffset;
  NSLog(@"scrollViewDidEndDragging: contentOffset: %@, contentSize: %@, bounds: %@, maxOffsetY: %f", NSStringFromCGPoint(scrollView.contentOffset), NSStringFromCGSize(scrollView.contentSize), NSStringFromCGRect(scrollView.bounds), maxOffsetY);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  // Clamp contentOffset.y to ensure fixed elements stay in place
  CGFloat maxOffsetY = MAX(0, scrollView.contentSize.height - scrollView.bounds.size.height);
  CGFloat clampedOffsetY = MIN(MAX(scrollView.contentOffset.y, 0), maxOffsetY);
  if (fabs(scrollView.contentOffset.y - clampedOffsetY) > 0.01) {
    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, clampedOffsetY);
    NSLog(@"scrollViewDidEndDecelerating: Clamped contentOffset.y from %f to %f", scrollView.contentOffset.y, clampedOffsetY);
  }

  // Enforce contentSize to match container bounds
  if (!self.ntpCoordinator.isNTPActiveForCurrentWebState) {
    CGFloat expectedHeight = self.containerView.bounds.size.height;
    if (fabs(scrollView.contentSize.height - expectedHeight) > 0.01) {
      NSLog(@"scrollViewDidEndDecelerating: Correcting contentSize height from %f to %f", scrollView.contentSize.height, expectedHeight);
      scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, expectedHeight);
    }
  } else {
    CGSize expectedContentSize = CGSizeMake(self.containerView.bounds.size.width, self.containerView.bounds.size.height);
    if (!CGSizeEqualToSize(scrollView.contentSize, expectedContentSize)) {
      NSLog(@"scrollViewDidEndDecelerating: Correcting NTP contentSize from %@ to %@", NSStringFromCGSize(scrollView.contentSize), NSStringFromCGSize(expectedContentSize));
      scrollView.contentSize = expectedContentSize;
    }
  }

  // Ensure consistent scroll view settings
  scrollView.contentInset = UIEdgeInsetsZero;
  scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
  scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  scrollView.bounces = NO;
  scrollView.alwaysBounceVertical = NO;

  _lastContentOffset = scrollView.contentOffset;
  NSLog(@"scrollViewDidEndDecelerating: contentOffset: %@, contentSize: %@, bounds: %@, maxOffsetY: %f", NSStringFromCGPoint(scrollView.contentOffset), NSStringFromCGSize(scrollView.contentSize), NSStringFromCGRect(scrollView.bounds), maxOffsetY);
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
  // Ensure contentOffset.y is 0 and settings are consistent
  if (fabs(scrollView.contentOffset.y) > 0.01) {
    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    NSLog(@"scrollViewDidScrollToTop: Reset contentOffset.y to 0");
  }

  // Enforce contentSize to match container bounds
  if (!self.ntpCoordinator.isNTPActiveForCurrentWebState) {
    CGFloat expectedHeight = self.containerView.bounds.size.height;
    if (fabs(scrollView.contentSize.height - expectedHeight) > 0.01) {
      NSLog(@"scrollViewDidScrollToTop: Correcting contentSize height from %f to %f", scrollView.contentSize.height, expectedHeight);
      scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, expectedHeight);
    }
  } else {
    CGSize expectedContentSize = CGSizeMake(self.containerView.bounds.size.width, self.containerView.bounds.size.height);
    if (!CGSizeEqualToSize(scrollView.contentSize, expectedContentSize)) {
      NSLog(@"scrollViewDidScrollToTop: Correcting NTP contentSize from %@ to %@", NSStringFromCGSize(scrollView.contentSize), NSStringFromCGSize(expectedContentSize));
      scrollView.contentSize = expectedContentSize;
    }
  }

  // Ensure consistent scroll view settings
  scrollView.contentInset = UIEdgeInsetsZero;
  scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
  scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  scrollView.bounces = NO;
  scrollView.alwaysBounceVertical = NO;

  _lastContentOffset = scrollView.contentOffset;
  NSLog(@"scrollViewDidScrollToTop: contentOffset: %@, contentSize: %@, bounds: %@", NSStringFromCGPoint(scrollView.contentOffset), NSStringFromCGSize(scrollView.contentSize), NSStringFromCGRect(scrollView.bounds));
}

#pragma mark - Private Methods: UI Configuration, update and Layout

// Register notifications to NSNotification center.
- (void)registerNotifications {
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(voiceSearchWillAppear)
                 name:kVoiceSearchWillShowNotification
               object:nil];
  [center addObserver:self
             selector:@selector(voiceSearchWillHide)
                 name:kVoiceSearchWillHideNotification
               object:nil];
}

// On iOS7, iPad should match iOS6 status bar. Install a simple black bar under
// the status bar to mimic this layout.
- (void)installFakeStatusBar {
  // This method is called when the view is loaded.

  // Remove the _fakeStatusBarView if present.
  [_fakeStatusBarView removeFromSuperview];
  _fakeStatusBarView = nil;

  CGRect statusBarFrame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0);
  _fakeStatusBarView = [[UIView alloc] initWithFrame:statusBarFrame];
  [_fakeStatusBarView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
  // Prevent fake status bar from intercepting touches
  _fakeStatusBarView.userInteractionEnabled = NO;
  if (ui::GetDeviceFormFactor() == ui::DEVICE_FORM_FACTOR_TABLET) {
    _fakeStatusBarView.backgroundColor = TabStripHelper.backgroundColor;
    // Force the UserInterfaceStyle update in incognito.
    _fakeStatusBarView.overrideUserInterfaceStyle =
        _isOffTheRecord ? UIUserInterfaceStyleDark
                        : UIUserInterfaceStyleUnspecified;
    const bool canShowTabStrip = IsRegularXRegularSizeClass(self);
    _fakeStatusBarView.hidden = !canShowTabStrip;
    _fakeStatusBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    DCHECK(self.contentArea);
    [self.view insertSubview:_fakeStatusBarView aboveSubview:self.contentArea];
  } else {
    // Add a white bar when there is no tab strip so that the status bar on the
    // NTP is white.
    _fakeStatusBarView.backgroundColor = ntp_home::NTPBackgroundColor();
    [self.view insertSubview:_fakeStatusBarView atIndex:0];
  }
}

// Builds the UI parts of tab strip and the toolbar. Does not matter whether
// or not profile and browser are valid.
- (void)buildToolbarAndTabStrip {
  DCHECK([self isViewLoaded]);

  [self updateBroadcastState];
  if (_voiceSearchController) {
    _voiceSearchController.dispatcher = self.loadQueryCommandsHandler;
  }

  if (ui::GetDeviceFormFactor() == ui::DEVICE_FORM_FACTOR_TABLET) {
    const bool canShowTabStrip = IsRegularXRegularSizeClass(self);
    [self.tabStripCoordinator start];
    [self.tabStripCoordinator hideTabStrip:!canShowTabStrip];
  }
}

// The height of the primary toolbar with the top safe area inset included.
- (CGFloat)primaryToolbarHeightWithInset {
  CGFloat height = self.toolbarCoordinator.expandedPrimaryToolbarHeight;
  // If the primary toolbar is not the topmost header, it does not overlap with
  // the unsafe area.
  // TODO(crbug.com/41367346): Update implementation such that this calculates
  // the topmost header's height.
  UIView* primaryToolbar =
      self.toolbarCoordinator.primaryToolbarViewController.view;
  UIView* topmostHeader = [self.headerViews firstObject].view;
  if (primaryToolbar != topmostHeader) {
    return height;
  }
  // If the primary toolbar is topmost, subtract the height of the portion of
  // the unsafe area.
  CGFloat unsafeHeight = self.rootSafeAreaInsets.top;

  // The topmost header is laid out `headerOffset` from the top of `view`, so
  // subtract that from the unsafe height.
  unsafeHeight -= self.headerOffset;
  return height + unsafeHeight;
}

// The height of the secondary toolbar with the bottom safe area inset included.
// Returns 0 if the toolbar should be hidden.
- (CGFloat)secondaryToolbarHeightWithInset {
  CGFloat height = self.toolbarCoordinator.expandedSecondaryToolbarHeight;
  if (!height) {
    return 0.0;
  }
  // Do not add safe area inset to ensure toolbar sticks to bottom
  return height;
}

// Sets up the constraints on the primary toolbar.
- (void)addConstraintsToPrimaryToolbar {
  // Skip adding constraints if toolbars are hidden
  if (self.hideToolbars) {
    return;
  }

  NSLayoutYAxisAnchor* topAnchor;
  // On iPhone, the toolbar is underneath the top of the screen.
  // On iPad, it depends:
  // - if the window is compact, it is like iPhone, underneath the top of the screen.
  // - if the window is regular, it is underneath the tab strip.
  if (ui::GetDeviceFormFactor() == ui::DEVICE_FORM_FACTOR_PHONE ||
      !IsRegularXRegularSizeClass(self)) {
    topAnchor = self.view.topAnchor;
  } else {
    topAnchor = self.tabStripView.bottomAnchor;
  }

  // Only add leading and trailing constraints once as they are never updated.
  // This uses the existence of `primaryToolbarOffsetConstraint` as a proxy for
  // whether we've already added the leading and trailing constraints.
  if (!self.primaryToolbarOffsetConstraint) {
    [NSLayoutConstraint activateConstraints:@[
      [self.toolbarCoordinator.primaryToolbarViewController.view.leadingAnchor
          constraintEqualToAnchor:[self view].leadingAnchor],
      [self.toolbarCoordinator.primaryToolbarViewController.view.trailingAnchor
          constraintEqualToAnchor:[self view].trailingAnchor],
    ]];
  }

  // Offset and Height can be updated, so reset first.
  self.primaryToolbarOffsetConstraint.active = NO;
  self.primaryToolbarHeightConstraint.active = NO;

  // Create a constraint for the vertical positioning of the toolbar.
  UIView* primaryView = self.toolbarCoordinator.primaryToolbarViewController.view;
  self.primaryToolbarOffsetConstraint =
      [primaryView.topAnchor constraintEqualToAnchor:topAnchor];

  // Create a constraint for the height of the toolbar to include the unsafe
  // area height.
  self.primaryToolbarHeightConstraint = [primaryView.heightAnchor
      constraintEqualToConstant:[self primaryToolbarHeightWithInset]];

  self.primaryToolbarOffsetConstraint.active = YES;
  self.primaryToolbarHeightConstraint.active = YES;

  // Ensure toolbar doesn't clip content, allowing overlap
  primaryView.clipsToBounds = NO;
}

- (void)addConstraintsToSecondaryToolbar {
  // Skip adding constraints if toolbars are hidden
  if (self.hideToolbars) {
    return;
  }

  // Ensure the secondary toolbar is pinned to the bottom with high priority
  UIView* toolbarView = self.toolbarCoordinator.secondaryToolbarViewController.view;
  toolbarView.translatesAutoresizingMaskIntoConstraints = NO;

  // Remove any existing constraints to avoid conflicts
  [NSLayoutConstraint deactivateConstraints:toolbarView.constraints];

  // Create a constraint for the height of the toolbar
  self.secondaryToolbarHeightConstraint = [toolbarView.heightAnchor
      constraintEqualToConstant:[self secondaryToolbarHeightWithInset]];
  self.secondaryToolbarHeightConstraint.priority = UILayoutPriorityRequired; // Non-negotiable priority

  // Pin to bottom, leading, and trailing edges of the view with zero constant
  [NSLayoutConstraint activateConstraints:@[
    [toolbarView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0],
    [toolbarView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [toolbarView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    self.secondaryToolbarHeightConstraint
  ]];

  [toolbarView layoutIfNeeded];
  toolbarView.clipsToBounds = NO; // Allow content to render behind toolbar
  NSLog(@"addConstraintsToSecondaryToolbar: Secondary toolbar frame: %@", NSStringFromCGRect(toolbarView.frame));
}

// Adds constraints to the primary and secondary toolbars, anchoring them to the
// top and bottom of the browser view.
- (void)addConstraintsToToolbar {
  [self addConstraintsToPrimaryToolbar];
  [self addConstraintsToSecondaryToolbar];
  [[self view] layoutIfNeeded];
}

// Sets up the frame for the fake status bar. View must be loaded.
- (void)setupStatusBarLayout {
  CGFloat topInset = self.rootSafeAreaInsets.top;

  // Update the fake toolbar background height.
  CGRect fakeStatusBarFrame = _fakeStatusBarView.frame;
  fakeStatusBarFrame.size.height = topInset;
  _fakeStatusBarView.frame = fakeStatusBarFrame;
}

// Sets up the frame and hierarchy for subviews and helper views. Only
// insert views on `initialLayout`.
- (void)setUpViewLayout:(BOOL)initialLayout {
  DCHECK([self isViewLoaded]);

  [self setupStatusBarLayout];

  if (initialLayout) {
    // Add the tab strip on iPad if present, regardless of hideToolbars.
    if (ui::GetDeviceFormFactor() == ui::DEVICE_FORM_FACTOR_TABLET && self.tabStripCoordinator) {
      UIViewController* tabStripViewController = self.tabStripCoordinator.viewController;
      [self addChildViewController:tabStripViewController];
      self.tabStripView = tabStripViewController.view;
      [self.view addSubview:self.tabStripView];
      [tabStripViewController didMoveToParentViewController:self];
      CGRect tabStripFrame = CGRectMake(0, self.headerOffset, self.view.bounds.size.width,
                                        TabStripCollectionViewConstants.height);
      self.tabStripView.frame = tabStripFrame;
      self.tabStripView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleBottomMargin);
    }

    // Conditionally add toolbars only if hideToolbars is NO.
    if (!self.hideToolbars) {
      [self addChildViewController:self.toolbarCoordinator.primaryToolbarViewController];
      UIView* primaryToolbarView = self.toolbarCoordinator.primaryToolbarViewController.view;
      if (ui::GetDeviceFormFactor() == ui::DEVICE_FORM_FACTOR_TABLET) {
        [self.view insertSubview:primaryToolbarView aboveSubview:self.tabStripView];
      } else {
        [self.view addSubview:primaryToolbarView];
      }
      [self addChildViewController:self.toolbarCoordinator.secondaryToolbarViewController];
      [self.view insertSubview:self.toolbarCoordinator.secondaryToolbarViewController.view
                  aboveSubview:primaryToolbarView];
    }

    // Complete child UIViewController containment flow only for added views.
    if (self.tabStripCoordinator) {
      [self.tabStripCoordinator.viewController didMoveToParentViewController:self];
    }
    if (!self.hideToolbars) {
      [self.toolbarCoordinator.primaryToolbarViewController didMoveToParentViewController:self];
      [self.toolbarCoordinator.secondaryToolbarViewController didMoveToParentViewController:self];
    }
  }

  // Resize the typing shield to cover the entire browser view and bring it to the front.
  self.typingShield.frame = self.contentArea.frame;
  if (initialLayout) {
    [self.view bringSubviewToFront:self.typingShield];
  }

  // Move the overlay containers in front of the hierarchy.
  [self updateOverlayContainerOrder];

  // Log content area frame and constraints
  NSLog(@"setUpViewLayout: Content area frame: %@", NSStringFromCGRect(self.contentArea.frame));
  NSLog(@"setUpViewLayout: Content area constraints: %@", self.contentArea.constraints);
}

- (void)updateContentAreaConstraints {
  // Constraints are disabled as contentArea uses frame-based layout
  [NSLayoutConstraint deactivateConstraints:self.contentArea.constraints];
  self.contentArea.frame = self.view.bounds;
  NSLog(@"updateContentAreaConstraints: Content area frame set to: %@", NSStringFromCGRect(self.contentArea.frame));
}

// Updates the z-order of the banner and modal overlay containers.
- (void)updateOverlayContainerOrder {
  NSLog(@"updateOverlayContainerOrder: Banner=%@, Modal=%@",
        self.infobarBannerOverlayContainerViewController,
        self.infobarModalOverlayContainerViewController);
  if (self.infobarBannerOverlayContainerViewController) {
    [self bringOverlayContainerToFront:self.infobarBannerOverlayContainerViewController];
  }
  if (self.infobarModalOverlayContainerViewController) {
    [self bringOverlayContainerToFront:self.infobarModalOverlayContainerViewController];
  }
}

// Brings the given container view controller to the front of the view hierarchy.
- (void)bringOverlayContainerToFront:(UIViewController*)containerViewController {
  [self.view bringSubviewToFront:containerViewController.view];
  UIView* presentedContainerView =
      containerViewController.presentedViewController.presentationController.containerView;
  if (presentedContainerView.superview == self.view) {
    [self.view bringSubviewToFront:presentedContainerView];
  }
}

// Invoked when voice search shows.
- (void)voiceSearchWillAppear {
  self.visibilityState = BrowserViewVisibilityState::kCoveredByVoiceSearch;
}

// Invoked when voice search hides.
- (void)voiceSearchWillHide {
  self.visibilityState = BrowserViewVisibilityState::kVisible;
}

// Displays the current webState view.
- (void)displayTabView {
  if (self.inNewTabAnimation) {
    return;
  }

  if (!self.currentWebState) {
    [self.ntpCoordinator start];
    UIViewController* ntpController = self.ntpCoordinator.viewController;
    if (ntpController.view.superview != self.containerView) {
      [self addChildViewController:ntpController];
      ntpController.view.frame = [self ntpFrameForCurrentWebState];
      [self.containerView addSubview:ntpController.view];
      [ntpController didMoveToParentViewController:self];
      NSLog(@"displayTabView: NTP view controller frame: %@", NSStringFromCGRect(ntpController.view.frame));
      NSLog(@"displayTabView: NTP view hierarchy: %@", ntpController.view.subviews);
    }
    return;
  }

  if (self.ntpCoordinator.isNTPActiveForCurrentWebState) {
    [self.ntpCoordinator start];
    UIViewController* ntpController = self.ntpCoordinator.viewController;
    if (ntpController.view.superview != self.containerView) {
      [self addChildViewController:ntpController];
      ntpController.view.frame = [self ntpFrameForCurrentWebState];
      [self.containerView addSubview:ntpController.view];
      [ntpController didMoveToParentViewController:self];
      NSLog(@"displayTabView: NTP view controller frame: %@", NSStringFromCGRect(ntpController.view.frame));
      NSLog(@"displayTabView: NTP view hierarchy: %@", ntpController.view.subviews);
    }
    return;
  }

  // Non-NTP case
  UIView* view = [self viewForWebState:self.currentWebState];
  if (!view) {
    return;
  }

  NSLog(@"displayTabView: Web view class: %@", NSStringFromClass([view class]));
  UIScrollView* scrollView = nil;
  if ([view isKindOfClass:[WKWebView class]]) {
    scrollView = [(WKWebView*)view scrollView];
  } else if ([view isKindOfClass:NSClassFromString(@"CRWWebControllerContainerView")]) {
    // Access WKWebView from CRWWebControllerContainerView
    for (UIView* subview in view.subviews) {
      if ([subview isKindOfClass:[WKWebView class]]) {
        scrollView = [(WKWebView*)subview scrollView];
        NSLog(@"displayTabView: Found WKWebView in CRWWebControllerContainerView");
        break;
      }
    }
  }

  if (scrollView) {
    if (scrollView.contentSize.height < self.containerView.bounds.size.height) {
      scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, self.containerView.bounds.size.height);
      scrollView.contentOffset = _lastContentOffset;
    }
    scrollView.scrollEnabled = YES;
    scrollView.contentInset = UIEdgeInsetsZero;
    scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    scrollView.bounces = NO;
    scrollView.alwaysBounceVertical = NO;
    // Log scroll view state after adjustments
    NSLog(@"displayTabView: Adjusted ScrollView contentOffset: %@", NSStringFromCGPoint(scrollView.contentOffset));
    NSLog(@"displayTabView: Adjusted ScrollView contentSize: %@", NSStringFromCGSize(scrollView.contentSize));
    NSLog(@"displayTabView: ScrollView scrollEnabled: %d", scrollView.scrollEnabled);
  } else {
    NSLog(@"displayTabView: No scroll view found, skipping scroll configuration");
  }

  if (view.superview != self.containerView) {
    [self.containerView addSubview:view];
    view.frame = self.containerView.bounds;
    view.translatesAutoresizingMaskIntoConstraints = YES;
    [NSLayoutConstraint deactivateConstraints:view.constraints];
    [self updateBrowserViewportForFullscreenProgress:self.footerFullscreenProgress];
  }
}

// Starts or stops broadcasting the toolbar UI and main content UI depending on
// whether the BVC is visible and active.
- (void)updateBroadcastState {
  self.broadcasting = self.active && self.visibilityState == BrowserViewVisibilityState::kVisible;
}

// Dismisses popups and modal dialogs that are displayed above the BVC when the
// accessibility escape gesture is performed.
- (void)dismissPopups {
  // The dispatcher may not be fully connected during shutdown, so selectors may
  // be unrecognized.
  if (_isShutdown) {
    return;
  }

  [self.popupMenuCommandsHandler dismissPopupMenuAnimated:NO];
  [self.helpHandler hideAllHelpBubbles];
  [self.omniboxCommandsHandler cancelOmniboxEdit];
}

// Returns the appropriate frame for the NTP.
- (CGRect)ntpFrameForCurrentWebState {
  DCHECK(self.ntpCoordinator.isNTPActiveForCurrentWebState);
  UIEdgeInsets viewportInsets = UIEdgeInsetsZero;
  viewportInsets.top = self.rootSafeAreaInsets.top + kTopPadding;
  if (!self.hideToolbars) {
    if (!IsRegularXRegularSizeClass(self)) {
      viewportInsets.bottom = [self secondaryToolbarHeightWithInset];
    }
    if (!IsSplitToolbarMode(self) || _isOffTheRecord) {
      viewportInsets.top += [self expandedTopToolbarHeight];
    }
  }
  CGRect frame = UIEdgeInsetsInsetRect(self.contentArea.bounds, viewportInsets);
  NSLog(@"ntpFrameForCurrentWebState: NTP frame: %@", NSStringFromCGRect(frame));
  NSLog(@"ntpFrameForCurrentWebState: Coordinator started: %d, View exists: %d",
        self.ntpCoordinator.started,
        self.ntpCoordinator.viewController.view != nil);
  return frame;
}

// Sets the frame for the headers.
- (void)setFramesForHeaders:(NSArray<HeaderDefinition*>*)headers
                   atOffset:(CGFloat)headerOffset {
  CGFloat height = self.headerOffset;
  for (HeaderDefinition* header in headers) {
    CGFloat yOrigin = height - headerOffset;
    BOOL isPrimaryToolbar =
        header.view ==
        self.toolbarCoordinator.primaryToolbarViewController.view;
    // Make sure the toolbarView's constraints are also updated. Leaving the
    // -setFrame call to minimize changes in this CL -- otherwise the way
    // toolbar_view manages its alpha changes would also need to be updated.
    // TODO(crbug.com/40546808): This can be cleaned up when the new fullscreen
    // is enabled.
    if (isPrimaryToolbar && !IsRegularXRegularSizeClass(self)) {
      self.primaryToolbarOffsetConstraint.constant = yOrigin;
    }
    CGRect frame = [header.view frame];
    frame.origin.y = yOrigin;
    [header.view setFrame:frame];
    if (header.behaviour != Overlap) {
      height += CGRectGetHeight(frame);
    }

    if (header.view == self.tabStripView) {
      [self setNeedsStatusBarAppearanceUpdate];
    }
  }
}

- (UIView*)viewForWebState:(web::WebState*)webState {
  if (!webState) {
    NSLog(@"viewForWebState: No web state provided, returning nil");
    return nil;
  }
  if (self.ntpCoordinator.isNTPActiveForCurrentWebState) {
    UIView *ntpView = self.ntpCoordinator.started ? self.ntpCoordinator.viewController.view : nil;
    if (!ntpView) {
      NSLog(@"viewForWebState: NTP coordinator not started or no view, returning nil");
    }
    return ntpView;
  }
  DCHECK(self.webStateList->GetIndexOfWebState(webState) !=
         WebStateList::kInvalidIndex);
  if (webState->IsEvicted() && _tabUsageRecorderBrowserAgent) {
    _tabUsageRecorderBrowserAgent->RecordPageLoadStart(webState);
  }
  if (!webState->IsCrashed()) {
    // Load the page if it was evicted by browsing data clearing logic or if
    // page was never loaded yet after launch.
    webState->GetNavigationManager()->LoadIfNecessary();
  }
  UIView *view = webState->GetView();
  if (!view) {
    NSLog(@"viewForWebState: No view available for web state, creating WKWebView");
    view = [[WKWebView alloc] initWithFrame:self.contentArea.bounds configuration:[self webViewConfiguration]];
  }
  NSLog(@"viewForWebState: Returning view of class: %@", NSStringFromClass([view class]));
  return view;
}

// Notifies or modifies BVC owned UI elements when a UITrait has been changed.
- (void)updateUIOnTraitChange:(UITraitCollection*)previousTraitCollection {
  // After `-shutdown` is called, profile is invalid and will cause a crash.
  if (_isShutdown) {
    return;
  }

  if (self.traitCollection.horizontalSizeClass ==
          previousTraitCollection.horizontalSizeClass &&
      self.traitCollection.verticalSizeClass ==
          previousTraitCollection.verticalSizeClass) {
    return;
  }

  self.fullscreenController->BrowserTraitCollectionChangedBegin();

#if !defined(__IPHONE_17_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_17_0
  // TODO(crbug.com/41198852): - traitCollectionDidChange: is not always
  // forwarded because in some cases the presented view controller isn't a child
  // of the BVC in the view controller hierarchy (some intervening object isn't
  // a view controller).
  [self.presentedViewController
      traitCollectionDidChange:previousTraitCollection];
#endif

  if (self.currentWebState) {
    UIView *webView = self.currentWebState->GetView();
    if ([webView isKindOfClass:[WKWebView class]]) {
      UIEdgeInsets contentPadding = [(WKWebView *)webView scrollView].contentInset;
      contentPadding.bottom = 0; // No bottom inset to avoid gap
      contentPadding.top = 0; // No top inset to allow content to stretch
      [(WKWebView *)webView scrollView].contentInset = contentPadding;
      [(WKWebView *)webView scrollView].scrollIndicatorInsets = contentPadding;
      [(WKWebView *)webView scrollView].contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
      [(WKWebView *)webView scrollView].contentOffset = _lastContentOffset; // Restore offset
      // Force contentSize to match frame height
      CGFloat expectedHeight = self.containerView.bounds.size.height;
      if ([(WKWebView *)webView scrollView].contentSize.height < expectedHeight) {
        [(WKWebView *)webView scrollView].contentSize = CGSizeMake([(WKWebView *)webView scrollView].contentSize.width, expectedHeight);
        NSLog(@"updateUIOnTraitChange: Forced contentSize height to %f", expectedHeight);
      }
    }
  }

  // Toolbars size must be updated before
  // `updateFootersForFullscreenProgress` as the later uses the insets from
  // fullscreen model.
  [self updateToolbarState];

  // Change the height of the secondary toolbar to show/hide it.
  self.secondaryToolbarHeightConstraint.constant =
      [self secondaryToolbarHeightWithInset];
  [self updateFootersForFullscreenProgress:self.footerFullscreenProgress];

  // If the device's size class has changed from RegularXRegular to another and
  // vice-versa, the find bar should switch between regular mode and compact
  // mode accordingly. Hide the findbar here and it will be reshown in [self
  // updateToolbar];
  if (ShouldShowCompactToolbar(previousTraitCollection) !=
      ShouldShowCompactToolbar(self)) {
    if (!IsNativeFindInPageAvailable()) {
      [self.findInPageCommandsHandler hideFindUI];
    }
    [self.textZoomHandler hideTextZoomUI];
  }

  // Update the toolbar visibility.
  // TODO(crbug.com/40842406): Remove this and let
  // `PrimaryToolbarViewController` or `ToolbarCoordinator` call the update ?
  [self.toolbarCoordinator updateToolbar];

  // Update the tab strip visibility.
  if (self.tabStripView) {
    [self showTabStripView:self.tabStripView];
    [self.tabStripView layoutSubviews];
    const bool canShowTabStrip = IsRegularXRegularSizeClass(self);
    [self.tabStripCoordinator hideTabStrip:!canShowTabStrip];
    _fakeStatusBarView.hidden = !canShowTabStrip;
    [self addConstraintsToPrimaryToolbar];
    // If tabstrip is leaving or coming back due to a window resize or screen
    // rotation, reset the full screen controller to adjust the tabstrip
    // position and toolbar constraints.
    if (ShouldShowCompactToolbar(previousTraitCollection) !=
        ShouldShowCompactToolbar(self)) {
      [self
          updateForFullscreenProgress:self.fullscreenController->GetProgress()];
    }
  }

  [self setNeedsStatusBarAppearanceUpdate];

  self.fullscreenController->BrowserTraitCollectionChangedEnd();
}

// Shows the `tabStripView`.
- (void)showTabStripView:(UIView*)tabStripView {
  DCHECK([self isViewLoaded]);
  DCHECK(tabStripView);
  self.tabStripView = tabStripView;
  CGRect tabStripFrame = [self.tabStripView frame];
  tabStripFrame.origin = CGPointZero;
  // TODO(crbug.com/41023322): Move the origin.y below to -setUpViewLayout.
  // because the CGPointZero above will break reset the offset, but it's not
  // clear what removing that will do.
  tabStripFrame.origin.y = self.headerOffset;
  tabStripFrame.size.width = CGRectGetWidth([self view].bounds);
  [self.tabStripView setFrame:tabStripFrame];

  UIView* primaryToolbar =
      self.toolbarCoordinator.primaryToolbarViewController.view;
  [self.view insertSubview:tabStripView belowSubview:primaryToolbar];
}

#pragma mark - Private Methods: Tap handling

// Record the last tap point based on the `originPoint` (if any) passed in
// command.
- (void)setLastTapPointFromCommand:(CGPoint)originPoint {
  if (CGPointEqualToPoint(originPoint, CGPointZero)) {
    _lastTapPoint = CGPointZero;
  } else {
    _lastTapPoint = [self.view.window convertPoint:originPoint
                                            toView:self.view];
  }
  _lastTapTime = CACurrentMediaTime();
}

// Returns the last stored `_lastTapPoint` if it's been set within the past
// second.
- (CGPoint)lastTapPoint {
  if (CACurrentMediaTime() - _lastTapTime < 1) {
    return _lastTapPoint;
  }
  return CGPointZero;
}

// Store the tap CGPoint in `_lastTapPoint` and the current timestamp.
- (void)saveContentAreaTapLocation:(UIGestureRecognizer*)gestureRecognizer {
  if (_isShutdown) {
    return;
  }
  UIView* view = gestureRecognizer.view;
  CGPoint viewCoordinate = [gestureRecognizer locationInView:view];
  _lastTapPoint = [[view superview] convertPoint:viewCoordinate
                                          toView:self.view];
  _lastTapTime = CACurrentMediaTime();
  // Last tap timestamp will be consumed by `IdleService` if IdleTimeout
  // policy is set.
  GetApplicationContext()->GetLocalState()->SetTime(
      enterprise_idle::prefs::kLastActiveTimestamp, base::Time::Now());
}

#pragma mark - Protocol Implementations and Helpers

#pragma mark - Helpers

- (UIEdgeInsets)snapshotEdgeInsetsForNTPHelper:(NewTabPageTabHelper*)NTPHelper {
  UIEdgeInsets maxViewportInsets =
      self.fullscreenController->GetMaxViewportInsets();
  maxViewportInsets.top = self.rootSafeAreaInsets.top + kTopPadding;

  if (NTPHelper && NTPHelper->IsActive()) {
    // If the NTP is active, then it's used as the base view for snapshotting.
    // When the tab strip is visible, or for the incognito NTP, the NTP is laid
    // out between the toolbars, so it should not be inset while snapshotting.
    if (IsRegularXRegularSizeClass(self) || _isOffTheRecord) {
      return UIEdgeInsetsZero;
    }

    // For the regular NTP without tab strip, it sits above the bottom toolbar
    // but starts below Dynamic Island + padding
    maxViewportInsets.bottom = 0;
    return maxViewportInsets;
  } else {
    // If the NTP is inactive, the WebState's view is used as the base view for
    // snapshotting. If fullscreen is implemented by resizing the scroll view,
    // then the WebILAState view is already laid out within the visible viewport
    // and doesn't need to be inset. If fullscreen uses the content inset, then
    // the WebState view is laid out fullscreen and should be inset by the
    // viewport insets.
    maxViewportInsets.bottom = 0;
    return self.fullscreenController->ResizesScrollView() ? UIEdgeInsetsZero
                                                          : maxViewportInsets;
  }
}

#pragma mark - WebStateContainerViewProvider

- (CGPoint)dialogLocation {
  CGRect bounds = self.view.bounds;
  return CGPointMake(CGRectGetMidX(bounds),
                     CGRectGetMinY(bounds) + self.rootSafeAreaInsets.top + kTopPadding + self.headerHeight);
}

#pragma mark - OmniboxPopupPresenterDelegate methods.

- (UIView*)popupParentViewForPresenter:(OmniboxPopupPresenter*)presenter {
  return self.view;
}

- (UIViewController*)popupParentViewControllerForPresenter:
    (OmniboxPopupPresenter*)presenter {
  return self;
}

- (UIColor*)popupBackgroundColorForPresenter:(OmniboxPopupPresenter*)presenter {
  ToolbarConfiguration* configuration = [[ToolbarConfiguration alloc]
      initWithStyle:_isOffTheRecord ? ToolbarStyle::kIncognito
                                    : ToolbarStyle::kNormal];
  return configuration.backgroundColor;
}

- (GuideName*)omniboxGuideNameForPresenter:(OmniboxPopupPresenter*)presenter {
  return kTopOmniboxGuide;
}

- (void)popupDidOpenForPresenter:(OmniboxPopupPresenter*)presenter {
  self.visibilityState = BrowserViewVisibilityState::kCoveredByOmniboxPopup;
  self.toolbarCoordinator.secondaryToolbarViewController.view
      .accessibilityElementsHidden = YES;
}

- (void)popupDidCloseForPresenter:(OmniboxPopupPresenter*)presenter {
  self.visibilityState = BrowserViewVisibilityState::kVisible;
  self.toolbarCoordinator.secondaryToolbarViewController.view
      .accessibilityElementsHidden = NO;
}

#pragma mark - FullscreenUIElement methods

- (void)updateForFullscreenProgress:(CGFloat)progress {
  if (!self.hideToolbars) {
    [self updateHeadersForFullscreenProgress:progress];
    [self updateFootersForFullscreenProgress:progress];
  }
  if (!ios::provider::IsFullscreenSmoothScrollingSupported()) {
    [self updateBrowserViewportForFullscreenProgress:progress];
  }
}

- (void)updateForFullscreenEnabled:(BOOL)enabled {
  if (!enabled) {
    [self updateForFullscreenProgress:1.0];
  }
}

- (void)animateFullscreenWithAnimator:(FullscreenAnimator*)animator {
  // Store the current contentOffset to restore after animation
  CGPoint originalContentOffset = _lastContentOffset;
  if (self.currentWebState) {
    UIView *webView = self.currentWebState->GetView();
    if ([webView isKindOfClass:[WKWebView class]]) {
      originalContentOffset = [(WKWebView *)webView scrollView].contentOffset;
    }
  }

  // Create a weak reference to animator to avoid retain cycles
  __weak FullscreenAnimator* weakAnimator = animator;

  // Add animations to update the headers and footers.
  __weak BrowserViewController* weakSelf = self;
  [animator addAnimations:^{
    BrowserViewController* strongSelf = weakSelf;
    FullscreenAnimator* strongAnimator = weakAnimator;
    if (strongSelf && strongAnimator) {
      [strongSelf updateHeadersForFullscreenProgress:strongAnimator.finalProgress];
      [strongSelf updateFootersForFullscreenProgress:strongAnimator.finalProgress];
    }
  }];

  // Restore contentOffset in the completion block to prevent jumps
  [animator addCompletion:^(UIViewAnimatingPosition finalPosition) {
    BrowserViewController* strongSelf = weakSelf;
    FullscreenAnimator* strongAnimator = weakAnimator;
    if (!strongSelf || !strongSelf.currentWebState || !strongAnimator) {
      return;
    }
    [strongSelf updateBrowserViewportForFullscreenProgress:
                    [strongAnimator progressForAnimatingPosition:finalPosition]];
    UIView *webView = strongSelf.currentWebState->GetView();
    if ([webView isKindOfClass:[WKWebView class]]) {
      [(WKWebView *)webView scrollView].contentOffset = originalContentOffset;
      NSLog(@"animateFullscreenWithAnimator: Restored contentOffset to: %@", NSStringFromCGPoint(originalContentOffset));
    }
  }];
}

- (void)updateForFullscreenMinViewportInsets:(UIEdgeInsets)minViewportInsets
                           maxViewportInsets:(UIEdgeInsets)maxViewportInsets {
  minViewportInsets.top = self.rootSafeAreaInsets.top + kTopPadding;
  maxViewportInsets.top = self.rootSafeAreaInsets.top + kTopPadding;
  minViewportInsets.bottom = 0; // No bottom inset
  maxViewportInsets.bottom = 0; // No bottom inset
  [self updateForFullscreenProgress:self.fullscreenController->GetProgress()];
}

#pragma mark - FullscreenUIElement helpers

// The minimum amount by which the top toolbar overlaps the browser content
// area.
- (CGFloat)collapsedTopToolbarHeight {
  return self.rootSafeAreaInsets.top +
         self.toolbarCoordinator.collapsedPrimaryToolbarHeight;
}

// The minimum amount by which the bottom toolbar overlaps the browser content
// area.
- (CGFloat)collapsedBottomToolbarHeight {
  CGFloat height = self.toolbarCoordinator.collapsedSecondaryToolbarHeight;
  if (!height) {
    return 0.0;
  }
  // Height is non-zero only when bottom omnibox is enabled.
  return height;
}

// The maximum amount by which the top toolbar overlaps the browser content
// area.
- (CGFloat)expandedTopToolbarHeight {
  return [self primaryToolbarHeightWithInset] +
         (IsRegularXRegularSizeClass(self) ? self.tabStripView.frame.size.height : 0.0) +
         self.headerOffset + kTopPadding;
}

// Updates the ToolbarsSize, which broadcasts any changes to registered
// listeners.
- (void)updateToolbarState {
  _toolbarsSize.collapsedTopToolbarHeight = [self collapsedTopToolbarHeight];
  _toolbarsSize.expandedTopToolbarHeight = [self expandedTopToolbarHeight];
  _toolbarsSize.collapsedBottomToolbarHeight =
      [self collapsedBottomToolbarHeight];
  _toolbarsSize.expandedBottomToolbarHeight =
      [self secondaryToolbarHeightWithInset];
}

// Returns the height difference between the fully expanded and fully collapsed
// primary toolbar.
- (CGFloat)primaryToolbarHeightDelta {
  CGFloat fullyExpandedHeight =
      self.fullscreenController->GetMaxViewportInsets().top + kTopPadding;
  CGFloat fullyCollapsedHeight =
      self.fullscreenController->GetMinViewportInsets().top + kTopPadding;
  return std::max(0.0, fullyExpandedHeight - fullyCollapsedHeight);
}

// Returns the height difference between the fully expanded and fully collapsed
// secondary toolbar.
- (CGFloat)secondaryToolbarHeightDelta {
  CGFloat fullyExpandedHeight =
      self.fullscreenController->GetMaxViewportInsets().bottom;
  CGFloat fullyCollapsedHeight =
      self.fullscreenController->GetMinViewportInsets().bottom;
  return std::max(0.0, fullyExpandedHeight - fullyCollapsedHeight);
}

// Translates the header views up and down according to `progress`, where a
// progress of 1.0 fully shows the headers and a progress of 0.0 fully hides
// them.
- (void)updateHeadersForFullscreenProgress:(CGFloat)progress {
  CGFloat offset =
      AlignValueToPixel((1.0 - progress) * [self primaryToolbarHeightDelta]);
  [self setFramesForHeaders:[self headerViews] atOffset:offset];
}

// Translates the footer view up and down according to `progress`, where a
// progress of 1.0 fully shows the footer and a progress of 0.0 fully hides it.
- (void)updateFootersForFullscreenProgress:(CGFloat)progress {
  self.footerFullscreenProgress = progress;

  // Don't update the height of the secondary toolbar if it is hidden.
  if (!IsSplitToolbarMode(self) || self.hideToolbars) {
    if (self.hideToolbars) {
      self.secondaryToolbarHeightConstraint.constant = 0;
    }
    return;
  }

  const CGFloat expandedToolbarHeight =
      self.fullscreenController->GetMaxViewportInsets().bottom;
  if (!expandedToolbarHeight) {
    // If `expandedToolbarHeight` is 0, secondary toolbar is hidden. In that
    // case don't update its height on fullscreen progress.
    return;
  }

  // Set the height to the expanded height to ensure it remains pinned to the bottom
  self.secondaryToolbarHeightConstraint.constant = [self secondaryToolbarHeightWithInset];
}

// Updates the browser container view such that its viewport is the space
// between the primary and secondary toolbars.
- (void)updateBrowserViewportForFullscreenProgress:(CGFloat)progress {
  if (!self.currentWebState || self.ntpCoordinator.isNTPActiveForCurrentWebState) {
    return;
  }

  // Calculate top inset for Dynamic Island + padding
  CGFloat topInset = self.rootSafeAreaInsets.top + kTopPadding;

  // Calculate frame to start below Dynamic Island/status bar + padding
  CGRect viewFrame = self.contentArea.bounds;
  viewFrame.origin.y = topInset;
  viewFrame.size.height = self.contentArea.bounds.size.height - topInset;

  // Update container view and web view
  UIView *webView = self.viewForCurrentWebState;
  if (!webView) {
    return;
  }

  // Store current contentOffset
  CGPoint currentOffset = _lastContentOffset;
  if ([webView isKindOfClass:[WKWebView class]]) {
    currentOffset = [(WKWebView *)webView scrollView].contentOffset;
  }

  // Ensure container view exists
  if (!self.containerView || self.containerView != webView.superview) {
    self.containerView = [[UIView alloc] initWithFrame:viewFrame];
    self.containerView.clipsToBounds = NO; // Allow content to extend for scrolling
    [webView removeFromSuperview];
    [self.containerView addSubview:webView];
    self.browserContainerViewController.contentView = self.containerView;
    // Add KVO for web view frame
    if (webView) {
      [webView addObserver:self
                forKeyPath:@"frame"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
    }
  }

  // Always update frame to enforce correct positioning
  self.containerView.translatesAutoresizingMaskIntoConstraints = YES;
  [NSLayoutConstraint deactivateConstraints:self.containerView.constraints];
  webView.translatesAutoresizingMaskIntoConstraints = YES;
  [NSLayoutConstraint deactivateConstraints:webView.constraints];
  [webView.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
    subview.translatesAutoresizingMaskIntoConstraints = YES;
    [NSLayoutConstraint deactivateConstraints:subview.constraints];
  }];
  self.containerView.frame = viewFrame;
  self.containerView.bounds = viewFrame;
  webView.frame = self.containerView.bounds;
  webView.bounds = self.containerView.bounds;

  // Configure scroll view
  if ([webView isKindOfClass:[WKWebView class]]) {
    UIScrollView *scrollView = [(WKWebView *)webView scrollView];
    [self configureScrollView:scrollView];
    scrollView.contentOffset = currentOffset; // Restore offset
  }

  // Log frame to detect overrides
  NSLog(@"updateBrowserViewport: Container view frame: %@", NSStringFromCGRect(self.containerView.frame));
  NSLog(@"updateBrowserViewport: Web view frame: %@", NSStringFromCGRect(webView.frame));
  NSLog(@"updateBrowserViewport: Restored contentOffset: %@", NSStringFromCGPoint(currentOffset));
  dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"updateBrowserViewport: Container view frame after update: %@", NSStringFromCGRect(self.containerView.frame));
    NSLog(@"updateBrowserViewport: Web view frame after update: %@", NSStringFromCGRect(webView.frame));
  });
}

// Updates the padding of the web view proxy. This either resets the frame of
// the WKWebView or the contentInsets of the WKWebView's UIScrollView, depending
// on the proxy's `shouldUseViewContentInset` property.
- (void)updateContentPaddingForTopToolbarHeight:(CGFloat)topToolbarHeight
                            bottomToolbarHeight:(CGFloat)bottomToolbarHeight {
  if (!self.currentWebState) {
    return;
  }

  UIView *webView = self.currentWebState->GetView();
  if ([webView isKindOfClass:[WKWebView class]]) {
    // Store current contentOffset
    CGPoint currentOffset = [(WKWebView *)webView scrollView].contentOffset;

    // Set insets to zero to allow content to stretch to edges
    UIEdgeInsets contentPadding = UIEdgeInsetsZero;
    [(WKWebView *)webView scrollView].contentInset = contentPadding;
    [(WKWebView *)webView scrollView].scrollIndicatorInsets = contentPadding;
    [(WKWebView *)webView scrollView].contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    // Restore contentOffset to prevent jump
    [(WKWebView *)webView scrollView].contentOffset = currentOffset;

    // Reapply toolbar-adjusted frame for non-NTP pages to prevent override
    if (!self.ntpCoordinator.isNTPActiveForCurrentWebState) {
      UIView *containerView = webView.superview;
      if (!containerView || containerView == self.contentArea) {
        containerView = [[UIView alloc] initWithFrame:self.contentArea.bounds];
        containerView.clipsToBounds = NO; // Allow content to extend for scrolling
        [webView removeFromSuperview];
        [containerView addSubview:webView];
        self.browserContainerViewController.contentView = containerView;
        // Add KVO for web view frame
        if (webView) {
          [webView addObserver:self
                    forKeyPath:@"frame"
                       options:NSKeyValueObservingOptionNew
                       context:nil];
        }
      }

      // Calculate frame to start below Dynamic Island/status bar + padding
      CGFloat topInset = self.rootSafeAreaInsets.top + kTopPadding;
      CGRect viewFrame = self.contentArea.bounds;
      viewFrame.origin.y = topInset;
      viewFrame.size.height = self.contentArea.bounds.size.height - topInset;

      // Only update frame if it has changed
      if (!CGRectEqualToRect(containerView.frame, viewFrame)) {
        containerView.frame = viewFrame;
        containerView.bounds = viewFrame;
        webView.frame = containerView.bounds;
        webView.bounds = containerView.bounds;

        // Restore contentOffset again
        [(WKWebView *)webView scrollView].contentOffset = currentOffset;

        UIScrollView *scrollView = [(WKWebView *)webView scrollView];
        scrollView.clipsToBounds = NO;
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        scrollView.contentInset = UIEdgeInsetsZero;
        scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
        scrollView.delegate = self;
        // Force contentSize to match frame height
        if (scrollView.contentSize.height < viewFrame.size.height) {
          scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, viewFrame.size.height);
          NSLog(@"updateContentPadding: Forced contentSize height to %f", viewFrame.size.height);
        }
      }
    }
  }
}

- (CGFloat)currentHeaderOffset {
  NSArray<HeaderDefinition*>* headers = [self headerViews];
  if (!headers.count) {
    return 0.0;
  }

  // Prerender tab does not have a toolbar, return `headerHeight` as promised by
  // API documentation.
  if ([self.toolbarCoordinator isLoadingPrerenderer]) {
    return self.headerHeight;
  }

  UIView* topHeader = headers[0].view;
  return -(topHeader.frame.origin.y - self.headerOffset);
}

#pragma mark - MainContentUI

- (MainContentUIState*)mainContentUIState {
  return _mainContentUIState;
}

#pragma mark - OmniboxFocusDelegate (Public)

- (void)omniboxDidBecomeFirstResponder {
  if (self.ntpCoordinator.isNTPActiveForCurrentWebState) {
    [self.ntpCoordinator locationBarDidBecomeFirstResponder];
  }
  [_sideSwipeCoordinator setEnabled:NO];

  if (!IsVisibleURLNewTabPage(self.currentWebState) ||
      ui::GetDeviceFormFactor() == ui::DEVICE_FORM_FACTOR_TABLET) {
    // Tapping on web content area should dismiss the keyboard. Tapping on NTP
    // gesture should propagate to NTP view.
    [self.view insertSubview:self.typingShield aboveSubview:self.contentArea];
    [self.typingShield setAlpha:0.0];
    [self.typingShield setHidden:NO];
    self.typingShield.userInteractionEnabled = YES; // Enable interaction only when visible
    [UIView animateWithDuration:0.3
                     animations:^{
                       [self.typingShield setAlpha:1.0];
                     }];
  }

  [self.toolbarCoordinator transitionToLocationBarFocusedState:YES
                                                    completion:nil];
}

- (void)omniboxDidResignFirstResponder {
  [_sideSwipeCoordinator setEnabled:YES];

  [self.ntpCoordinator locationBarWillResignFirstResponder];

  [UIView animateWithDuration:0.3
      animations:^{
        [self.typingShield setAlpha:0.0];
      }
      completion:^(BOOL finished) {
        // This can happen if one quickly resigns the omnibox and then taps
        // on the omnibox again during this animation. If the animation is
        // interrupted and the toolbar controller is first responder, it's safe
        // to assume `self.typingShield` shouldn't be hidden here.
        if (!finished && [self.toolbarCoordinator isOmniboxFirstResponder]) {
          return;
        }
        [self.typingShield setHidden:YES];
        self.typingShield.userInteractionEnabled = NO; // Disable interaction when hidden
      }];

  ProceduralBlock completion = ^{
    // Show the NTP's fake toolbar after the defocus animation completes.
    [self.ntpCoordinator locationBarDidResignFirstResponder];
  };

  [self.toolbarCoordinator transitionToLocationBarFocusedState:NO
                                                    completion:completion];
}

#pragma mark - BrowserCommands

- (void)dismissSoftKeyboard {
  if (self.visibilityState != BrowserViewVisibilityState::kNotInViewHierarchy ||
      self.dismissingModal) {
    [self.viewForCurrentWebState endEditing:NO];
  }
}

#pragma mark - TabConsumer (Public)

- (void)resetTab {
  self.browserContainerViewController.contentView = nil;
}

- (void)prepareForNewTabAnimation {
  [self dismissPopups];
}

- (void)webStateSelected {
  // Ignore changes while the tab stack view is visible (or while suspended).
  // The display will be refreshed when this view becomes active again.
  if (self.visibilityState == BrowserViewVisibilityState::kNotInViewHierarchy ||
      !self.webUsageEnabled) {
    return;
  }

  if (!self.currentWebState || !self.viewForCurrentWebState) {
    NSLog(@"webStateSelected: No valid web state or view, skipping displayTabView");
    return;
  }

  [self displayTabView];
  if (!self.inNewTabAnimation) {
    _pagePlaceholderBrowserAgent->CancelPagePlaceholder();
  }
}

- (void)displayTabViewIfActive {
  if (self.active && self.currentWebState && self.viewForCurrentWebState) {
    [self displayTabView];
  }
}

- (void)initiateNewTabForegroundAnimationForWebState:(web::WebState*)webState {
  // Initiates the new tab foreground animation, which is phone-specific.
  if (IsRegularXRegularSizeClass(self)) {
    if (self.foregroundTabWasAddedCompletionBlock) {
      // This callback is called before webState is activated. Dispatch the
      // callback asynchronously to be sure the activation is complete.
      __weak BrowserViewController* weakSelf = self;
      base::SequencedTaskRunner::GetCurrentDefault()->PostTask(
          FROM_HERE, base::BindOnce(^{
            [weakSelf executeAndClearForegroundTabWasAddedCompletionBlock:YES];
          }));
    }
    return;
  }
  // Do nothing if browsing is currently suspended. The BVC will set everything
  // up correctly when browsing resumes.
  if (self.visibilityState == BrowserViewVisibilityState::kNotInViewHierarchy ||
      !self.webUsageEnabled) {
    return;
  }

  self.inNewTabAnimation = YES;
  __weak __typeof(self) weakSelf = self;
  [self animateNewTabForWebState:webState
      inForegroundWithCompletion:^{
        [weakSelf startVoiceSearchIfNecessary];
      }];
}

- (void)initiateNewTabBackgroundAnimation {
  if (self.foregroundTabWasAddedCompletionBlock) {
    // This callback is called before webState is activated. Dispatch the
    // callback asynchronously to be sure the activation is complete.
    __weak BrowserViewController* weakSelf = self;
    base::SequencedTaskRunner::GetCurrentDefault()->PostTask(
        FROM_HERE, base::BindOnce(^{
          [weakSelf executeAndClearForegroundTabWasAddedCompletionBlock:NO];
        }));
  }
  self.inNewTabAnimation = NO;
}

- (void)switchToTabAnimationPosition:(SwitchToTabAnimationPosition)position
                   snapshotTabHelper:(SnapshotTabHelper*)snapshotTabHelper
                  willAddPlaceholder:(BOOL)willAddPlaceholder
                 newTabPageTabHelper:(NewTabPageTabHelper*)NTPHelper
                     topToolbarImage:(UIImage*)topToolbarImage
                  bottomToolbarImage:(UIImage*)bottomToolbarImage {
  if (IsRegularXRegularSizeClass(self)) {
    return;
  }

  // Add animations only if the tab strip isn't shown.
  UIView* snapshotView = [self.view snapshotViewAfterScreenUpdates:NO];

  SwipeView* swipeView = [[SwipeView alloc]
      initWithFrame:self.contentArea.frame
          topMargin:self.rootSafeAreaInsets.top + kTopPadding];

  [swipeView setTopToolbarImage:topToolbarImage];
  [swipeView setBottomToolbarImage:bottomToolbarImage];

  snapshotTabHelper->RetrieveColorSnapshot(^(UIImage* image) {
    willAddPlaceholder ? [swipeView setImage:nil] : [swipeView setImage:image];
  });

  SwitchToTabAnimationView* animationView =
      [[SwitchToTabAnimationView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:animationView];

  [animationView animateFromCurrentView:snapshotView
                              toNewView:swipeView
                             inPosition:position];
}

- (void)dismissBookmarkModalController {
  [_bookmarksCoordinator dismissBookmarkModalControllerAnimated:YES];
}

#pragma mark - TabConsumer helpers

// Helper which execute and then clears `foregroundTabWasAddedCompletionBlock`
// if it is still set, or does nothing.
- (void)executeAndClearForegroundTabWasAddedCompletionBlock:(BOOL)animated {
  // Test existence again as the block may have been deleted.
  ProceduralBlock completion = self.foregroundTabWasAddedCompletionBlock;
  if (!completion) {
    return;
  }

  // Clear the property before executing the completion, in case the
  // completion calls appendTabAddedCompletion:tabAddedCompletion.
  // Clearing the property after running the completion would cause any
  // newly appended completion to be immediately cleared without ever
  // getting run. An example where this would happen is when opening
  // multiple tabs via the "Open URLs in Chrome" Siri Shortcut.
  self.foregroundTabWasAddedCompletionBlock = nil;
  if (animated) {
    completion();
  } else {
    [UIView performWithoutAnimation:^{
      completion();
    }];
  }
}

// Helper which starts voice search at the end of new Tab animation if
// necessary.
- (void)startVoiceSearchIfNecessary {
  if (_startVoiceSearchAfterNewTabAnimation) {
    _startVoiceSearchAfterNewTabAnimation = NO;
    [self startVoiceSearch];
    [IntentDonationHelper donateIntent:IntentType::kOpenVoiceSearch];
  }
}

- (void)animateNewTabForWebState:(web::WebState*)webState
      inForegroundWithCompletion:(ProceduralBlock)completion {
  // Create the new page image, and load with the new tab snapshot except if
  // it is the NTP.
  UIView* newPage = [self viewForWebState:webState];
  if (!newPage) {
    NSLog(@"animateNewTabForWebState: No valid view for web state, skipping animation");
    if (completion) {
      completion();
    }
    return;
  }
  GURL tabURL = webState->GetVisibleURL();
  // Toolbar snapshot is only used for the UIRefresh animation.
  UIView* toolbarSnapshot;

  if (tabURL == kChromeUINewTabURL && !_isOffTheRecord &&
      !IsRegularXRegularSizeClass(self)) {
    // Add a snapshot of the primary toolbar to the background as the
    // animation runs.
    UIViewController* toolbarViewController =
        self.toolbarCoordinator.primaryToolbarViewController;
    toolbarSnapshot =
        [toolbarViewController.view snapshotViewAfterScreenUpdates:NO];
    toolbarSnapshot.frame = [self.contentArea convertRect:toolbarSnapshot.frame
                                                 fromView:self.view];
    [self.contentArea addSubview:toolbarSnapshot];
    newPage.frame = self.view.bounds;
  } else {
    if (self.ntpCoordinator.isNTPActiveForCurrentWebState &&
        self.webUsageEnabled) {
      newPage.frame = [self ntpFrameForCurrentWebState];
    } else {
            // Set frame to start at top of content area for clickability
      CGFloat topInset = 0; // No offset to allow touches near Dynamic Island
      CGRect viewFrame = self.contentArea.bounds;
      viewFrame.origin.y = topInset;
      viewFrame.size.height = self.contentArea.bounds.size.height;

      // Store current contentOffset if available
      CGPoint currentOffset = _lastContentOffset;
      if ([newPage isKindOfClass:[WKWebView class]]) {
        currentOffset = [(WKWebView *)newPage scrollView].contentOffset;
      }
      newPage.translatesAutoresizingMaskIntoConstraints = YES;
      [NSLayoutConstraint deactivateConstraints:newPage.constraints];
      [newPage.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        subview.translatesAutoresizingMaskIntoConstraints = YES;
        [NSLayoutConstraint deactivateConstraints:subview.constraints];
      }];
      // Wrap in a container view
      UIView *containerView = [[UIView alloc] initWithFrame:viewFrame];
      containerView.clipsToBounds = NO; // Allow content to extend for scrolling
      [newPage removeFromSuperview];
      [containerView addSubview:newPage];
      newPage.frame = containerView.bounds;
      newPage.bounds = containerView.bounds;
      // Restore contentOffset
      if ([newPage isKindOfClass:[WKWebView class]]) {
        [(WKWebView *)newPage scrollView].contentOffset = currentOffset;
        [(WKWebView *)newPage scrollView].contentInset = UIEdgeInsetsZero;
        [(WKWebView *)newPage scrollView].scrollIndicatorInsets = UIEdgeInsetsZero;
        [(WKWebView *)newPage scrollView].contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        // Force contentSize to match frame height
        UIScrollView *scrollView = [(WKWebView *)newPage scrollView];
        if (scrollView.contentSize.height < viewFrame.size.height) {
          scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, viewFrame.size.height);
          NSLog(@"animateNewTabForWebState: Forced contentSize height to %f", viewFrame.size.height);
        }
      }
      newPage = containerView;
      // Add KVO for web view frame
      if (newPage.subviews.firstObject) {
        [newPage.subviews.firstObject addObserver:self
                                       forKeyPath:@"frame"
                                          options:NSKeyValueObservingOptionNew
                                          context:nil];
      }
      NSLog(@"animateNewTabForWebState: Set non-NTP container frame: %@", NSStringFromCGRect(newPage.frame));
      NSLog(@"animateNewTabForWebState: Restored contentOffset: %@", NSStringFromCGPoint(currentOffset));
    }
  }
  newPage.userInteractionEnabled = NO;
  NSInteger currentAnimationIdentifier = ++_NTPAnimationIdentifier;

  // Cleanup steps needed for both UI Refresh and stack-view style animations.
  UIView* webStateView = [self viewForWebState:webState];
  __weak __typeof(self) weakSelf = self;
  auto commonCompletion = ^{
    __strong __typeof(self) strongSelf = weakSelf;
    newPage.userInteractionEnabled = YES;

    // Check for nil because we need to access an ivar below.
    if (!strongSelf) {
      return;
    }

    // Reapply toolbar-adjusted frame for non-NTP pages
    if (!strongSelf.ntpCoordinator.isNTPActiveForCurrentWebState && webStateView) {
      // Store current contentOffset if available
      CGPoint currentOffset = strongSelf->_lastContentOffset;
      if ([webStateView isKindOfClass:[WKWebView class]]) {
        currentOffset = [(WKWebView *)webStateView scrollView].contentOffset;
      }

      CGFloat topInset = strongSelf.rootSafeAreaInsets.top + kTopPadding;
      CGRect viewFrame = strongSelf.contentArea.bounds;
      viewFrame.origin.y = topInset;
      viewFrame.size.height = strongSelf.contentArea.bounds.size.height - topInset;

      UIView *containerView = webStateView.superview;
      if (!containerView || containerView == strongSelf.contentArea) {
        containerView = [[UIView alloc] initWithFrame:viewFrame];
        containerView.clipsToBounds = NO; // Allow content to extend for scrolling
        [webStateView removeFromSuperview];
        [containerView addSubview:webStateView];
        strongSelf.browserContainerViewController.contentView = containerView;
        // Add KVO for web view frame
        if (webStateView) {
          [webStateView addObserver:strongSelf
                         forKeyPath:@"frame"
                            options:NSKeyValueObservingOptionNew
                            context:nil];
        }
      }
      // Only update frame if it has changed
      if (!CGRectEqualToRect(containerView.frame, viewFrame)) {
        containerView.translatesAutoresizingMaskIntoConstraints = YES;
        [NSLayoutConstraint deactivateConstraints:containerView.constraints];
        webStateView.translatesAutoresizingMaskIntoConstraints = YES;
        [NSLayoutConstraint deactivateConstraints:webStateView.constraints];
        [webStateView.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
          subview.translatesAutoresizingMaskIntoConstraints = YES;
          [NSLayoutConstraint deactivateConstraints:subview.constraints];
        }];
        containerView.frame = viewFrame;
        containerView.bounds = viewFrame;
        webStateView.frame = containerView.bounds;
        webStateView.bounds = containerView.bounds;

        // Restore contentOffset
        if ([webStateView isKindOfClass:[WKWebView class]]) {
          [(WKWebView *)webStateView scrollView].contentOffset = currentOffset;
          [(WKWebView *)webStateView scrollView].contentInset = UIEdgeInsetsZero;
          [(WKWebView *)webStateView scrollView].scrollIndicatorInsets = UIEdgeInsetsZero;
          [(WKWebView *)webStateView scrollView].contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
          // Force contentSize to match frame height
          UIScrollView *scrollView = [(WKWebView *)webStateView scrollView];
          if (scrollView.contentSize.height < viewFrame.size.height) {
            scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, viewFrame.size.height);
            NSLog(@"animateNewTabForWebState: Forced contentSize height to %f in completion", viewFrame.size.height);
          }
        }

        NSLog(@"animateNewTabForWebState: Reapplied non-NTP container frame: %@", NSStringFromCGRect(containerView.frame));
        NSLog(@"animateNewTabForWebState: Restored contentOffset: %@", NSStringFromCGPoint(currentOffset));
      }
    } else if (webStateView != newPage) {
      webStateView.frame = strongSelf.contentArea.bounds;
    }

    if (currentAnimationIdentifier != strongSelf->_NTPAnimationIdentifier) {
      // Prevent the completion block from being executed if a new animation has
      // started in between. `self.foregroundTabWasAddedCompletionBlock` isn't
      // called because it is overridden when a new animation is started.
      // Calling it here would call the block from the latest animation that
      // have started.
      return;
    }

    strongSelf.inNewTabAnimation = NO;

    [strongSelf webStateSelected];
    if (completion) {
      completion();
    }

    [strongSelf executeAndClearForegroundTabWasAddedCompletionBlock:YES];
  };

  // Skip animation if animations are disabled (e.g. new search action from
  // toolbar).
  if (!UIView.areAnimationsEnabled) {
    [toolbarSnapshot removeFromSuperview];
    commonCompletion();
    return;
  }

  CGPoint origin = [self lastTapPoint];

  CGRect frame = [self.contentArea convertRect:self.view.bounds
                                      fromView:self.view];
  frame.origin.y += self.rootSafeAreaInsets.top + kTopPadding;
  ForegroundTabAnimationView* animatedView =
      [[ForegroundTabAnimationView alloc] initWithFrame:frame];
  animatedView.contentView = newPage;
  __weak UIView* weakAnimatedView = animatedView;
  auto completionBlock = ^() {
    [weakAnimatedView removeFromSuperview];
    [toolbarSnapshot removeFromSuperview];
    commonCompletion();
  };
  [self.contentArea addSubview:animatedView];
  [animatedView animateFrom:origin withCompletion:completionBlock];
}

#pragma mark - IncognitoReauthConsumer

- (void)setItemsRequireAuthentication:(BOOL)require {
  _itemsRequireAuthentication = require;
  if (require) {
    if (!self.blockingView) {
      self.blockingView = [[IncognitoReauthView alloc] init];
      self.blockingView.translatesAutoresizingMaskIntoConstraints = NO;
      self.blockingView.layer.zPosition = FLT_MAX;

      DCHECK(self.reauthHandler);
      [self.blockingView.authenticateButton
                 addTarget:self.reauthHandler
                    action:@selector(authenticateIncognitoContent)
          forControlEvents:UIControlEventTouchUpInside];

      DCHECK(self.applicationCommandsHandler);
      __weak __typeof(self) weakSelf = self;
      [self.blockingView.tabSwitcherButton
                 addAction:[UIAction actionWithHandler:^(UIAction* action) {
                   if (IsIOSSoftLockEnabled()) {
                     base::UmaHistogramEnumeration(
                         kIncognitoLockOverlayInteractionHistogram,
                         IncognitoLockOverlayInteraction::
                             kSeeOtherTabsButtonClicked);
                     base::RecordAction(base::UserMetricsAction(
                         "IOS.IncognitoLock.Overlay.SeeOtherTabs"));
                   }
                   [weakSelf.applicationCommandsHandler
                       displayTabGridInMode:TabGridOpeningMode::kRegular];
                 }]
          forControlEvents:UIControlEventTouchUpInside];

      if (IsIOSSoftLockEnabled()) {
        base::WeakPtr<WebStateList> webStateList = _webStateList;
        id<IncognitoReauthCommands> reauthHandler = self.reauthHandler;
        [self.blockingView.exitIncognitoButton
                   addAction:[UIAction actionWithHandler:^(UIAction* action) {
                     if (IsIOSSoftLockEnabled()) {
                       base::UmaHistogramEnumeration(
                           kIncognitoLockOverlayInteractionHistogram,
                           IncognitoLockOverlayInteraction::
                               kCloseIncognitoTabsButtonClicked);
                       base::RecordAction(base::UserMetricsAction(
                           "IOS.IncognitoLock.Overlay.CloseIncognitoTabs"));
                     }
                     if (webStateList) {
                       CloseAllWebStates(*(webStateList),
                                         WebStateList::CLOSE_USER_ACTION);
                     }
                     [reauthHandler manualAuthenticationOverride];
                   }]
            forControlEvents:UIControlEventTouchUpInside];
      }
    }

    [self.view addSubview:self.blockingView];
    AddSameConstraints(self.view, self.blockingView);
    self.blockingView.alpha = 1;
    [self.omniboxCommandsHandler cancelOmniboxEdit];
    // Resign the first responder. This achieves multiple goals:
    // 1. The keyboard is dismissed.
    // 2. Hardware keyboard events (such as space to scroll) will be ignored.
    UIResponder* firstResponder = GetFirstResponder();
    [firstResponder resignFirstResponder];
    // Close presented view controllers, e.g. share sheets.
    if (self.presentedViewController) {
      [self.applicationCommandsHandler dismissModalDialogsWithCompletion:nil];
    }

  } else {
    [UIView animateWithDuration:0.2
        animations:^{
          self.blockingView.alpha = 0;
        }
        completion:^(BOOL finished) {
          // In an extreme case, this method can be called twice in quick
          // succession, before the animation completes. Check if the blocking
          // UI should be shown or the animation needs to be rolled back.
          if (self->_itemsRequireAuthentication) {
            self.blockingView.alpha = 1;
          } else {
            [self.blockingView removeFromSuperview];
          }
        }];
  }
}

- (void)setItemsRequireAuthentication:(BOOL)require
                withPrimaryButtonText:(NSString*)text
                   accessibilityLabel:(NSString*)accessibilityLabel {
  [self setItemsRequireAuthentication:require];
  if (require) {
    [self.blockingView setAuthenticateButtonText:text
                              accessibilityLabel:accessibilityLabel];
  } else {
    // No primary button text or accessibility label should be set when
    // authentication is not required.
    CHECK(!text);
    CHECK(!accessibilityLabel);
  }
}

#pragma mark - Swipe Gesture Handling

- (void)handleRightToLeftSwipe:(UISwipeGestureRecognizer*)gesture {
  if (gesture.state == UIGestureRecognizerStateEnded) {
    NSLog(@"Right-to-left swipe detected");

    // Present URLInputViewController with slide animation
    URLInputViewController* menuVC = [[URLInputViewController alloc] init];
    menuVC.toolbarCoordinator = self.toolbarCoordinator; // Pass toolbar coordinator
    menuVC.delegate = self; // Set delegate to handle URL submission
    menuVC.modalPresentationStyle = UIModalPresentationCustom;
    // Use URLInputTransitioningDelegate to manage the slide transition
    URLInputTransitioningDelegate* transitioningDelegate = [[URLInputTransitioningDelegate alloc] init];
    menuVC.transitioningDelegate = transitioningDelegate;
    [self presentViewController:menuVC animated:YES completion:^{
      NSLog(@"URLInputViewController presented with frame: %@", NSStringFromCGRect(menuVC.view.frame));
      NSLog(@"URLInputViewController view hierarchy: %@", menuVC.view.subviews);
    }];
  }
}

// URLInputViewControllerDelegate method to handle URL submission
- (void)urlInputViewController:(URLInputViewController*)controller didEnterURL:(NSURL*)url {
  if (self.currentWebState && url) {
    web::NavigationManager::WebLoadParams params(net::GURLWithNSURL(url));
    params.transition_type = ui::PAGE_TRANSITION_TYPED;
    self.currentWebState->GetNavigationManager()->LoadURLWithParams(params);
    NSLog(@"Loading URL from swipe menu: %@", url);
  } else {
    NSLog(@"Failed to load URL: No web state or invalid URL");
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  // Allow the pan gesture recognizer to work with other gestures
  if (gestureRecognizer == self.contentPanGestureRecognizer) {
    return YES;
  }
  // Existing logic for swipe gestures
  if ([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]] &&
      [(UISwipeGestureRecognizer *)gestureRecognizer direction] == UISwipeGestureRecognizerDirectionLeft) {
    return NO; // Custom swipe takes precedence
  }
  return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gesture {
  if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
    CGPoint location = [gesture locationInView:self.view];
    // Only allow touches on descendant views of `contentArea`.
    UIView* hitView = [self.view hitTest:location withEvent:nil];
    return [hitView isDescendantOfView:self.contentArea];
  }
  return YES; // Allow swipe gestures to begin
}

#pragma mark - CardSwipeViewDelegate

- (void)sideSwipeViewDismissAnimationDidEnd:(UIView*)sideSwipeView {
  DCHECK(!IsRegularXRegularSizeClass(self));
  // TODO(crbug.com/40842406): Signal to the toolbar coordinator to perform this
  // update. Longer-term, make SideSwipeMediatorDelegate observable instead of
  // delegating.
  [self.toolbarCoordinator updateToolbar];

  // Reset horizontal stack view.
  [sideSwipeView removeFromSuperview];
  [_sideSwipeCoordinator setSwipeInProgress:NO];
}

#pragma mark - SideSwipeUIControllerDelegate

- (UIView*)sideSwipeFullscreenView {
  return self.view;
}

- (UIView*)sideSwipeContentView {
  return self.contentArea;
}

- (void)sideSwipeRedisplayTabView {
  [self displayTabView];
}

- (BOOL)preventSideSwipe {
  if ([self.popupMenuCoordinator isShowingPopupMenu]) {
    return YES;
  }

  if (_voiceSearchController.visible) {
    return YES;
  }

  if (!self.active) {
    return YES;
  }

  BOOL isShowingIncognitoBlocker = (self.blockingView.superview != nil);
  if (isShowingIncognitoBlocker) {
    return YES;
  }

  return NO;
}

- (void)updateAccessoryViewsForSideSwipeWithVisibility:(BOOL)visible {
  if (visible) {
    // TODO(crbug.com/40842406): Signal to the toolbar coordinator to perform
    // this update. Longer-term, make SideSwipeMediatorDelegate observable
    // instead of delegating.
    [self.toolbarCoordinator updateToolbar];
  } else {
    // Hide UI accessories such as find bar and first visit overlays
    // for welcome page.
    [self.findInPageCommandsHandler hideFindUI];
    [self.textZoomHandler hideTextZoomUI];
  }
}

- (CGFloat)headerHeightForSideSwipe {
  // If the toolbar is hidden, only inset the side swipe navigation view by
  // `safeAreaInsets.top` + padding. Otherwise insetting by `self.headerHeight`
  // would show a grey strip where the toolbar would normally be.
  if (self.toolbarCoordinator.primaryToolbarViewController.view.hidden) {
    return self.rootSafeAreaInsets.top + kTopPadding;
  }
  return self.headerHeight + kTopPadding;
}

- (BOOL)canBeginToolbarSwipe {
  return ![self.toolbarCoordinator isOmniboxFirstResponder] &&
         ![self.toolbarCoordinator showingOmniboxPopup];
}

- (UIView*)topToolbarView {
  return self.toolbarCoordinator.primaryToolbarViewController.view;
}

#pragma mark - ToolbarHeightDelegate

- (void)toolbarsHeightChanged {
  if (![self isViewLoaded]) {
    return;
  }

  // Toolbars size must be updated before
  // `updateFootersForFullscreenProgress` as the later uses the insets from
  // fullscreen model.
  [self updateToolbarState];

  self.primaryToolbarHeightConstraint.constant =
      [self primaryToolbarHeightWithInset];
  self.secondaryToolbarHeightConstraint.constant =
      [self secondaryToolbarHeightWithInset];
  [self updateForFullscreenProgress:self.footerFullscreenProgress];
}

- (void)secondaryToolbarMovedAboveKeyboard {
  // Lower the height constraint priority temporarily to allow UIKeyboardLayoutGuide
  // to move the toolbar above the keyboard.
  self.secondaryToolbarHeightConstraint.priority = UILayoutPriorityDefaultHigh;
  // Re-apply bottom constraint to ensure it stays at the bottom when keyboard is dismissed
  UIView* toolbarView = self.toolbarCoordinator.secondaryToolbarViewController.view;
  [NSLayoutConstraint deactivateConstraints:@[toolbarView.constraints.lastObject]];
  [NSLayoutConstraint activateConstraints:@[
    [toolbarView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];
}

- (void)secondaryToolbarRemovedFromKeyboard {
  // Restore required priority and re-apply bottom constraint
  self.secondaryToolbarHeightConstraint.priority = UILayoutPriorityRequired;
  UIView* toolbarView = self.toolbarCoordinator.secondaryToolbarViewController.view;
  [NSLayoutConstraint deactivateConstraints:@[toolbarView.constraints.lastObject]];
  [NSLayoutConstraint activateConstraints:@[
    [toolbarView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];
}

#pragma mark - LogoAnimationControllerOwnerOwner (Public)

- (id<LogoAnimationControllerOwner>)logoAnimationControllerOwner {
  return _logoAnimationControllerOwner;
}

#pragma mark - FindBarPresentationDelegate

- (void)setHeadersForFindBarCoordinator:
    (FindBarCoordinator*)findBarCoordinator {
  [self setFramesForHeaders:[self headerViews]
                   atOffset:[self currentHeaderOffset]];
}

- (void)findBarDidAppearForFindBarCoordinator:
    (FindBarCoordinator*)findBarCoordinator {
  // When the Find bar is presented, hide underlying elements from VoiceOver.
  self.contentArea.accessibilityElementsHidden = YES;
  self.toolbarCoordinator.primaryToolbarViewController.view
      .accessibilityElementsHidden = YES;
  self.toolbarCoordinator.secondaryToolbarViewController.view
      .accessibilityElementsHidden = YES;
}

- (void)findBarDidDisappearForFindBarCoordinator:
    (FindBarCoordinator*)findBarCoordinator {
  // When the Find bar is dismissed, show underlying elements to VoiceOver.
  self.contentArea.accessibilityElementsHidden = NO;
  self.toolbarCoordinator.primaryToolbarViewController.view
      .accessibilityElementsHidden = NO;
  self.toolbarCoordinator.secondaryToolbarViewController.view
      .accessibilityElementsHidden = NO;
}

#pragma mark - ContextualSheetPresenter Protocol Implementation

- (void)insertContextualSheet:(UIView*)contextualSheet {
  // Add the contextual sheet as a subview to the main view
  [self.view addSubview:contextualSheet];
  // Set up basic constraints to center the sheet and size it relative to the view
  contextualSheet.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [contextualSheet.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [contextualSheet.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                             constant:self.rootSafeAreaInsets.top + kTopPadding],
    [contextualSheet.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.9],
    [contextualSheet.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.5]
  ]];
}

#pragma mark - LensPresentationDelegate

- (CGRect)webContentAreaForLensCoordinator:(LensCoordinator*)lensCoordinator {
  DCHECK(lensCoordinator);
  // Return the bounds of the content area adjusted for Dynamic Island/status bar
  CGRect frame = self.contentArea.bounds;
  frame.origin.y = self.rootSafeAreaInsets.top + kTopPadding;
  frame.size.height -= frame.origin.y;
  return frame;
}

@end