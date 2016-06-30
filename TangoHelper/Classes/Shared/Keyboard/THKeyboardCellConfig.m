#import "THKeyboardCellConfig.h"

static NSString *ja_font_normal = @"HiraKakuProN-W3";
static NSString *ja_font_bold = @"HiraKakuProN-W6";

@implementation THKeyboardCellConfig {
  UIFont *_font[numberOfKeyboardCellStates];
  UIColor *_textColor[numberOfKeyboardCellStates];
  UIColor *_backgroundColor[numberOfKeyboardCellStates];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  THKeyboardCellConfig *copy = [[THKeyboardCellConfig alloc] init];
  memccpy(copy->_font, self->_font, numberOfKeyboardCellStates, sizeof(UIFont *));
  memccpy(copy->_textColor, self->_textColor, numberOfKeyboardCellStates, sizeof(UIColor *));
  memccpy(copy->_backgroundColor, self->_backgroundColor, numberOfKeyboardCellStates, sizeof(UIColor *));
  return copy;
}

#pragma mark - public

+ (instancetype)numberCellConfig {
  return [[self class] defaultInstance];
}

+ (instancetype)englishCellConfig {
  return [[self class] defaultInstance];
}

+ (instancetype)hiraganaCellConfig {
  return [[self class] defaultInstance];
}

+ (instancetype)katakanaCellConfig {
  return [[self class] defaultInstance];
}

+ (instancetype)backCellConfig {
  THKeyboardCellConfig *instance = [[[self class] defaultInstance] copy];
  instance->_font[kTHKeyboardCellStateNormal] = [UIFont fontWithName:ja_font_normal size:17];
  instance->_font[kTHKeyboardCellStateFocused] = [UIFont fontWithName:ja_font_bold size:17];
  return instance;
}

+ (instancetype)spaceCellConfig {
  return [[self class] defaultInstance];
}

+ (instancetype)actionCellConfig {
  return [[self class] defaultInstance];
}

+ (instancetype)hiraganaCharCellConfig {
  THKeyboardCellConfig *instance = [[[self class] defaultInstance] copy];
  instance->_font[kTHKeyboardCellStateNormal] = [UIFont fontWithName:ja_font_normal size:20];
  instance->_font[kTHKeyboardCellStateFocused] = [UIFont fontWithName:ja_font_bold size:20];
  return instance;
}

+ (instancetype)hiraganaLeftCellConfig {
  return [[self class] defaultInstance];
}

+ (instancetype)hiraganaRightCellConfig {
  return [[self class] hiraganaLeftCellConfig];
}

// currently katakana has the style as hiragana.
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

#pragma mark - private

+ (instancetype)defaultInstance {
  static dispatch_once_t once;
  static THKeyboardCellConfig *instance = nil;
  dispatch_once(&once, ^{
    instance = [[self alloc] init];
    instance->_font[kTHKeyboardCellStateNormal] = [UIFont fontWithName:ja_font_normal size:16];
    instance->_font[kTHKeyboardCellStateFocused] = [UIFont fontWithName:ja_font_bold size:16];
  });
  return instance;
}

@end