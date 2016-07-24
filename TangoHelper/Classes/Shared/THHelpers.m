#import "THHelpers.h"
#import "THStrings.h"

#if __cplusplus
extern "C" {
#endif

static NSString *ja_font_normal = @"HiraKakuProN-W3";
static NSString *ja_font_bold = @"HiraKakuProN-W6";

NSString *playlist_title(NSString *partial_name) {
  return [NSString stringWithFormat:kPlaylistTitle, partial_name];
}

NSString *add_to_playlist_title(NSString *partial_name) {
  return [NSString stringWithFormat:kAddToPlaylistTitle, partial_name];
}

NSString *remove_dialog_title_from_playlist(NSString *partial_name) {
  return [NSString stringWithFormat:kRemoveDialogTitleFromPlaylist, partial_name];
}

NSString *remove_dialog_title_normal(NSString *name) {
  return [NSString stringWithFormat:kRemoveDialogTitleNormal, name];
}

NSString *play_dialog_title(NSString *partial_name) {
  return [NSString stringWithFormat:kPlayDialogTitle, partial_name];
}

NSString *play_immediately_dialog_title(NSString *partial_name) {
  return [NSString stringWithFormat:kPlayImmediatelyDialogTitle, partial_name];
}

NSString *playing_title(NSString *partial_name) {
  return [NSString stringWithFormat:kPlayingTitle, partial_name];
}

NSString *play_wrong_answer_dialog_title(NSString *answer) {
  return [NSString stringWithFormat:kPlayWrongAnswerDialogTitle, answer];
}

NSString *play_wrong_answer_dialog_message(NSString *answer) {
  return [NSString stringWithFormat:kPlayWrongAnswerDialogMessage, answer];
}

UIBarButtonItem *system_item(UIBarButtonSystemItem sys, id target, SEL action) {
  return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:sys target:target action:action];
}

UIBarButtonItem *custom_item(NSString *title, UIBarButtonItemStyle style, id target, SEL action) {
  return [[UIBarButtonItem alloc] initWithTitle:title style:style target:target action:action];
}

UIAlertController *super_basic_alert(NSString *title, NSString *message, THBasicAlertAction block) {
  if (!block) {
    block = ^() {
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

UIAlertController *basic_alert(NSString *title, NSString *message, THBasicAlertAction block) {
  return basic_alert_two_blocks(title, message, nil, block);
}

UIAlertController *basic_alert_two_blocks(NSString *title, NSString *message,
                                          THBasicAlertAction cancel_block,
                                          THBasicAlertAction confirm_block) {
  if (!cancel_block) {
    cancel_block = ^() {
    };
  }
  if (!confirm_block) {
    confirm_block = ^() {
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

UIAlertController *texts_alert(NSString *title, NSString *message, NSArray *texts,
                               NSArray *placeholders, THTextsAlertAction block) {
  return texts_alert_two_blocks(title, message, texts, placeholders, nil, block);
}

UIAlertController *texts_alert_two_blocks(NSString *title, NSString *message, NSArray *texts,
                                          NSArray *placeholders, THTextsAlertAction cancel_block,
                                          THTextsAlertAction confirm_block) {
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
  if (texts.count != placeholders.count) {
    NSLog(@"cannot create 'texts_alert': inconsistant number of elements.");
    return nil;
  }
  for (NSUInteger i = 0; i < texts.count; ++i) {
    NSString *text = texts[i];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.placeholder = placeholders[i];
      textField.text = text;
    }];
  }
  [alert addAction:[UIAlertAction actionWithTitle:kCancel
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            cancel_block(alert.textFields);
                                          }]];
  [alert addAction:[UIAlertAction actionWithTitle:kConfirm
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            confirm_block(alert.textFields);
                                          }]];
  return alert;
}

UIFont *ja_normal_small() { return [UIFont fontWithName:ja_font_normal size:16]; }

UIFont *ja_normal_big() { return [UIFont fontWithName:ja_font_normal size:24]; }

UIFont *ja_bold_small() { return [UIFont fontWithName:ja_font_bold size:16]; }

UIFont *ja_bold_big() { return [UIFont fontWithName:ja_font_bold size:24]; }

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

#if __cplusplus
}  // Extern C
#endif
