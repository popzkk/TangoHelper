#import <UIKit/UIKit.h>

#define KEYBOARDCELL_HAS_BORDER_

typedef NS_ENUM(NSUInteger, THKeyboardCellState) {
  THKeyboardCellStateNormal = 0,
  THKeyboardCellStateFocused,
  // not used...
  THKeyboardCellStateFaded,
  THKeyboardCellStatePopped,
  // count the number of states.
  numberOfKeyboardCellStates,
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
#ifdef KEYBOARDCELL_HAS_BORDER
- (CGFloat)borderWidthForState:(THKeyboardCellState)state;
- (UIColor *)borderColorForState:(THKeyboardCellState)state;
#endif

@end
