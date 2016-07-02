#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, THKeyboardType) {
  kTHKeyboardHiragana = 0,
  kTHKeyboardKatakana,
  //kTHKeyboardNumber,
  //kTHKeyboardEnglish
};

@protocol THKeyboardDelegate <NSObject>

- (void)actionCellTapped;

@end

@interface THKeyboard : UIView

@property(nonatomic, weak) id<THKeyboardDelegate> delegate;
@property(nonatomic) THKeyboardType keyboardType;
@property(nonatomic, copy) NSString *actionText;
// should support set/get text.
@property(nonatomic) UIView *targetView;

+ (instancetype)sharedInstance;

@end
