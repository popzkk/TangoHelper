#ifndef THHelpers_h
#define THHelpers_h

#import <UIKit/UIKit.h>

typedef void (^THBasicAlertAction)();
typedef void (^THTextsAlertAction)(NSArray<UITextField *> *);

#if __cplusplus
extern "C" {
#endif

NSString *playlist_title(NSString *partial_name);
NSString *add_to_playlist_title(NSString *partial_name);
NSString *remove_dialog_title_from_playlist(NSString *partial_name);
NSString *remove_dialog_title_normal(NSString *name);
NSString *play_dialog_title(NSString *partial_name);
NSString *play_immediately_dialog_title(NSString *partial_name);
NSString *playing_title(NSString *partial_name);
NSString *play_wrong_answer_dialog_title(NSString *answer);
NSString *play_wrong_answer_dialog_message(NSString *answer);

UIBarButtonItem *system_item(UIBarButtonSystemItem sys, id target, SEL action);
UIBarButtonItem *custom_item(NSString *title, UIBarButtonItemStyle style, id target, SEL action);

UIAlertController *super_basic_alert(NSString *title, NSString *message, THBasicAlertAction block);
UIAlertController *basic_alert_two_blocks(NSString *title, NSString *message,
                                          THBasicAlertAction cancel_block,
                                          THBasicAlertAction confirm_block);
UIAlertController *basic_alert(NSString *title, NSString *message, THBasicAlertAction block);
// all buttons are enabled by default.
UIAlertController *texts_alert(NSString *title, NSString *message, NSArray *texts,
                               NSArray *placeholders, THTextsAlertAction block);
UIAlertController *texts_alert_two_blocks(NSString *title, NSString *message, NSArray *texts,
                                          NSArray *placeholders, THTextsAlertAction cancel_block,
                                          THTextsAlertAction confirm_block);
//UIFont *ja_light_small();
//UIFont *ja_light_big();
UIFont *cj_regular_small();
UIFont *cj_regular_big();
UIFont *cj_bold_small();
UIFont *cj_bold_big();

UIFont *zh_light_small();
UIFont *zh_medium_big();
UIFont *zh_bold_large();

UIColor *blue_color();
UIColor *light_blue_color();
UIColor *grey_color();
UIColor *grey_color_half();

NSString *core_part(NSString *);

#if __cplusplus
}  // Extern C
#endif

#endif /* THHelpers_h */
