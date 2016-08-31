#import "THPlayViewController.h"

#import "THWordsViewController.h"
#import "Backend/THFileRW.h"
#import "Backend/THPlaylist.h"
#import "Backend/THWord.h"
#import "Backend/THWordsManager.h"
#import "Keyboard/THKeyboard.h"
#import "Models/THPlayViewModel.h"
#import "Shared/THHelpers.h"
#import "Shared/THStrings.h"

/** TODO: cancel the back button */

typedef void (^THPlayViewTextsOperation)(NSArray<NSString *> *);

static CGFloat kTextViewFontSize = 27;
static CGFloat kTextFieldFontSize = 16;

static CGFloat kPadding = 13;
static CGFloat kTextFieldTopPadding = 5;
static CGFloat kTextFieldHeight = 28;
static CGFloat kTextFieldBottomPadding = 5;

@interface THPlayViewController ()<THKeyboardDelegate, THPlayViewModelDelegate>

@end

@implementation THPlayViewController {
  THWordsCollection *_collection;
  THPlayViewModel *_model;

  UITextView *_textView;
  UITextField *_textField;
  THKeyboard *_keyboard;

  NSMutableArray<UIAlertController *> *_alertStack;
  NSMutableArray<NSArray<NSString *> *> *_textsStack;

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
    _alertStack = [NSMutableArray array];
    _textsStack = [NSMutableArray array];

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
  }
  return self;
}

#if (DEBUG)
- (void)dealloc {
  NSLog(@"dealloc: %@", self);
}
#endif

#pragma mark - private

- (void)showAlert:(UIAlertController *)alert {
  [self showAlert:alert save:NO];
}

- (void)showAlert:(UIAlertController *)alert save:(BOOL)save {
  [self showAlert:alert completion:nil save:save];
}

- (void)showAlert:(UIAlertController *)alert completion:(void (^)(void))completion save:(BOOL)save {
  if (save) {
    [_alertStack addObject: alert];
  }
  [self.navigationController presentViewController:alert animated:YES completion:completion];
}

- (void)showLastAlertAndPop:(BOOL)pop {
  if (pop) {
    [_alertStack removeLastObject];
  }
  UIAlertController *alert = _alertStack.lastObject;
  if (alert.textFields.count) {
    recover_alert_texts(alert, _textsStack.lastObject);
    [_textsStack removeLastObject];
  }
  [self showAlert:alert];
}

- (THAlertBasicAction)editWordBlockWithExplanation:(NSString *)explanation
                                               key:(THWordKey *)key
                                         operation:(THPlayViewTextsOperation)operation {
  __weak THPlayViewController *weakSelf = self;
  return ^() {
    [weakSelf
        showAlert:alert_edit_word(
                      key.contentForDisplay, @[ key.input, key.extra, explanation ],
                      ^() {
                        [weakSelf showLastAlertAndPop:YES];
                      },
                      ^(NSArray<UITextField *> *textFields) {
                        NSArray<NSString *> *texts = texts_from_text_fields(textFields);
                        [_textsStack addObject:texts];
                        THWordKey *newKey =
                            [[THWordKey alloc] initWithInput:texts[0] extra:texts[1]];
                        NSString *newExplanation = texts[2];
                        THWordsCollection *collection;
                        THWordsManagerOverwriteAction action =
                            [THWordsManager collection:_collection
                                wantsToEditExplanation:newExplanation
                                                forKey:newKey
                                                oldKey:key
                                           conflicting:&collection];
                        if (action) {
                          [weakSelf showAlert:alert_edit_word_conflicting(
                                                  key.contentForDisplay, newKey.contentForDisplay,
                                                  newExplanation,
                                                  [collection objectForKey:newKey].explanation,
                                                  ^() {
                                                    [weakSelf showLastAlertAndPop:NO];
                                                  },
                                                  ^{
                                                    action();
                                                    operation(texts);
                                                  })];
                        } else {
                          operation(texts);
                        }
                      })
             save:YES];
  };
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
  if (!_collection.count) {
    [self showAlert:alert_play_empty_playlist(^() {
            [self.navigationController popViewControllerAnimated:YES];
          })];
  } else if (_result) {
    [self.navigationController popViewControllerAnimated:NO];
  } else {
    [_model start];
  }
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
  [self showAlert:alert_ask_for_secret(callback)];
}

- (void)showNotImplementedDialog {
  [self showAlert:alert_not_implemented(nil)];
}

#pragma mark - THPlayViewModelDelegate

- (void)nextWordWithExplanation:(NSString *)explanation {
  _textView.text = explanation;
  _textField.text = @"";
  [_alertStack removeAllObjects];
  [_textsStack removeAllObjects];
}

- (void)wrongAnswer:(NSString *)wrongAnswer
     forExplanation:(NSString *)explanation
            wordKey:(THWordKey *)key {
  THAlertBasicAction next_block = ^() {
    [_model commitWrongAnswerWithOption:THPlayOptionNext texts:nil];
  };
  THAlertBasicAction typo_block = ^() {
    [_model commitWrongAnswerWithOption:THPlayOptionTypo texts:nil];
  };
  THPlayViewTextsOperation wrong_right_operation = ^(NSArray<NSString *> *texts) {
    [_model commitWrongAnswerWithOption:THPlayOptionWrongRight texts:texts];
  };
  THPlayViewTextsOperation wrong_wrong_operation = ^(NSArray<NSString *> *texts) {
    [_model commitWrongAnswerWithOption:THPlayOptionWrongWrong texts:texts];
  };
  THAlertBasicAction remove_block = ^() {
    // _model will remove the word for us!
    [_model commitWrongAnswerWithOption:THPlayOptionRemove texts:nil];
  };
  [self showAlert:action_sheet_play_options(
                      key.contentForDisplay, wrongAnswer, next_block, typo_block,
                      [self editWordBlockWithExplanation:explanation
                                                     key:key
                                               operation:wrong_right_operation],
                      [self editWordBlockWithExplanation:explanation
                                                     key:key
                                               operation:wrong_wrong_operation],
                      remove_block)
             save:YES];
}

- (void)playFinishedWithResult:(THPlayResult *)result {
  _result = result;
  if (result.wrongWordKeys.count) {
    NSArray<THWordKey *> *keys = result.wrongWordKeys.allObjects;
    THWordsCollection *collection = [[THWordsCollection alloc]
        initWithTransformedContent:[NSDictionary
                                       dictionaryWithObjects:[_collection objectsForKeys:keys]
                                                     forKeys:keys]];
    [self showAlert:action_sheet_play_finished_mistakes(
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
                                                            cancelBlock:nil
                                                           confirmBlock:nil]
                                        animated:YES];
                        },
                        ^{
                          [self.navigationController popViewControllerAnimated:YES];
                        })];
  } else {
    [self showAlert:alert_play_finished_no_mistakes(^() {
      [self.navigationController popViewControllerAnimated:YES];
    })];
  }
}

@end