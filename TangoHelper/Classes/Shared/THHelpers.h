#ifndef THHelpers_h
#define THHelpers_h

#import <UIKit/UIKit.h>

@class THPlaylist;

typedef void (^THAlertBasicAction)();
typedef void (^THAlertTextsAction)(NSArray<UITextField *> *);

#if __cplusplus
extern "C" {
#endif

// =============================================  UI components Helpers

UIBarButtonItem *system_item(UIBarButtonSystemItem sys, id target, SEL action);
UIBarButtonItem *custom_item(NSString *title, UIBarButtonItemStyle style, id target, SEL action);

UIAlertController *alert_add_word(THAlertTextsAction confirm_block);
UIAlertController *alert_edit_word(NSString *word_key, NSArray<NSString *> *texts,
                                   THAlertBasicAction cancel_block,
                                   THAlertTextsAction confirm_block);
UIAlertController *alert_add_word_conflicting(NSString *word_key, NSString *your_input,
                                              NSString *already_there,
                                              THAlertBasicAction cancel_block,
                                              THAlertBasicAction confirm_block);
UIAlertController *alert_edit_word_conflicting(NSString *old_key, NSString *new_key,
                                               NSString *your_input, NSString *already_there,
                                               THAlertBasicAction cancel_block,
                                               THAlertBasicAction confirm_block);
UIAlertController *alert_add_playlist(THAlertTextsAction confirm_block);
UIAlertController *alert_rename_playlist(NSString *partial_name, THAlertTextsAction confirm_block);
UIAlertController *alert_playlist_exists(NSString *partial_name, THAlertBasicAction block);
UIAlertController *alert_remove_item(NSString *name, THAlertBasicAction confirm_block);
UIAlertController *alert_remove_selected(THAlertBasicAction confirm_block);
UIAlertController *alert_more_info(NSString *more_info);
UIAlertController *action_sheet_selected_options_words(THAlertBasicAction create_block,
                                                       THAlertBasicAction copy_block,
                                                       THAlertBasicAction move_block,
                                                       THAlertBasicAction play_block);
UIAlertController *action_sheet_selected_options_playlists(THAlertBasicAction create_block,
                                                           THAlertBasicAction copy_block,
                                                           THAlertBasicAction play_block);
UIAlertController *action_sheet_selection_options(THAlertBasicAction select_all_block,
                                                  THAlertBasicAction clear_block,
                                                  THAlertBasicAction invert_block);
UIAlertController *alert_play(NSString *partial_name, THAlertBasicAction confirm_block);
UIAlertController *action_sheet_play_options(NSString *word_self, NSString *your_answer,
                                             THAlertBasicAction next_block,
                                             THAlertBasicAction typo_block,
                                             THAlertBasicAction edit_block,
                                             THAlertBasicAction remove_block);
UIAlertController *alert_play_empty_playlist(THAlertBasicAction block);
UIAlertController *action_sheet_play_finished_mistakes(THAlertBasicAction try_again_block,
                                                       THAlertBasicAction view_block,
                                                       THAlertBasicAction ack_block);
UIAlertController *alert_play_finished_no_mistakes(THAlertBasicAction block);
UIAlertController *alert_not_implemented(THAlertBasicAction block);
UIAlertController *alert_ask_for_secret(THAlertTextsAction block);

// =============================================  Fonts and Colors Helpers

UIFont *cj_regular(CGFloat size);
UIFont *cj_bold(CGFloat size);
UIFont *zh_light(CGFloat size);
UIFont *zh_medium(CGFloat size);
UIFont *zh_bold(CGFloat size);

UIColor *blue_color();
UIColor *light_blue_color();
UIColor *grey_color();
UIColor *grey_color_half();

// =============================================  Other Helpers

void shuffle(NSMutableArray *);

NSArray<NSString *> *texts_from_text_fields(NSArray<UITextField *> *text_fields);

NSIndexSet *index_set_from_index_paths(NSArray<NSIndexPath *> *index_paths);

UIAlertController *recover_alert_texts(UIAlertController *alert, NSArray<NSString *> *texts);

THPlaylist *try_to_create(NSString *partial_name);

#if __cplusplus
}  // Extern C
#endif

#endif /* THHelpers_h */
