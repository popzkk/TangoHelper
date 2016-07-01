#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, THKeyboardCellState) {
  kTHKeyboardCellStateNormal = 0,
  kTHKeyboardCellStateFocused,
  // not used...
  kTHKeyboardCellStateFaded,
  kTHKeyboardCellStatePopped,
  // count the number of states.
  numberOfKeyboardCellStates
};

@interface THKeyboardCellConfig : NSObject

+ (instancetype)defaultInstance;
+ (instancetype)defaultJaInstance;

+ (instancetype)specialCellConfig;

+ (instancetype)actionCellConfig;

+ (instancetype)hiraganaCharCellConfig;
+ (instancetype)hiraganaLeftCellConfig;
+ (instancetype)hiraganaRightCellConfig;

+ (instancetype)katakanaCharCellConfig;
+ (instancetype)katakanaLeftCellConfig;
+ (instancetype)katakanaRightCellConfig;

// add config for english and number...

- (UIFont *)fontForState:(THKeyboardCellState)state;
- (UIColor *)textColorForState:(THKeyboardCellState)state;
- (UIColor *)backgroundColorForState:(THKeyboardCellState)state;
- (CGFloat)borderWidthForState:(THKeyboardCellState)state;
- (UIColor *)borderColorForState:(THKeyboardCellState)state;

@end
