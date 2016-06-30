#import "THKeyboard.h"
#import "THKeyboardConfig.h"
#import "THKeyboardCell.h"

static CGFloat kPadding = 3;

static NSUInteger numberCellIndex = 5;
static NSUInteger englishCellIndex = 10;
static NSUInteger hiraganaCellIndex = 15;
static NSUInteger katakanaCellIndex = 20;
static NSUInteger backCellIndex = 9;
static NSUInteger spaceCellIndex = 14;
static NSUInteger core[12] = {6, 7, 8, 11, 12, 13, 16, 17, 18, 21, 22, 23};
static NSUInteger leftCellCoreIndex = 9;
static NSUInteger rightCellCoreIndex = 11;

@implementation THKeyboard {
  THKeyboardCell *_cells[25];
  THKeyboardCell *_actionCell; // overlap with cells 19 and 24.
}

#pragma mark - UIView

- (void)layoutSubviews {
  CGRect frame = self.bounds;
  CGFloat width = (frame.size.width - 2 * kPadding) / 5;
  CGFloat height = (frame.size.height - 2 * kPadding) / 5;
  for (NSUInteger i = 0; i < 25; ++i) {
    NSUInteger r = i / 5, c = i % 5;
    _cells[i].frame =
        CGRectMake(kPadding + width * c, kPadding + height * r, width, height);
  }
  _actionCell.frame = CGRectMake(_cells[19].frame.origin.x,
                                 _cells[19].frame.origin.y, width, height * 2);
}

#pragma mark - public

+ (instancetype)sharedInstance {
  static dispatch_once_t once;
  static THKeyboard * sharedInstance = nil;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] initWithFrame:CGRectZero];
    [sharedInstance initAll];
  });
  return sharedInstance;
}

- (void)setKeyboardType:(THKeyboardType)keyboardType {
  _keyboardType = keyboardType;
  [self loadKeyboardWithType:keyboardType];
}

- (NSString *)actionText {
  return _actionCell.text;
}

- (void)setActionText:(NSString *)actionText {
  _actionCell.text = actionText;
}

#pragma mark - private

- (void)loadKeyboardWithType:(THKeyboardType)type {
  THKeyboardConfig *keyboardConfig;
  THKeyboardCellConfig *charCellConfig, *leftCellConfig, *rightCellConfig;
  switch (type) {
    case kTHKeyboardHiragana:
      keyboardConfig = [THKeyboardConfig hiraganaConfig];
      charCellConfig = [THKeyboardCellConfig hiraganaCharCellConfig];
      leftCellConfig = [THKeyboardCellConfig hiraganaLeftCellConfig];
      rightCellConfig = [THKeyboardCellConfig hiraganaRightCellConfig];
      break;
    case kTHKeyboardKatakana:
      keyboardConfig = [THKeyboardConfig katakanaConfig];
      charCellConfig = [THKeyboardCellConfig katakanaCharCellConfig];
      leftCellConfig = [THKeyboardCellConfig katakanaLeftCellConfig];
      rightCellConfig = [THKeyboardCellConfig katakanaRightCellConfig];
      break;
    default:
      NSLog(@"WARNING: unknown keyboard type!");
      charCellConfig = [THKeyboardCellConfig defaultInstance];
      leftCellConfig = [THKeyboardCellConfig defaultInstance];
      rightCellConfig = [THKeyboardCellConfig defaultInstance];
      break;
  }
  [self leftCell].config = leftCellConfig;
  [self rightCell].config = rightCellConfig;
  for (NSUInteger i = 0; i < 12; ++i) {
    THKeyboardCell *cell = [self cellAtCoreIndex:i];
    cell.text = keyboardConfig.texts[i];
    if (i != leftCellCoreIndex && i != rightCellCoreIndex) {
      cell.config = charCellConfig;
    }
  }
}

- (void)initAll {
  // add the action cell first so that other cells can cover it when necessary
  _actionCell = [[THKeyboardCell alloc] initWithFrame:CGRectZero];
  _actionCell.textAlignment = NSTextAlignmentCenter;
  _actionCell.layer.borderWidth = 0.5;
  _actionCell.layer.borderColor = [UIColor lightGrayColor].CGColor;
  [self addSubview:_actionCell];

  // init all the cells.
  for (NSUInteger i = 0; i < 25; ++i) {
    THKeyboardCell *cell = [[THKeyboardCell alloc] initWithFrame:CGRectZero];
    cell.textAlignment = NSTextAlignmentCenter;
    cell.numberOfLines = 0;
    cell.layer.borderWidth = 0.5;
    cell.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _cells[i] = cell;
    [self addSubview:cell];
  }

  // hide cells in the first row and cells for actionCell
  for (NSUInteger i = 0; i < 5; ++i) {
    _cells[i].hidden = YES;
  }
  _cells[19].hidden = YES;
  _cells[24].hidden = YES;

  // set texts and styles for constant cells
  [self numberCell].text = @"１２３";
  [self numberCell].config = [THKeyboardCellConfig numberCellConfig];
  [self englishCell].text = @"ＡＢＣ";
  [self englishCell].config = [THKeyboardCellConfig englishCellConfig];
  [self hiraganaCell].text = @"あいう";
  [self hiraganaCell].config = [THKeyboardCellConfig hiraganaCellConfig];
  [self katakanaCell].text = @"アイウ";
  [self katakanaCell].config = [THKeyboardCellConfig katakanaCellConfig];
  [self backCell].text = @"⌫";
  [self backCell].config = [THKeyboardCellConfig backCellConfig];
  [self spaceCell].text = @"空白";
  [self spaceCell].config = [THKeyboardCellConfig spaceCellConfig];
  // the action cell's text is set after init.
  _actionCell.config = [THKeyboardCellConfig actionCellConfig];
}

#pragma mark - helpers

- (THKeyboardCell *)numberCell {
  return _cells[numberCellIndex];
}

- (THKeyboardCell *)englishCell {
  return _cells[englishCellIndex];
}

- (THKeyboardCell *)hiraganaCell {
  return _cells[hiraganaCellIndex];
}

- (THKeyboardCell *)katakanaCell {
  return _cells[katakanaCellIndex];
}

- (THKeyboardCell *)backCell {
  return _cells[backCellIndex];
}

- (THKeyboardCell *)spaceCell {
  return _cells[spaceCellIndex];
}

- (THKeyboardCell *)cellAtCoreIndex:(NSUInteger)coreIndex {
  return _cells[core[coreIndex]];
}

- (THKeyboardCell *)leftCell {
  return [self cellAtCoreIndex:leftCellCoreIndex];
}

- (THKeyboardCell *)rightCell {
  return [self cellAtCoreIndex:rightCellCoreIndex];
}

@end
