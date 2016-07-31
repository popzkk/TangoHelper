#import "THPlayViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THPlayManager.h"
#import "Backend/THPlaylist.h"
#import "Keyboard/THKeyboard.h"
#import "Shared/THHelpers.h"
#import "Shared/THStrings.h"
#import "THPlaylistsViewController.h"

#pragma mark - THPlayViewController

static CGFloat kPadding = 20;
static CGFloat kTextViewTopMargin = 20;
static CGFloat kTextFieldTopMargin = 5;
static CGFloat kTextFieldHeight = 35;

@interface THPlayViewController ()<THKeyboardDelegate, THPlayManagerDelegate>

@end

@implementation THPlayViewController {
  THPlayManager *_manager;
  UITextView *_textView;
  UITextField *_textField;
  THKeyboard *_keyboard;
}

#pragma mark - public

- (instancetype)initWithPlaylist:(THPlaylist *)playlist {
  self = [super init];
  if (self) {
    if (!playlist) {
      NSLog(@"Internal error: try to play a nil playlist");
      return nil;
    }
    _manager = [[THPlayManager alloc] initWithPlaylist:playlist
                                                config:[[THPlayConfig alloc] init]
                                              delegate:self];
    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _textView.font = zh_medium_big();
    _textView.layer.borderWidth = 1;
    _textView.layer.borderColor = grey_color().CGColor;
    _textView.textAlignment = NSTextAlignmentCenter;
    _textView.userInteractionEnabled = NO;
    _textField = [[UITextField alloc] initWithFrame:CGRectZero];
    _textField.font = ja_regular_small();
    _textField.textAlignment = NSTextAlignmentCenter;
    _textField.layer.borderWidth = 1;
    _textField.layer.borderColor = grey_color().CGColor;
    _keyboard = [THKeyboard sharedInstanceWithKeyboardType:kTHKeyboardUnknown
                                                actionText:kNext
                                                  delegate:self];
    [self.view addSubview:_textView];
    [self.view addSubview:_textField];
    [self.view addSubview:_keyboard];
    self.title = playing_title(playlist.partialName);
  }
  return self;
}

#pragma mark - private

- (BOOL)canAddPlaylistWithPartialName:(NSString *)partialName {
  return ![[THFileCenter sharedInstance] playlistWithPartialName:partialName create:NO];
}

- (void)playlistDialogAddTextFieldDidChange {
  UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
  if (alertController) {
    NSString *partialName = alertController.textFields.firstObject.text;
    UIAlertAction *action = alertController.actions.lastObject;
    action.enabled = partialName.length && [self canAddPlaylistWithPartialName:partialName];
  }
}

- (UIAlertController *)wrapPlaylistDialogAdd:(UIAlertController *)alert {
  alert.actions.lastObject.enabled = NO;
  [alert.textFields.firstObject addTarget:self
                                   action:@selector(playlistDialogAddTextFieldDidChange)
                         forControlEvents:UIControlEventEditingChanged];
  return alert;
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.toolbarHidden = YES;
}

- (void)viewWillLayoutSubviews {
  CGRect frame = CGRectMake(
      0, self.navigationController.navigationBar.frame.size.height, self.view.bounds.size.width,
      self.view.bounds.size.height - self.navigationController.navigationBar.frame.size.height);
  // height for keyboard + text field
  CGFloat height = (frame.size.height - 2 * kPadding) / 2;
  _textView.frame =
      CGRectMake(frame.origin.x + kPadding, frame.origin.y + kPadding + kTextViewTopMargin,
                 frame.size.width - 2 * kPadding, height - kTextViewTopMargin);
  _textField.frame = CGRectMake(
      frame.origin.x + kPadding, frame.origin.y + kPadding + height + kTextFieldTopMargin,
      frame.size.width - 2 * kPadding, kTextFieldHeight - kTextFieldTopMargin);
  _keyboard.frame =
      CGRectMake(frame.origin.x + kPadding, frame.origin.y + kPadding + height + kTextFieldHeight,
                 frame.size.width - 2 * kPadding, height - kTextFieldHeight);
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (!_manager.playlist.count) {
    [self.navigationController
        presentViewController:super_basic_alert(kPlayEmptyPlaylistTitle, nil,
                                                ^() {
                                                  [self.navigationController
                                                      popViewControllerAnimated:YES];
                                                })
                     animated:YES
                   completion:nil];
  } else {
    if (!_manager.isPlaying) {
      [_manager start];
    }
  }
}

#pragma mark - THKeyboardDelegate

- (void)actionCellTapped {
  [_manager commitInput:_textField.text];
}

- (void)backCellTapped {
  if ([_textField hasText]) {
    _textField.text = [_textField.text substringToIndex:_textField.text.length - 1];
  }
}

- (void)addContent:(NSString *)content {
  _textField.text = [_textField.text stringByAppendingString:content];
}

- (NSString *)lastInput {
  if ([_textField hasText]) {
    return [_textField.text substringFromIndex:_textField.text.length - 1];
  } else {
    return @"";
  }
}

- (void)changeLastInputTo:(NSString *)content {
  if ([_textField hasText]) {
    _textField.text = [[_textField.text substringToIndex:_textField.text.length - 1]
        stringByAppendingString:content];
  }
}

- (void)showNotImplementedDialog {
  [self.navigationController
      presentViewController:super_basic_alert(kNotImplementedDialogTitle,
                                              kNotImplementedDialogMessage, nil)
                   animated:YES
                 completion:nil];
}

- (void)rightCellLongTapped {
  // ...shows nice sentences?
}

#pragma mark - THPlayManagerDelegate

- (void)showWithText:(NSString *)text {
  _textView.text = text;
  _textField.text = @"";
}

- (void)showAlert:(UIAlertController *)alert {
  [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void)playFinishedWithResult:(THPlayResult *)result {
  if (result.errors.count) {
    [self.navigationController
        presentViewController:
            [self
                wrapPlaylistDialogAdd:texts_alert_two_blocks(
                                          kPlayFinishMistakeDialogTitle,
                                          kPlayFinishMistakeDialogMessage, @[ @"" ],
                                          @[ kPlaylistDialogTextField ],
                                          ^(NSArray<UITextField *> *textFields) {
                                            [self.navigationController
                                                popViewControllerAnimated:YES];
                                          },
                                          ^(NSArray<UITextField *> *textFields) {
                                            NSString *partialName = textFields.firstObject.text;
                                            THPlaylist *playlist = [[THFileCenter sharedInstance]
                                                playlistWithPartialName:partialName
                                                                 create:YES];
                                            NSArray *keys = [result.errors allObjects];
                                            [playlist
                                                setObjects:[_manager.playlist objectsForKeys:keys]
                                                   forKeys:keys];
                                            [self.navigationController
                                                popToRootViewControllerAnimated:YES];
                                            [(THPlaylistsViewController *)self.navigationController
                                                    .viewControllers.firstObject
                                                showDialogForPlaylist:playlist];
                                          })]
                     animated:YES
                   completion:nil];
  } else {
    [self.navigationController
        presentViewController:super_basic_alert(kPlayFinishNoMistakeDialogTitle,
                                                kPlayFinishNoMistakeDialogMessage,
                                                ^() {
                                                  [self.navigationController
                                                      popViewControllerAnimated:YES];
                                                })
                     animated:YES
                   completion:nil];
  }
}

@end
