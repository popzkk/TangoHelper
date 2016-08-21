#import "THPlayViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THPlayManager.h"
#import "Backend/THPlaylist.h"
#import "Keyboard/THKeyboard.h"
#import "Shared/THHelpers.h"
#import "Shared/THStrings.h"
#import "THPlaylistsViewController.h"

#pragma mark - THPlayViewController

static CGFloat kTextViewFontSize = 27;
static CGFloat kTextFieldFontSize = 16;

static CGFloat kPadding = 13;
static CGFloat kTextFieldTopPadding = 5;
static CGFloat kTextFieldHeight = 28;
static CGFloat kTextFieldBottomPadding = 5;

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
    _textView.font = zh_bold(kTextViewFontSize);
    _textView.layer.borderWidth = 1;
    _textView.layer.borderColor = grey_color().CGColor;
    _textView.textAlignment = NSTextAlignmentCenter;
    _textView.userInteractionEnabled = NO;
    _textField = [[UITextField alloc] initWithFrame:CGRectZero];
    _textField.font = cj_regular(kTextFieldFontSize);
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
  CGRect frame = self.view.bounds;
  CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
  // height for the text view.
  CGFloat textViewHeight = frame.size.height / 2 - kPadding - navBarHeight;
  CGFloat x = frame.origin.x + kPadding;
  CGFloat y = frame.origin.y + + navBarHeight + kPadding;
  CGFloat width = frame.size.width - 2 * kPadding;

  _textView.frame = CGRectMake(x, y += kPadding, width, textViewHeight);
  y += textViewHeight;

  _textField.frame = CGRectMake(x, y += kTextFieldTopPadding, width, kTextFieldHeight);
  y += kTextFieldHeight + kTextFieldBottomPadding;

  _keyboard.frame = CGRectMake(x, y, width, frame.size.height - y - kPadding);
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

- (void)askForSecretWithCallback:(id)callback {
  [self.navigationController
      presentViewController:texts_alert(@"", nil, @[ @"" ], @[ @"Please enter something ^_^" ],
                                        callback)
                   animated:YES
                 completion:nil];
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
