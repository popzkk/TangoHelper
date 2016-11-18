#import "THHelpers.h"

#import "THStrings.h"
#import "../Backend/THFileCenter.h"
#import "../Backend/THPlaylist.h"

#if _cplusplus
extern "C" {
#endif

#pragma mark - UIBarButtonItems

UIBarButtonItem *system_item(UIBarButtonSystemItem sys, id target, SEL action) {
  return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:sys target:target action:action];
}

UIBarButtonItem *custom_item(NSString *title, UIBarButtonItemStyle style, id target, SEL action) {
  return [[UIBarButtonItem alloc] initWithTitle:title style:style target:target action:action];
}

#pragma mark - Alerts and ActionSheets

// =====================================  Word related strings

static NSString *kAddWordAlertTitle = @"Add a Word";
static NSString *kEditWordAlertTitle = @"Edit '%@'";
static NSString *kWordAlertKeyInputPlaceholder = @"Recitable Content";
static NSString *kWordAlertKeyExtraPlaceholder = @"Extra Content";
static NSString *kWordAlertObjectPlaceholder = @"Explanation";
static NSString *kAddWordConflictAlertTitle = @"Adding an existing Word - '%@'\nOverwrite?";
static NSString *kAddWordConflictAlertMessage = @"Your input: %@\nAlready there: %@";
static NSString *kEditWordConflictAlertTitle =
    @"Editing '%@' to an existing Word - '%@'\nOverwrite?";
static NSString *kEditWordConflictAlertMessage = @"Your input: %@\nAlready there: %@";

// =====================================  Playlist related strings

static NSString *kAddPlaylistAlertTitle = @"Add a Playlist";
static NSString *kRenamePlaylistAlertTitle = @"Rename '%@'";
static NSString *kPlaylistAlertPartialNamePlaceholder = @"Playlist name";
static NSString *kPlaylistExistsAlertTitle = @"Playlist '%@' already exists";

// =====================================  Word and Playlist strings

static NSString *kRemoveRowAlertTitle = @"Remove \"%@\"?";
static NSString *kRemoveSelectedAlertTitle = @"Remove the selected items?";
static NSString *kSelectedOptionsActionSheetTitle = @"Next step with the selected content";
static NSString *kSelectedOptionsActionSheetPlayActionTitle = @"Directly Play";
static NSString *kSelectedOptionsActionSheetCreateActionTitle = @"Create a Playlist";
static NSString *kSelectedOptionsActionSheetCopyToPlaylistsActionTitle = @"Copy to Playlist(s)";
static NSString *kMoreInfoAlertTitle = @"More Info";
static NSString *kSelectionOptionsActionSheetSelectAllActionTitle = @"Select All";
static NSString *kSelectionOptionsActionSheetClearActionTitle = @"Clear";
static NSString *kSelectionOptionsActionSheetInvertActionTitle = @"Invert";

// =====================================  Play related strings

static NSString *kPlayAlertTitle = @"Play \"%@\"?";
static NSString *kPlayAlertTitleSimple = @"Play?";
static NSString *kPlayFinishMistakesActionSheetTitle =
    @"Finished...However there were some mistakes";
static NSString *kPlayFinishMistakesActionSheetTryAgain = @"Try again with the mistakes";
static NSString *kPlayFinishMistakesActionSheetView = @"View the mistakes";
static NSString *kPlayFinishMistakesActionSheetAck = @"Acknowledged";
static NSString *kPlayFinishNoMistakeAlertTitle = @"Wow...No mistakes!";
static NSString *kPlayFinishNoMistakeAlertMessage = @"Congratulations!";
static NSString *kPlayEmptyPlaylistAlertTitle = @"Please add some Words first";
static NSString *kPlayOptionsActionSheetTitle = @"Word Self:\"%@\"";
static NSString *kPlayOptionsActionSheetMessage = @"Your Answer:\"%@\"";
static NSString *kPlayOptionsActionSheetNext = @"F**k...Next";
static NSString *kPlayOptionsActionSheetTypo = @"Typo...Never mind";
static NSString *kPlayOptionsActionSheetEdit = @"Edit this Word";
static NSString *kPlayOptionsActionSheetRemove = @"Remove this Word";

// ===================================== Others

static NSString *kNotImplementedAlertTitle = @"Oops...Please be patient";
static NSString *kNotImplementedAlertMessage = @"Kaikai is working on this feature day and night";
static NSString *kAskForSecretAlertTitle = @"";
static NSString *kAskForSecretAlertSecretPlaceholder = @"Please enter something ^_^";
static NSString *kSpecialPlaylistDisallowedTitle = @"恋人が欲しい？";
static NSString *kSpecialPlaylistDisallowedMessage = @"You can speak English...";
// =====================================

static CGFloat kTextFieldFontSize = 16;

UIAlertController *dialog_super_basic(NSString *title, NSString *message,
                                      THAlertBasicAction block) {
  if (!block) {
    block = ^{
    };
  }

  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:kConfirm
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            block();
                                          }]];
  return alert;
}

UIAlertController *dialog_basic_two_blocks(NSString *title, NSString *message,
                                           THAlertBasicAction cancel_block,
                                           THAlertBasicAction confirm_block) {
  if (!cancel_block) {
    cancel_block = ^{
    };
  }
  if (!confirm_block) {
    confirm_block = ^{
    };
  }

  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:kCancel
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            cancel_block();
                                          }]];
  [alert addAction:[UIAlertAction actionWithTitle:kConfirm
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            confirm_block();
                                          }]];
  return alert;
}

UIAlertController *dialog_basic(NSString *title, NSString *message, THAlertBasicAction block) {
  return dialog_basic_two_blocks(title, message, nil, block);
}

UIAlertController *dialog_texts_two_blocks(NSString *title, NSString *message,
                                           NSArray<NSString *> *texts,
                                           NSArray<NSString *> *placeholders,
                                           THAlertTextsAction cancel_block,
                                           THAlertTextsAction confirm_block) {
  if (!cancel_block) {
    cancel_block = ^(NSArray<UITextField *> *array) {
    };
  }
  if (!confirm_block) {
    confirm_block = ^(NSArray<UITextField *> *array) {
    };
  }

  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
#if (DEBUG)
  if (texts.count != placeholders.count) {
    NSLog(@"cannot create 'dialog_texts': inconsistant number of elements");
    return nil;
  }
#endif
  for (NSUInteger i = 0; i < texts.count; ++i) {
    NSString *text = texts[i];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.placeholder = placeholders[i];
      textField.text = text;
      textField.font = ja_normal(kTextFieldFontSize);
    }];
  }
  [alert addAction:[UIAlertAction actionWithTitle:kCancel
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            for (UITextField *textField in alert.textFields) {
                                              textField.text = @"";
                                            }
                                            cancel_block(alert.textFields);
                                          }]];
  [alert addAction:[UIAlertAction actionWithTitle:kConfirm
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            confirm_block(alert.textFields);
                                          }]];
  return alert;
}

UIAlertController *dialog_texts(NSString *title, NSString *message, NSArray<NSString *> *texts,
                                NSArray<NSString *> *placeholders, THAlertTextsAction block) {
  return dialog_texts_two_blocks(title, message, texts, placeholders, nil, block);
}

UIAlertController *sheet_(NSString *title, NSString *message, NSArray<NSString *> *action_titles,
                          NSArray<THAlertBasicAction> *actions, NSString *default_title,
                          THAlertBasicAction default_block) {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleActionSheet];
#if (DEBUG)
  if (action_titles.count != actions.count) {
    NSLog(@"cannot create 'sheet_': inconsistant number of elements");
    return nil;
  }
#endif
  for (NSUInteger i = 0; i < action_titles.count; ++i) {
    [alert addAction:[UIAlertAction actionWithTitle:action_titles[i]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                              actions[i]();
                                            }]];
  }
  if (!default_block) {
    default_block = ^{
    };
  }
  [alert addAction:[UIAlertAction actionWithTitle:default_title
                                            style:UIAlertActionStyleCancel
                                          handler:^(UIAlertAction *action) {
                                            default_block();
                                          }]];
  return alert;
}

UIAlertController *sheet_basic(NSString *title, NSString *message,
                               NSArray<NSString *> *action_titles,
                               NSArray<THAlertBasicAction> *actions) {
  return sheet_(title, message, action_titles, actions, kCancel, nil);
}

UIAlertController *dialog_word(NSString *title, NSString *message, NSArray<NSString *> *texts,
                               THAlertTextsAction cancel_block, THAlertTextsAction confirm_block) {
  if (!texts) {
    texts = @[
      @"",
      @"",
      @"",
    ];
  }
  return dialog_texts_two_blocks(title, message, texts,
                                 @[
                                   kWordAlertKeyInputPlaceholder,
                                   kWordAlertKeyExtraPlaceholder,
                                   kWordAlertObjectPlaceholder,
                                 ],
                                 cancel_block, confirm_block);
}

UIAlertController *dialog_add_word(THAlertTextsAction confirm_block) {
  return dialog_word(kAddWordAlertTitle, nil, nil, nil, confirm_block);
}

UIAlertController *dialog_edit_word(NSString *word_key, NSArray<NSString *> *texts,
                                    THAlertBasicAction cancel_block,
                                    THAlertTextsAction confirm_block) {
  return dialog_word([NSString stringWithFormat:kEditWordAlertTitle, word_key], nil, texts,
                     cancel_block, confirm_block);
}

UIAlertController *dialog_add_word_conflicting(NSString *word_key, NSString *your_input,
                                               NSString *already_there,
                                               THAlertBasicAction cancel_block,
                                               THAlertBasicAction confirm_block) {
  return dialog_basic_two_blocks(
      [NSString stringWithFormat:kAddWordConflictAlertTitle, word_key],
      [NSString stringWithFormat:kAddWordConflictAlertMessage, your_input, already_there],
      cancel_block, confirm_block);
}

UIAlertController *dialog_edit_word_conflicting(NSString *old_key, NSString *new_key,
                                                NSString *your_input, NSString *already_there,
                                                THAlertBasicAction cancel_block,
                                                THAlertBasicAction confirm_block) {
  return dialog_basic_two_blocks(
      [NSString stringWithFormat:kEditWordConflictAlertTitle, old_key, new_key],
      [NSString stringWithFormat:kEditWordConflictAlertMessage, your_input, already_there],
      cancel_block, confirm_block);
}

UIAlertController *dialog_playlist(NSString *title, NSString *text,
                                   THAlertTextsAction confirm_block) {
  if (!text) {
    text = @"";
  }
  return dialog_texts(title, nil, @[ text ], @[ kPlaylistAlertPartialNamePlaceholder ],
                      confirm_block);
}

UIAlertController *dialog_add_playlist(THAlertTextsAction confirm_block) {
  return dialog_playlist(kAddPlaylistAlertTitle, nil, confirm_block);
}

UIAlertController *dialog_rename_playlist(NSString *partial_name,
                                          THAlertTextsAction confirm_block) {
  return dialog_playlist([NSString stringWithFormat:kRenamePlaylistAlertTitle, partial_name],
                         partial_name, confirm_block);
}

UIAlertController *dialog_playlist_exists(NSString *partial_name, THAlertBasicAction block) {
  return dialog_super_basic([NSString stringWithFormat:kPlaylistExistsAlertTitle, partial_name],
                            nil, block);
}

UIAlertController *dialog_remove_item(NSString *name, THAlertBasicAction confirm_block) {
  return dialog_basic([NSString stringWithFormat:kRemoveRowAlertTitle, name], nil, confirm_block);
}

UIAlertController *dialog_remove_selected(THAlertBasicAction confirm_block) {
  return dialog_basic(kRemoveSelectedAlertTitle, nil, confirm_block);
}

UIAlertController *dialog_more_info(NSString *more_info) {
  return dialog_super_basic(kMoreInfoAlertTitle, more_info, nil);
}

UIAlertController *sheet_selected_options(THAlertBasicAction play_block,
                                          THAlertBasicAction create_block,
                                          THAlertBasicAction copy_to_playlists_block) {
  return sheet_basic(kSelectedOptionsActionSheetTitle, nil,
                     @[
                       kSelectedOptionsActionSheetPlayActionTitle,
                       kSelectedOptionsActionSheetCreateActionTitle,
                       kSelectedOptionsActionSheetCopyToPlaylistsActionTitle,
                     ],
                     @[
                       play_block,
                       create_block,
                       copy_to_playlists_block,
                     ]);
}

UIAlertController *sheet_selection_options(THAlertBasicAction select_all_block,
                                           THAlertBasicAction clear_block,
                                           THAlertBasicAction invert_block) {
  return sheet_basic(nil, nil,
                     @[
                       kSelectionOptionsActionSheetSelectAllActionTitle,
                       kSelectionOptionsActionSheetClearActionTitle,
                       kSelectionOptionsActionSheetInvertActionTitle,
                     ],
                     @[
                       select_all_block,
                       clear_block,
                       invert_block,
                     ]);
}

UIAlertController *dialog_play(NSString *partial_name, THAlertBasicAction confirm_block) {
  if (partial_name.length) {
    return dialog_basic([NSString stringWithFormat:kPlayAlertTitle, partial_name], nil,
                        confirm_block);
  } else {
    return dialog_basic(kPlayAlertTitleSimple, nil, confirm_block);
  }
}

UIAlertController *sheet_play_options(NSString *word_self, NSString *your_answer,
                                      THAlertBasicAction next_block, THAlertBasicAction typo_block,
                                      THAlertBasicAction edit_block,
                                      THAlertBasicAction remove_block) {
  return sheet_([NSString stringWithFormat:kPlayOptionsActionSheetTitle, word_self],
                [NSString stringWithFormat:kPlayOptionsActionSheetMessage, your_answer],
                @[
                  kPlayOptionsActionSheetTypo,
                  kPlayOptionsActionSheetEdit,
                  kPlayOptionsActionSheetRemove,
                ],
                @[
                  typo_block,
                  edit_block,
                  remove_block,
                ],
                kPlayOptionsActionSheetNext, next_block);
}

UIAlertController *dialog_play_empty_playlist(THAlertBasicAction block) {
  return dialog_super_basic(kPlayEmptyPlaylistAlertTitle, nil, block);
}

UIAlertController *sheet_play_finished_mistakes(THAlertBasicAction try_again_block,
                                                THAlertBasicAction view_block,
                                                THAlertBasicAction ack_block) {
  return sheet_(kPlayFinishMistakesActionSheetTitle, nil,
                @[
                  kPlayFinishMistakesActionSheetTryAgain,
                  kPlayFinishMistakesActionSheetView,
                ],
                @[
                  try_again_block,
                  view_block,
                ],
                kPlayFinishMistakesActionSheetAck, ack_block);
}

UIAlertController *dialog_play_finished_no_mistakes(THAlertBasicAction block) {
  return dialog_super_basic(kPlayFinishNoMistakeAlertTitle, kPlayFinishNoMistakeAlertMessage,
                            block);
}

UIAlertController *dialog_not_implemented(THAlertBasicAction block) {
  return dialog_super_basic(kNotImplementedAlertTitle, kNotImplementedAlertMessage, block);
}

UIAlertController *dialog_ask_for_secret(THAlertTextsAction block) {
  return dialog_texts(kAskForSecretAlertTitle, nil, @[ @"" ],
                      @[ kAskForSecretAlertSecretPlaceholder ], block);
}

UIAlertController *dialog_special_playlist_disallowed() {
  return dialog_super_basic(kSpecialPlaylistDisallowedTitle, kSpecialPlaylistDisallowedMessage,
                            nil);
}

#pragma mark - Fonts and Colors

static NSString *ja_font_normal = @"PingFang-SC-Medium";
static NSString *ja_font_bold = @"PingFang-SC-Semibold";
static NSString *zh_font_normal = @"PingFang-SC-Medium";
static NSString *zh_font_bold = @"PingFang-SC-Semibold";

UIFont *ja_normal(CGFloat size) { return [UIFont fontWithName:ja_font_normal size:size]; }

UIFont *ja_bold(CGFloat size) { return [UIFont fontWithName:ja_font_bold size:size]; }

UIFont *zh_normal(CGFloat size) { return [UIFont fontWithName:zh_font_normal size:size]; }

UIFont *zh_bold(CGFloat size) { return [UIFont fontWithName:zh_font_bold size:size]; }

UIColor *blue_color() {
  // modified from 007aff
  return [UIColor colorWithRed:0.00 green:0.60 blue:1.00 alpha:1];
}

UIColor *light_blue_color() {
  // 5ac8fa
  return [UIColor colorWithRed:0.35 green:0.78 blue:0.98 alpha:0.6];
}

UIColor *grey_color() {
  // c7c7cc
  return [UIColor colorWithRed:0.78 green:0.78 blue:0.80 alpha:1.0];
}

UIColor *grey_color_half() { return [UIColor colorWithRed:0.78 green:0.78 blue:0.80 alpha:0.5]; }

#pragma mark - Others

void shuffle(NSMutableArray *array) {
  for (NSUInteger i = array.count; i > 1; --i) {
    [array exchangeObjectAtIndex:i - 1 withObjectAtIndex:arc4random_uniform((int)i)];
  }
}

NSArray<NSString *> *texts_from_text_fields(NSArray<UITextField *> *text_fields) {
  NSMutableArray<NSString *> *texts = [NSMutableArray arrayWithCapacity:text_fields.count];
  for (UITextField *text_field in text_fields) {
    [texts addObject:text_field.text];
  }
  return texts;
}

NSIndexSet *index_set_from_index_paths(NSArray<NSIndexPath *> *index_paths) {
  NSMutableIndexSet *index_set = [NSMutableIndexSet indexSet];
  for (NSIndexPath *index_path in index_paths) {
    [index_set addIndex:index_path.row];
  }
  return index_set;
}

UIAlertController *recover_dialog_texts(UIAlertController *alert, NSArray<NSString *> *texts) {
  for (NSUInteger i = 0; i < texts.count; ++i) {
    alert.textFields[i].text = texts[i];
  }
  return alert;
}

#if _cplusplus
}  // Extern C
#endif
