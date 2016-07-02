#import "THKeyboardCellConfig.h"

static NSString *ja_font_normal = @"HiraKakuProN-W3";
static NSString *ja_font_bold = @"HiraKakuProN-W6";

@implementation THKeyboardCellConfig {
  UIFont *_font[numberOfKeyboardCellStates];
  UIColor *_textColor[numberOfKeyboardCellStates];
  UIColor *_backgroundColor[numberOfKeyboardCellStates];
  CGFloat _borderWidth[numberOfKeyboardCellStates];
  UIColor *_borderColor[numberOfKeyboardCellStates];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  THKeyboardCellConfig *copy = [[THKeyboardCellConfig alloc] init];
  for (int i = 0; i < numberOfKeyboardCellStates; ++i) {
    copy->_font[i] = _font[i];
    copy->_textColor[i] = _textColor[i];
    copy->_backgroundColor[i] = _backgroundColor[i];
    copy->_borderWidth[i] = _borderWidth[i];
    copy->_borderColor[i] = _borderColor[i];
  }
  return copy;
}

#pragma mark - public

+ (instancetype)specialCellConfig {
  THKeyboardCellConfig *instance = [[[self class] defaultJaInstance] copy];
  [instance setBackgroundColor:grey_color() state:kTHKeyboardCellStateNormal];
  [instance setBackgroundColor:grey_color_half() state:kTHKeyboardCellStateFocused];
  return instance;
}

+ (instancetype)actionCellConfig {
  THKeyboardCellConfig *instance = [[[self class] defaultJaInstance] copy];
  [instance setBackgroundColor:blue_color() state:kTHKeyboardCellStateFocused];
  [instance setBorderWidth:0.5 state:kTHKeyboardCellStateFocused];
  return instance;
}

+ (instancetype)hiraganaCharCellConfig {
  THKeyboardCellConfig *instance = [[[self class] defaultJaInstance] copy];
  [instance setFont:ja_normal_big() state:kTHKeyboardCellStatePopped];
  [instance setFont:ja_bold_big() state:kTHKeyboardCellStateFocused];
  [instance setBackgroundColor:blue_color() state:kTHKeyboardCellStateFocused];
  [instance setBackgroundColor:light_blue_color() state:kTHKeyboardCellStatePopped];
  [instance setBorderWidth:0.5 state:kTHKeyboardCellStateFocused];
  [instance setBorderWidth:0.5 state:kTHKeyboardCellStatePopped];
  return instance;
}

+ (instancetype)hiraganaLeftCellConfig {
  THKeyboardCellConfig *instance = [[[self class] defaultJaInstance] copy];
  [instance setBackgroundColor:grey_color_half() state:kTHKeyboardCellStateFocused];
  return instance;
}

+ (instancetype)hiraganaRightCellConfig {
  return [[self class] hiraganaLeftCellConfig];
}

// currently katakana has the same style as hiragana.
+ (instancetype)katakanaCharCellConfig {
  return [[self class] hiraganaCharCellConfig];
}

+ (instancetype)katakanaLeftCellConfig {
  return [[self class] hiraganaLeftCellConfig];
}

+ (instancetype)katakanaRightCellConfig {
  return [[self class] hiraganaRightCellConfig];
}

- (UIFont *)fontForState:(THKeyboardCellState)state {
  return _font[state];
}

- (UIColor *)textColorForState:(THKeyboardCellState)state {
  return _textColor[state];
}

- (UIColor *)backgroundColorForState:(THKeyboardCellState)state {
  return _backgroundColor[state];
}

- (CGFloat)borderWidthForState:(THKeyboardCellState)state {
  return _borderWidth[state];
}

- (UIColor *)borderColorForState:(THKeyboardCellState)state {
  return _borderColor[state];
}

+ (instancetype)defaultJaInstance {
  static dispatch_once_t once;
  static THKeyboardCellConfig *instance = nil;
  dispatch_once(&once, ^{
    instance = [[self alloc] init];
    [instance setFont:ja_normal_small() state:kTHKeyboardCellStateNormal];
    [instance setTextColor:[UIColor blackColor] state:kTHKeyboardCellStateNormal];
    [instance setTextColor:[UIColor lightGrayColor] state:kTHKeyboardCellStateFaded];
    [instance setBackgroundColor:[UIColor clearColor] state:kTHKeyboardCellStateNormal];
    [instance setBorderWidth:1 state:kTHKeyboardCellStateNormal];
    [instance setBorderColor:[UIColor lightGrayColor] state:kTHKeyboardCellStateNormal];
  });
  return instance;
}

+ (instancetype)defaultInstance {
  static dispatch_once_t once;
  static THKeyboardCellConfig *instance = nil;
  dispatch_once(&once, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

#pragma mark - private

- (instancetype)init {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < numberOfKeyboardCellStates; ++i) {
      _borderWidth[i] = -1;
    }
  }
  return self;
}

- (void)setFont:(UIFont *)font state:(THKeyboardCellState)state {
  _font[state] = font;
}

- (void)setTextColor:(UIColor *)color state:(THKeyboardCellState)state {
  _textColor[state] = color;
}

- (void)setBackgroundColor:(UIColor *)color state:(THKeyboardCellState)state {
  _backgroundColor[state] = color;
}

- (void)setBorderWidth:(CGFloat)width state:(THKeyboardCellState)state {
  _borderWidth[state] = width;
}

- (void)setBorderColor:(UIColor *)color state:(THKeyboardCellState)state {
  _borderColor[state] = color;
}

#pragma mark - helpers

static UIFont *ja_normal_small() {
  return [UIFont fontWithName:ja_font_normal size:16];
}

static UIFont *ja_normal_big() {
  return [UIFont fontWithName:ja_font_normal size:20];
}

/*
static UIFont *ja_bold_small() {
  return [UIFont fontWithName:ja_font_bold size:16];
}
*/

static UIFont *ja_bold_big() {
  return [UIFont fontWithName:ja_font_bold size:20];
}

static UIColor *blue_color() {
  // 007aff
  return [UIColor colorWithRed:0.00 green:0.48 blue:1.00 alpha:0.7];
}

static UIColor *light_blue_color() {
  // 5ac8fa
  return [UIColor colorWithRed:0.35 green:0.78 blue:0.98 alpha:0.4];
}

static UIColor *grey_color() {
  // c7c7cc
  return [UIColor colorWithRed:0.78 green:0.78 blue:0.80 alpha:1.0];
}

static UIColor *grey_color_half() {
  return [UIColor colorWithRed:0.78 green:0.78 blue:0.80 alpha:0.5];
}

@end
