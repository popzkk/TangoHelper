#ifndef THHelpers_h
#define THHelpers_h

#import <UIKit/UIKit.h>

typedef void (^THBasicAlertConfirmAction)();
typedef void (^THTextsAlertConformAction)(NSArray<UITextField *> *);

#if __cplusplus
extern "C" {
#endif

UIBarButtonItem *system_item(UIBarButtonSystemItem sys, id target, SEL action);

UIBarButtonItem *custom_item(NSString *title, UIBarButtonItemStyle style, id target, SEL action);

UIAlertController *basic_alert(NSString *title, NSString *message, THBasicAlertConfirmAction block);
UIAlertController *texts_alert(NSString *title, NSString *message, NSArray *texts,
                               NSArray *placeholders, THTextsAlertConformAction block);

#if __cplusplus
}  // Extern C
#endif

#endif /* THHelpers_h */
