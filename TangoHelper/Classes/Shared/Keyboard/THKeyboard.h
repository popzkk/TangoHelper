#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, THKeyboardType) {
  kTHKeyboardUnknown = 0,
  //kTHKeyboardNumber,
  //kTHKeyboardEnglish,
  kTHKeyboardHiragana,
  kTHKeyboardKatakana
};

@protocol THKeyboardDelegate <NSObject>

- (void)customButtonTapped;

@end

@interface THKeyboard : UIView

@property(nonatomic, weak) id<THKeyboardDelegate> delegate;
@property(nonatomic) THKeyboardType keyboardType;
@property(nonatomic, copy) NSString *actionText;
// should support set/get text.
@property(nonatomic) UIView *targetView;

+ (instancetype)sharedInstance;

@end
