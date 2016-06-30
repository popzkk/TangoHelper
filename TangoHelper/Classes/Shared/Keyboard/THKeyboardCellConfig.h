#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, THKeyboardCellState) {
  kTHKeyboardCellStateNormal = 0,
  kTHKeyboardCellStateFocused,
  // count the number of states.
  numberOfKeyboardCellStates
};

@interface THKeyboardCellConfig : NSObject

+ (instancetype)defaultInstance;

+ (instancetype)numberCellConfig;
+ (instancetype)englishCellConfig;
+ (instancetype)hiraganaCellConfig;
+ (instancetype)katakanaCellConfig;
+ (instancetype)backCellConfig;
+ (instancetype)spaceCellConfig;
+ (instancetype)actionCellConfig;

+ (instancetype)hiraganaCharCellConfig;
+ (instancetype)hiraganaLeftCellConfig;
// + (instancetype)hiraganaRightCellConfig;

+ (instancetype)katakanaCharCellConfig;
+ (instancetype)katakanaLeftCellConfig;
// + (instancetype)katakanaRightCellConfig;

// Add config for english and number...

- (UIFont *)fontForState:(THKeyboardCellState)state;
- (UIColor *)textColorForState:(THKeyboardCellState)state;
- (UIColor *)backgroundColorForState:(THKeyboardCellState)state;
@end
