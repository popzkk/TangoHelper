#import "THPlayViewController.h"

#import "Backend/THFileRW.h"
#import "Backend/THPlaylist.h"
#import "Backend/THWord.h"
#import "Backend/THWordsManager.h"
#import "Keyboard/THKeyboard.h"
#import "Models/THPlayViewModel.h"
#import "Shared/THHelpers.h"
#import "Shared/THStrings.h"
#import "THWordsViewController.h"

typedef void (^THPlayViewTextsOperation)(NSArray<NSString *> *);

static CGFloat kTextViewFontSize = 27;
static CGFloat kTextFieldFontSize = 16;

static CGFloat kHorizontalPadding = 16;
static CGFloat kVerticalPadding = 16;
static CGFloat kTextFieldHeight = 28;
static CGFloat kTextFieldBottomPadding = 5;

// Declear these properties here so we can use 'weakSelf.xxx'. Any better way?
@interface THPlayViewController () <UITextFieldDelegate,
                                    THKeyboardDelegate,
                                    THPlayViewModelDelegate>

@property(nonatomic) THWordsCollection *collection;

@property(nonatomic) THPlayViewModel *model;

@property(nonatomic) UIAlertController *lastAlert;

@property(nonatomic) NSArray<NSString *> *lastTexts;

@end

@implementation THPlayViewController {
  UITextView *_textView;
  UITextField *_textField;
  THKeyboard *_keyboard;

  THPlayResult *_result;
}

#pragma mark - public

- (instancetype)initWithCollection:(THWordsCollection *)collection {
  self = [super init];
  if (self) {
    _collection = collection;
    _model = [[THPlayViewModel alloc] initWithCollection:_collection
                                                  config:[[THPlayConfig alloc] init]
                                                delegate:self];

    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _textView.font = zh_bold(kTextViewFontSize);
    _textView.layer.borderWidth = 1;
    _textView.layer.borderColor = grey_color().CGColor;
    _textView.textAlignment = NSTextAlignmentCenter;
    _textView.userInteractionEnabled = NO;
    _textField = [[UITextField alloc] initWithFrame:CGRectZero];
    _textField.font = ja_normal(kTextFieldFontSize);
    _textField.textAlignment = NSTextAlignmentCenter;
    _textField.layer.borderWidth = 1;
    _textField.layer.borderColor = grey_color().CGColor;
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textField.spellCheckingType = UITextSpellCheckingTypeNo;
    _textField.returnKeyType = UIReturnKeyNext;
    _textField.delegate = self;
    _keyboard = [THKeyboard sharedInstanceWithKeyboardType:THKeyboardTypeUnknown
                                                actionText:kNextJa
                                                  delegate:self];
    [self.view addSubview:_textView];
    [self.view addSubview:_textField];
    [self.view addSubview:_keyboard];

    if ([_collection isKindOfClass:[THPlaylist class]]) {
      self.title = ((THPlaylist *)_collection).partialName;
    } else {
      self.title = @"Playing";
    }
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem =
        system_item(UIBarButtonSystemItemCancel, self, @selector(didTapBarItemCancel));
    self.navigationItem.rightBarButtonItem =
        custom_item(@"Keyboard", UIBarButtonItemStylePlain, self, @selector(didTapBarItemKeyboard));

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sysKeyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
#if (DEBUG)
  NSLog(@"dealloc: %@", self);
#endif
}

#pragma mark - private

- (void)prepareFrames {
  CGRect frame = UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets);
  frame = CGRectInset(frame, kHorizontalPadding, 0);
  CGRect slice;
  CGRectDivide(frame, &slice, &frame, self.navigationController.navigationBar.frame.size.height,
               CGRectMinYEdge);
  CGFloat keyboardKeight = frame.size.width / 5 * 4;
  CGRectDivide(frame, &slice, &frame, keyboardKeight, CGRectMaxYEdge);
  _keyboard.frame = slice;
  CGRectDivide(frame, &slice, &frame, kVerticalPadding, CGRectMaxYEdge);
  CGRectDivide(frame, &slice, &frame, kTextFieldHeight, CGRectMaxYEdge);
  _textField.frame = slice;
  CGRectDivide(frame, &slice, &frame, kVerticalPadding, CGRectMaxYEdge);
  _textView.frame = frame;
}

- (void)didTapBarItemKeyboard {
  if (_keyboard.hidden) {
    _keyboard.hidden = NO;
    [_textField resignFirstResponder];
  } else {
    _keyboard.hidden = YES;
    [_textField becomeFirstResponder];
  }
}

- (void)sysKeyboardWillChangeFrame:(NSNotification *)notification {
  if (_keyboard.hidden) {
    // When switching from other apps directly, the text field doesn't automatically become the
    // first responder. Seems it is a bug of iOS 10. Manually make it to be the first responder if
    // we are not presenting an alert.
    if (!self.presentedViewController && ![_textField isFirstResponder]) {
      [_textField becomeFirstResponder];
    }
    CGRect kbRect =
        [self.view convertRect:[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey]
                                   CGRectValue]
                      fromView:nil];
    CGFloat diff =
        _textField.frame.origin.y + kTextFieldHeight + kTextFieldBottomPadding - kbRect.origin.y;
    _textField.frame =
        CGRectApplyAffineTransform(_textField.frame, CGAffineTransformMakeTranslation(0, -diff));
    _textView.frame = CGRectMake(_textView.frame.origin.x, _textView.frame.origin.y,
                                 _textView.frame.size.width, _textView.frame.size.height - diff);
  } else {
    [self prepareFrames];
  }
  [self.view layoutIfNeeded];
}

- (void)didTapBarItemCancel {
  [_model finish];
}

- (void)showAlert:(UIAlertController *)alert {
  [self showAlert:alert save:NO];
}

- (void)showAlert:(UIAlertController *)alert save:(BOOL)save {
  [self showAlert:alert completion:nil save:save];
}

- (void)showAlert:(UIAlertController *)alert completion:(void (^)(void))completion save:(BOOL)save {
  if (save) {
    _lastAlert = alert;
  }
  [self.navigationController presentViewController:alert animated:YES completion:completion];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.toolbarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self prepareFrames];
  if (_keyboard.hidden && ![_textField isFirstResponder]) {
    [_textField becomeFirstResponder];
  }
  if (!_collection.count) {
    [self showAlert:dialog_play_empty_playlist(^{
            [self.navigationController popViewControllerAnimated:YES];
          })];
  } else if (_result) {
    [self.navigationController popViewControllerAnimated:NO];
  } else {
    [_model start];
  }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [_model confirmInput:textField.text];
  return YES;
}

#pragma mark - THKeyboardDelegate

- (void)actionCellTapped {
  [_model confirmInput:_textField.text];
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

- (void)rightCellLongTapped {
  // ...shows nice sentences?
}

- (void)askForSecretWithCallback:(id)callback {
  [self showAlert:dialog_ask_for_secret(callback)];
}

- (void)showNotImplementedDialog {
  [self showAlert:dialog_not_implemented(nil)];
}

#pragma mark - THPlayViewModelDelegate

- (void)nextWordWithExplanation:(NSString *)explanation {
  _textView.text = explanation;
  _textField.text = @"";
}

- (void)wrongAnswer:(NSString *)wrongAnswer
     forExplanation:(NSString *)explanation
            wordKey:(THWordKey *)key {
  __weak THPlayViewController *weakSelf = self;
  THAlertBasicAction next_block = ^{
    [weakSelf.model commitWrongAnswerWithOption:THPlayOptionNext wordKey:nil];
  };
  THAlertBasicAction typo_block = ^{
    [weakSelf.model commitWrongAnswerWithOption:THPlayOptionTypo wordKey:nil];
  };
  THAlertBasicAction edit_block = ^{
    [self
        showAlert:dialog_edit_word(
                      key.contentForDisplay, @[ key.input, key.extra, explanation ],
                      ^{
                        [weakSelf wrongAnswer:wrongAnswer forExplanation:explanation wordKey:key];
                      },
                      ^(NSArray<UITextField *> *textFields) {
                        NSArray<NSString *> *texts = texts_from_text_fields(textFields);
                        weakSelf.lastTexts = texts;
                        THWordKey *newKey =
                            [[THWordKey alloc] initWithInput:texts[0] extra:texts[1]];
                        NSString *newExplanation = texts[2];
                        THWordObject *newObj = [weakSelf.collection editOldKey:key
                                                                         toKey:newKey
                                                               withExplanation:newExplanation];
                        if (newObj) {
                          [weakSelf showAlert:dialog_edit_word_conflicting(
                                                  key.contentForDisplay, newKey.contentForDisplay,
                                                  newExplanation, newObj.explanation,
                                                  ^{
                                                    recover_dialog_texts(weakSelf.lastAlert,
                                                                         weakSelf.lastTexts);
                                                    [weakSelf showAlert:weakSelf.lastAlert];
                                                  },
                                                  ^{
                                                    newObj.explanation = newExplanation;
                                                    [weakSelf.collection editOldKey:key
                                                                              toKey:newKey
                                                                    withExplanation:newExplanation];
                                                    [weakSelf.model
                                                        commitWrongAnswerWithOption:THPlayOptionEdit
                                                                            wordKey:newKey];
                                                  })];
                        } else {
                          [weakSelf.model commitWrongAnswerWithOption:THPlayOptionEdit
                                                              wordKey:newKey];
                        }
                      })
             save:YES];
  };
  THAlertBasicAction remove_block = ^{
    // _model will remove the word for us!
    [weakSelf.model commitWrongAnswerWithOption:THPlayOptionRemove wordKey:nil];
  };
  [self showAlert:sheet_play_options(key.contentForDisplay, wrongAnswer, next_block, typo_block,
                                     edit_block, remove_block)];
}

- (void)playFinishedWithResult:(THPlayResult *)result {
  _result = result;
  if (result.wrongWordKeys.count) {
    NSArray<THWordKey *> *keys = result.wrongWordKeys.allObjects;
    THWordsCollection *collection = [[THWordsCollection alloc]
        initWithTransformedContent:[NSDictionary
                                       dictionaryWithObjects:[_collection objectsForKeys:keys]
                                                     forKeys:keys]];
    [self showAlert:sheet_play_finished_mistakes(
                        ^{
                          [self.navigationController
                              pushViewController:[[THPlayViewController alloc]
                                                     initWithCollection:collection]
                                        animated:YES];
                        },
                        ^{
                          [self.navigationController
                              pushViewController:[[THWordsViewController alloc]
                                                     initWithCollection:collection
                                                            preSelected:nil
                                                                  title:@"Wrong Words"
                                                           searchString:nil
                                                            cancelBlock:nil
                                                           confirmBlock:nil]
                                        animated:YES];
                        },
                        ^{
                          [self.navigationController popViewControllerAnimated:YES];
                        })];
  } else {
    [self showAlert:dialog_play_finished_no_mistakes(^{
            [self.navigationController popViewControllerAnimated:YES];
          })];
  }
}

@end
