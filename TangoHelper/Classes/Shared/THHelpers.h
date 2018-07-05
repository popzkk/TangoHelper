#ifndef THHelpers_h
#define THHelpers_h

#import <UIKit/UIKit.h>

@class THPlaylist;

typedef void (^THAlertBasicAction)(void);
typedef void (^THAlertTextsAction)(NSArray<UITextField *> *);

// =============================================  UI components Helpers

FOUNDATION_EXPORT UIBarButtonItem *system_item(UIBarButtonSystemItem sys, id target, SEL action);
FOUNDATION_EXPORT UIBarButtonItem *custom_item(NSString *title, UIBarButtonItemStyle style,
                                               id target, SEL action);

FOUNDATION_EXPORT UIAlertController *dialog_add_playlist(THAlertTextsAction confirm_block);
FOUNDATION_EXPORT UIAlertController *dialog_rename_playlist(NSString *partial_name,
                                                            THAlertTextsAction confirm_block);
FOUNDATION_EXPORT UIAlertController *dialog_playlist_exists(NSString *partial_name,
                                                            THAlertBasicAction block);
FOUNDATION_EXPORT UIAlertController *dialog_add_word(THAlertTextsAction confirm_block);
FOUNDATION_EXPORT UIAlertController *dialog_edit_word(NSString *word_key,
                                                      NSArray<NSString *> *texts,
                                                      THAlertBasicAction cancel_block,
                                                      THAlertTextsAction confirm_block);
FOUNDATION_EXPORT UIAlertController *dialog_add_word_conflicting(NSString *word_key,
                                                                 NSString *your_input,
                                                                 NSString *already_there,
                                                                 THAlertBasicAction cancel_block,
                                                                 THAlertBasicAction confirm_block);
FOUNDATION_EXPORT UIAlertController *dialog_edit_word_conflicting(
    NSString *old_key, NSString *new_key, NSString *your_input, NSString *already_there,
    THAlertBasicAction cancel_block, THAlertBasicAction confirm_block);
FOUNDATION_EXPORT UIAlertController *dialog_remove_item(NSString *name,
                                                        THAlertBasicAction confirm_block);
FOUNDATION_EXPORT UIAlertController *dialog_remove_selected(THAlertBasicAction confirm_block);
FOUNDATION_EXPORT UIAlertController *dialog_more_info(NSString *more_info);
FOUNDATION_EXPORT UIAlertController *sheet_selected_options(
    THAlertBasicAction play_block, THAlertBasicAction create_block,
    THAlertBasicAction copy_to_playlists_block);
FOUNDATION_EXPORT UIAlertController *sheet_selection_options(THAlertBasicAction select_all_block,
                                                             THAlertBasicAction clear_block,
                                                             THAlertBasicAction invert_block);
FOUNDATION_EXPORT UIAlertController *dialog_play(NSString *partial_name,
                                                 THAlertBasicAction confirm_block);
FOUNDATION_EXPORT UIAlertController *sheet_play_options(NSString *word_self, NSString *your_answer,
                                                        THAlertBasicAction next_block,
                                                        THAlertBasicAction typo_block,
                                                        THAlertBasicAction edit_block,
                                                        THAlertBasicAction remove_block);
FOUNDATION_EXPORT UIAlertController *dialog_play_empty_playlist(THAlertBasicAction block);
FOUNDATION_EXPORT UIAlertController *sheet_play_finished_mistakes(
    THAlertBasicAction try_again_block, THAlertBasicAction view_block,
    THAlertBasicAction ack_block);
FOUNDATION_EXPORT UIAlertController *dialog_play_finished_no_mistakes(THAlertBasicAction block);
FOUNDATION_EXPORT UIAlertController *dialog_not_implemented(THAlertBasicAction block);
FOUNDATION_EXPORT UIAlertController *dialog_ask_for_secret(THAlertTextsAction block);
FOUNDATION_EXPORT UIAlertController *dialog_special_playlist_disallowed(void);

// =============================================  Fonts and Colors Helpers

FOUNDATION_EXPORT UIFont *ja_normal(CGFloat size);
FOUNDATION_EXPORT UIFont *ja_bold(CGFloat size);
FOUNDATION_EXPORT UIFont *zh_normal(CGFloat size);
FOUNDATION_EXPORT UIFont *zh_bold(CGFloat size);

FOUNDATION_EXPORT UIColor *blue_color(void);
FOUNDATION_EXPORT UIColor *light_blue_color(void);
FOUNDATION_EXPORT UIColor *grey_color(void);
FOUNDATION_EXPORT UIColor *grey_color_half(void);

// =============================================  Other Helpers

FOUNDATION_EXPORT void shuffle(NSMutableArray *);

FOUNDATION_EXPORT NSArray<NSString *> *texts_from_text_fields(NSArray<UITextField *> *text_fields);

FOUNDATION_EXPORT NSIndexSet *index_set_from_index_paths(NSArray<NSIndexPath *> *index_paths);

FOUNDATION_EXPORT UIAlertController *recover_dialog_texts(UIAlertController *alert,
                                                          NSArray<NSString *> *texts);

#endif /* THHelpers_h */
