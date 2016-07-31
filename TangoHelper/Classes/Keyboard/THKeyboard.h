#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, THKeyboardType) {
  // unknown can keep it the same as last time used.
  kTHKeyboardUnknown = 0,
  // make the order as it appears on the keyboard.
  kTHKeyboardNumber,
  kTHKeyboardEnglish,
  kTHKeyboardHiragana,
  kTHKeyboardKatakana
};

@protocol THKeyboardDelegate<NSObject>

- (void)actionCellTapped;

- (void)backCellTapped;

- (void)addContent:(NSString *)content;

- (NSString *)lastInput;

- (void)changeLastInputTo:(NSString *)content;

- (void)showNotImplementedDialog;

- (void)rightCellLongTapped;

@end

@interface THKeyboard : UIView

@property(nonatomic) THKeyboardType keyboardType;

@property(nonatomic, copy) NSString *actionText;

+ (instancetype)sharedInstanceWithKeyboardType:(THKeyboardType)type
                                    actionText:(NSString *)actionText
                                      delegate:(id<THKeyboardDelegate>)delegate;

@end
