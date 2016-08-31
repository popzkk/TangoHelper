#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, THKeyboardType) {
  // unknown can keep it the same as last time used.
  THKeyboardTypeUnknown = 0,
  // make the order as it appears on the keyboard.
  THKeyboardTypeNumber,
  THKeyboardTypeEnglish,
  THKeyboardTypeHiragana,
  THKeyboardTypeKatakana,
};

@protocol THKeyboardDelegate

- (void)actionCellTapped;

- (void)backCellTapped;

- (void)addContent:(NSString *)content;

- (NSString *)lastInput;

- (void)changeLastInputTo:(NSString *)content;

- (void)showNotImplementedDialog;

- (void)rightCellLongTapped;

- (void)askForSecretWithCallback:(id)callback;

@end

@interface THKeyboard : UIView

@property(nonatomic) THKeyboardType keyboardType;

@property(nonatomic, copy) NSString *actionText;

+ (instancetype)sharedInstanceWithKeyboardType:(THKeyboardType)type
                                    actionText:(NSString *)actionText
                                      delegate:(id<THKeyboardDelegate>)delegate;

@end
