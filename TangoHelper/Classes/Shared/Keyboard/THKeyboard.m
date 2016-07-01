#import "THKeyboard.h"
#import "THKeyboardConfig.h"
#import "THKeyboardCell.h"
#import "THKeyboardCellConfig.h"

typedef NS_ENUM(NSUInteger, THKeyboardTouchState) {
  kTHKeyboardTouchStateNoTouch = 0,  // no touch
  kTHKeyboardTouchStateNormal,       // already touched, but not a char cell
  kTHKeyboardTouchStateMoving,       // already touched, and is a char cell
};

static CGFloat kPadding = 3;

static NSString *special_names[] = {@"１２３", @"ＡＢＣ", @"あいう", @"アイウ", @"⌫", @"空白"};
static const NSUInteger special_indexes[] = {5, 10, 15, 20, 9, 14};
static const NSUInteger core_indexes[12] = {6, 7, 8, 11, 12, 13, 16, 17, 18, 21, 22, 23};
static const NSUInteger leftCellCoreIndex = 9;
static const NSUInteger rightCellCoreIndex = 11;

@implementation THKeyboard {
  THKeyboardCell *_cells[25];
  THKeyboardCell *_actionCell;  // overlap with cells 19 and 24.

  THKeyboardTouchState _state;
  NSUInteger _startIndex;  // index of the cell when the touch begins.
  CGPoint _startPoint;     // touch point at the beginning.
  NSUInteger _lastIndex;
  NSUInteger _currentIndex;  // index of the cell when the user is moving.
}

#pragma mark - public

+ (instancetype)sharedInstance {
  static dispatch_once_t once;
  static THKeyboard *sharedInstance = nil;
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
      keyboardConfig = nil;
      charCellConfig = [THKeyboardCellConfig defaultInstance];
      leftCellConfig = [THKeyboardCellConfig defaultInstance];
      rightCellConfig = [THKeyboardCellConfig defaultInstance];
      break;
  }
  [self leftCell].config = leftCellConfig;
  [self rightCell].config = rightCellConfig;
  for (NSUInteger i = 0; i < 12; ++i) {
    THKeyboardCell *cell = [self cellAtCoreIndex:i];
    if (i != leftCellCoreIndex && i != rightCellCoreIndex) {
      cell.config = charCellConfig;
    }
    cell.text = [keyboardConfig.texts objectAtIndex:i];
    cell.arrow = [keyboardConfig.arrows objectAtIndex:i];
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
    _cells[i] = cell;
    [self addSubview:cell];
  }

  // hide cells in the first row and cells for actionCell
  for (NSUInteger i = 0; i < 5; ++i) {
    _cells[i].hidden = YES;
  }
  _cells[19].hidden = YES;
  _cells[24].hidden = YES;

  // set texts and styles for special cells
  for (NSUInteger i = 0; i < 6; ++i) {
    THKeyboardCell *cell = [self cellAtSpecialIndex:i];
    cell.text = special_names[i];
    cell.config = [THKeyboardCellConfig specialCellConfig];
  }

  // the action cell's text is set after init.
  _actionCell.config = [THKeyboardCellConfig actionCellConfig];
}

- (void)handleTouchedCharCell:(NSUInteger)index {
  // no need to save here as their states must be |Normal|.
  for (NSUInteger i = 0; i < 25; ++i) {
    _cells[i].state = kTHKeyboardCellStateFaded;
  }
  THKeyboardCell *cell = _cells[index];
  cell.state = kTHKeyboardCellStateFocused;
  THKeyboardCellConfig *config = nil;
  if (_keyboardType == kTHKeyboardHiragana) {
    config = [THKeyboardCellConfig hiraganaCharCellConfig];
  } else if (_keyboardType == kTHKeyboardKatakana) {
    config = [THKeyboardCellConfig katakanaCharCellConfig];
  } else {
    config = [THKeyboardCellConfig defaultInstance];
  }
  for (NSUInteger i = 0; i < cell.arrow.length; ++i) {
    THKeyboardCell *arrow = _cells[neighbor(index, i)];
    [arrow saveForState:kTHKeyboardCellStatePopped config:config];
    arrow.text = [cell.arrow substringWithRange:NSMakeRange(i, 1)];
    arrow.hidden = NO;
  }
}

#pragma mark - UIView

- (void)layoutSubviews {
  CGRect frame = self.bounds;
  CGFloat width = (frame.size.width - 2 * kPadding) / 5;
  CGFloat height = (frame.size.height - 2 * kPadding) / 5;
  for (NSUInteger i = 0; i < 25; ++i) {
    NSUInteger r = i / 5, c = i % 5;
    _cells[i].frame = CGRectMake(kPadding + width * c, kPadding + height * r, width, height);
  }
  _actionCell.frame =
      CGRectMake(_cells[19].frame.origin.x, _cells[19].frame.origin.y, width, 2 * height);
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  if (_state != kTHKeyboardTouchStateNoTouch) {
    NSLog(@"WARNING: touch must start with |NoTouch| state.");
    return;
  }
  if (touches.count != 1) {
    NSLog(@"WARNING %@ %@: multiple touches detected - a ramdom one will be used.",
          NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  }

  _startPoint = [[touches anyObject] locationInView:self];
  _currentIndex = _startIndex = [self touchedIndex:_startPoint];
  _lastIndex = NSNotFound;
  // touch is on the padding area.
  if (_startIndex == NSNotFound) {
    return;
  }
  // the first touch must fall into one of the visible cell.
  if (_startIndex > 4) {
    if (is_char_cell(index_to_core_index(_startIndex))) {
      [self handleTouchedCharCell:_startIndex];
      _state = kTHKeyboardTouchStateMoving;
    } else {
      _state = kTHKeyboardTouchStateNormal;
      if (_startIndex != 19 && _startIndex != 24) {
        _cells[_startIndex].state = kTHKeyboardCellStateFocused;
      } else {
        _actionCell.state = kTHKeyboardCellStateFocused;
      }
    }
    // NSLog(@"touchesBegin: %lu", _startIndex);
  }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  // if _state is not updated, that means the user touches on the invisible cells
  // or the touch is cancelled or ...
  if (_state == kTHKeyboardTouchStateNoTouch) {
    return;
  }

  if (touches.count != 1) {
    NSLog(@"WARNING %@ %@: multiple touches detected - a ramdom one will be used.",
          NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  }

  CGPoint point = [[touches anyObject] locationInView:self];
  NSUInteger index = [self touchedIndex:point];
  if (_state == kTHKeyboardTouchStateMoving) {
    if (index != _startIndex) {
      CGVector vec = CGVectorMake(point.x - _startPoint.x, point.y - _startPoint.y);
      index = calc_neighbor(_startIndex, vec);
    }
    if (index < 25 && belongs_to_cross(_cells[index])) {
      _lastIndex = _currentIndex;
      _currentIndex = index;
      _cells[_lastIndex].state = kTHKeyboardCellStatePopped;
      _cells[_currentIndex].state = kTHKeyboardCellStateFocused;
    }
  }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  // if _state is not updated, that means the user touches on the invisible cells
  // or the touch is cancelled or ...
  if (_state == kTHKeyboardTouchStateNoTouch) {
    return;
  }

  if (touches.count != 1) {
    NSLog(@"WARNING %@ %@: multiple touches detected - a ramdom one will be used.",
          NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  }

  CGPoint point = [[touches anyObject] locationInView:self];
  NSUInteger index = [self touchedIndex:point];

  if (_state == kTHKeyboardTouchStateMoving) {
    NSLog(@"Output: %@", _cells[_currentIndex].text);
    for (NSUInteger i = 0; i < _cells[_startIndex].arrow.length; ++i) {
      [_cells[neighbor(_startIndex, i)] restore];
    }
    for (NSUInteger i = 0; i < 25; ++i) {
      _cells[i].state = kTHKeyboardCellStateNormal;
    }
  } else if (_state == kTHKeyboardTouchStateNormal) {
    if ((index == 19 && _startIndex == 19) || (index == 24 && _startIndex == 24) ||
        (index == 19 && _startIndex == 24) || (index == 24 && _startIndex == 19)) {
      NSLog(@"Action Cell tapped");
    } else if (index == _startIndex) {
      NSLog(@"Cell %@ tapped", _cells[_startIndex].text);
    }
    if (_startIndex == 19 || _startIndex == 24) {
      _actionCell.state = kTHKeyboardCellStateNormal;
    } else {
      _cells[_startIndex].state = kTHKeyboardCellStateNormal;
    }
  }

  _state = kTHKeyboardTouchStateNoTouch;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  // for any reason, we set it back to |NoTouch| so a new touch can begin.
  _state = kTHKeyboardTouchStateNoTouch;
  for (NSUInteger i = 0; i < _cells[_startIndex].arrow.length; ++i) {
    [_cells[neighbor(_startIndex, i)] restore];
  }
  for (NSUInteger i = 0; i < 25; ++i) {
    _cells[i].state = kTHKeyboardCellStateNormal;
  }
}

// this is only available after iOS 9.1
- (void)touchesEstimatedPropertiesUpdated:(NSSet *)touches {
}

#pragma mark - helpers

- (THKeyboardCell *)cellAtSpecialIndex:(NSUInteger)specialIndex {
  return _cells[special_indexes[specialIndex]];
}

- (THKeyboardCell *)cellAtCoreIndex:(NSUInteger)coreIndex {
  return _cells[core_indexes[coreIndex]];
}

- (THKeyboardCell *)leftCell {
  return [self cellAtCoreIndex:leftCellCoreIndex];
}

- (THKeyboardCell *)rightCell {
  return [self cellAtCoreIndex:rightCellCoreIndex];
}

- (NSUInteger)touchedIndex:(CGPoint)point {
  for (NSUInteger index = 0; index < 25; ++index) {
    if (CGRectContainsPoint(_cells[index].frame, point)) {
      return index;
    }
  }
  return NSNotFound;
}

static NSUInteger neighbor(NSUInteger index, NSUInteger arrow) {
  switch (arrow) {
    // left
    case 0:
      return index - 1;
    // up
    case 1:
      return index - 5;
    // right
    case 2:
      return index + 1;
    // down
    case 3:
      return index + 5;
    default:
      NSLog(@"WARNING: arrow number greater than 4!");
      return NSNotFound;
  }
}

static BOOL is_char_cell(NSUInteger coreIndex) {
  return coreIndex != leftCellCoreIndex && coreIndex != rightCellCoreIndex &&
         coreIndex != NSNotFound;
}

static NSUInteger index_to_core_index(NSUInteger index) {
  for (NSUInteger i = 0; i < 12; ++i) {
    if (core_indexes[i] == index) {
      return i;
    }
  }
  return NSNotFound;
}

static NSUInteger calc_neighbor(NSUInteger index, CGVector vec) {
  CGFloat len = sqrt(vec.dx * vec.dx + vec.dy * vec.dy);
  CGFloat cos = vec.dx / len;
  CGFloat thres = cos * sqrt(2);
  if (thres > 1) {
    // right
    return neighbor(index, 2);
  } else if (thres > -1) {
    if (vec.dy < 0) {
      // up
      return neighbor(index, 1);
    } else {
      // down
      return neighbor(index, 3);
    }
  } else {
    // left
    return neighbor(index, 0);
  }
  return NSNotFound;
}

static BOOL belongs_to_cross(THKeyboardCell *cell) {
  return cell.state == kTHKeyboardCellStatePopped || cell.state == kTHKeyboardCellStateFocused;
}

@end
