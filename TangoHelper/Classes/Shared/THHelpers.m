#import "THHelpers.h"
#import "THStrings.h"

#if __cplusplus
extern "C" {
#endif

UIBarButtonItem *system_item(UIBarButtonSystemItem sys, id target, SEL action) {
  return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:sys target:target action:action];
}

UIBarButtonItem *custom_item(NSString *title, UIBarButtonItemStyle style, id target,
                                    SEL action) {
  return [[UIBarButtonItem alloc] initWithTitle:title style:style target:target action:action];
}

UIAlertController *basic_alert(NSString *title, NSString *message,
                                      THBasicAlertConfirmAction block) {
  UIAlertController *alert =
  [UIAlertController alertControllerWithTitle:title
                                      message:message
                               preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:kCancel
                                            style:UIAlertActionStyleDefault
                                          handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:kConfirm
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            block();
                                          }]];
  return alert;
}

UIAlertController *texts_alert(NSString *title, NSString *message, NSArray *texts,
                                      NSArray *placeholders, THTextsAlertConformAction block) {
  UIAlertController *alert =
  [UIAlertController alertControllerWithTitle:title
                                      message:message
                               preferredStyle:UIAlertControllerStyleAlert];
  if (texts.count != placeholders.count) {
    NSLog(@"cannot create 'texts_alert': inconsistant number of elements");
    return nil;
  }
  for (NSUInteger i = 0; i < texts.count; ++i) {
    NSString *text = texts[i];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      if (text.length == 0) {
        textField.placeholder = placeholders[i];
      } else {
        textField.text = text;
      }
    }];
  }
  [alert addAction:[UIAlertAction actionWithTitle:kCancel
                                            style:UIAlertActionStyleDefault
                                          handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:kConfirm
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            block(alert.textFields);
                                          }]];
  return alert;
}

#if __cplusplus
}  // Extern C
#endif
