#import "THKeyboard.h"

#import "THKeyboardCell.h"
#import "THKeyboardCellConfig.h"
#import "THKeyboardCharTransformer.h"
#import "THKeyboardConfig.h"

/** TODO
 * merge hiragana and katakana buttons and add a button to switch to system keyboards.
 */

typedef NS_ENUM(NSUInteger, THKeyboardTouchState) {
  THKeyboardTouchStateNoTouch = 0,  // no touch
  THKeyboardTouchStateNormal,       // already touched, but not a char cell
  THKeyboardTouchStateMoving,       // already touched, and is a char cell
};

typedef NS_ENUM(NSUInteger, THKeyboardTouchResult) {
  THKeyboardTouchResultUnknown = 0,  // not implemented
  THKeyboardTouchResultText,         // add or delete text
  THKeyboardTouchResultSelf,         // touched on a cell related to the keyboard itself
  THKeyboardTouchResultLeft,         // touched on the left cell
  THKeyboardTouchResultRight,        // touched on the right cell
  THKeyboardTouchResultAction,       // touched on the action cell
};

static const NSUInteger numberCellIndex = 5;
static const NSUInteger englishCellIndex = 10;
static const NSUInteger hiraganaCellIndex = 15;
static const NSUInteger katakanaCellIndex = 20;
static const NSUInteger backCellIndex = 9;
static const NSUInteger spaceCellIndex = 14;
static NSString *special_names[] = {@"１２３", @"ＡＢＣ", @"あいう", @"アイウ", @"⌫", @"空白"};
static const NSUInteger hiraganaCellSpecialIndex = 2;
static const NSUInteger katakanaCellSpecialIndex = 3;
static const NSUInteger special_indexes[] = {numberCellIndex,   englishCellIndex, hiraganaCellIndex,
                                             katakanaCellIndex, backCellIndex,    spaceCellIndex};
static const NSUInteger core_indexes[12] = {6, 7, 8, 11, 12, 13, 16, 17, 18, 21, 22, 23};
static const NSUInteger leftCellCoreIndex = 9;
static const NSUInteger leftCellIndex = 21;  // core_indexes[leftCellCoreIndex]
static const NSUInteger rightCellCoreIndex = 11;
static const NSUInteger rightCellIndex = 23;  // core_indexes[rightCellCoreIndex]

@implementation THKeyboard {
  THKeyboardCell *_cells[25];
  THKeyboardCell *_actionCell;  // overlap with cells 19 and 24.

  __weak id<THKeyboardDelegate> _delegate;

  THKeyboardTouchState _state;
  NSUInteger _startIndex;       // index of the cell when the touch begins.
  BOOL _crossIsShown;           // whether the cross is shown.
  CGPoint _startPoint;          // touch point at the beginning.
  NSUInteger _previousIndex;    // the previous index of the cell when the user is moving.
  NSUInteger _currentIndex;     // index of the cell when the user is moving.
  NSTimeInterval _startTime;    // start time of the touch.
  NSInteger _rightTappedCount;  // how many times the right cell is tapped. -1 means changed.
  NSTimeInterval _lastTime;     // finish time of the last tap.
}

#pragma mark - public

+ (instancetype)sharedInstanceWithKeyboardType:(THKeyboardType)type
                                    actionText:(NSString *)actionText
                                      delegate:(id<THKeyboardDelegate>)delegate {
  THKeyboard *sharedInstance = [self sharedInstance];
  if (type != THKeyboardTypeUnknown) {
    [sharedInstance setKeyboardType:type];
  }
  if (actionText.length) {
    [sharedInstance setActionText:actionText];
  }
  sharedInstance->_delegate = delegate;
  return sharedInstance;
}

- (void)setKeyboardType:(THKeyboardType)keyboardType {
  if (keyboardType == _keyboardType) {
    return;
  }

  _cells[keyboardType * 5].state = THKeyboardCellStateFocused;
  _cells[_keyboardType * 5].state = THKeyboardCellStateNormal;
  _keyboardType = keyboardType;

  THKeyboardConfig *keyboardConfig;
  THKeyboardCellConfig *charCellConfig, *leftCellConfig, *rightCellConfig;
  switch (keyboardType) {
    case THKeyboardTypeHiragana:
      keyboardConfig = [THKeyboardConfig hiraganaConfig];
      charCellConfig = [THKeyboardCellConfig hiraganaCharCellConfig];
      leftCellConfig = [THKeyboardCellConfig hiraganaLeftCellConfig];
      rightCellConfig = [THKeyboardCellConfig hiraganaRightCellConfig];
      break;
    case THKeyboardTypeKatakana:
      keyboardConfig = [THKeyboardConfig katakanaConfig];
      charCellConfig = [THKeyboardCellConfig katakanaCharCellConfig];
      leftCellConfig = [THKeyboardCellConfig katakanaLeftCellConfig];
      rightCellConfig = [THKeyboardCellConfig katakanaRightCellConfig];
      break;
    default:
      NSLog(@"WARNING: unknown keyboard type!");
      return;
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

- (NSString *)actionText {
  return _actionCell.text;
}

- (void)setActionText:(NSString *)actionText {
  _actionCell.text = actionText;
}

#pragma mark - private

+ (instancetype)sharedInstance {
  static dispatch_once_t once;
  static THKeyboard *sharedInstance = nil;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] initWithFrame:CGRectZero];
    [sharedInstance initAll];
  });
  return sharedInstance;
}

- (void)initAll {
  // add the action cell first so that other cells can cover it when necessary.
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

  // hide cells in the first row and cells for actionCell.
  for (NSUInteger i = 0; i < 5; ++i) {
    _cells[i].hidden = YES;
  }
  _cells[19].hidden = YES;
  _cells[24].hidden = YES;

  // set texts and styles for special cells.
  for (NSUInteger i = 0; i < 6; ++i) {
    THKeyboardCell *cell = [self cellAtSpecialIndex:i];
    cell.text = special_names[i];
    cell.config = [THKeyboardCellConfig specialCellConfig];
  }

  // the default action text.
  self.actionText = @"確認";
  _actionCell.config = [THKeyboardCellConfig actionCellConfig];

  // by default, starts with hiragana.
  self.keyboardType = THKeyboardTypeHiragana;
}

- (void)touchedCharCellWillMove {
  if (_crossIsShown) {
    return;
  }
  _crossIsShown = YES;

  for (NSUInteger i = 0; i < 25; ++i) {
    [_cells[i] save];
  }

  THKeyboardCell *cell = _cells[_startIndex];
  [cell onlySetState:THKeyboardCellStateFocused];

  THKeyboardCellConfig *config = char_cell_config(_keyboardType);
  for (NSUInteger i = 0; i < cell.arrow.length; ++i) {
    THKeyboardCell *arrow = _cells[neighbor(_startIndex, i)];
    [arrow onlySetState:THKeyboardCellStatePopped];
    [arrow onlySetConfig:config];
    arrow.text = [cell.arrow substringWithRange:NSMakeRange(i, 1)];
    arrow.hidden = NO;
  }

  for (NSUInteger i = 0; i < 25; ++i) {
    [_cells[i] configSelf];
  }
}

- (void)touchedCharCellReleased {
  if (!_crossIsShown) {
    return;
  }
  _crossIsShown = NO;
  for (NSUInteger i = 0; i < 25; ++i) {
    [_cells[i] restore];
  }
}

- (void)commitTouchResult:(THKeyboardTouchResult)result object:(id)object {
  NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
  NSTimeInterval interval = currentTime - _startTime;
  NSTimeInterval intervalSinceLastTime = currentTime - _lastTime;
  switch (result) {
    // show a nice dialog to explain.
    case THKeyboardTouchResultUnknown:
      [_delegate showNotImplementedDialog];
      break;
    // the right cell has some secret function?
    case THKeyboardTouchResultRight:
      if (interval < 0.7) {
        if (_rightTappedCount <= 0 || intervalSinceLastTime < 0.7) {
          ++_rightTappedCount;
          if (_rightTappedCount > 11) {
            _rightTappedCount = 1;
          }
          if (_rightTappedCount == 11) {
            [_delegate askForSecretWithCallback:^(NSArray<UITextField *> *textFields) {
              if ([textFields.firstObject.text isEqualToString:@"11"]) {
                [self updateSecretCells];
              }
            }];
          } else if (_rightTappedCount == 0) {
            [self updateSecretCells];
          }
        }
      } else {
        _rightTappedCount = MIN(_rightTappedCount, 0);
        // holding the right cell longer than 3s will be regarded as a long tap.
        if (interval > 3) {
          [_delegate rightCellLongTapped];
        }
      }
      break;
    case THKeyboardTouchResultAction:
      [_delegate actionCellTapped];
      break;
    case THKeyboardTouchResultLeft:
      [_delegate
          changeLastInputTo:[transformer(_keyboardType) nextFormOfContent:[_delegate lastInput]]];
      break;
    case THKeyboardTouchResultSelf:
      self.keyboardType = keyboard_type(object);
      break;
    default:  // kTHKeyboardTouchResultText
      if ([object isEqualToString:@"⌫"]) {
        [_delegate backCellTapped];
      } else if ([object isEqualToString:@"空白"]) {
        // not sure if we should always use the english space.
        [_delegate addContent:@" "];
      } else {
        [_delegate addContent:object];
      }
      break;
  }
  _lastTime = currentTime;
}

- (void)updateSecretCells {
  if (_rightTappedCount == 11) {
    _rightTappedCount = -1;
    special_names[hiraganaCellSpecialIndex] = @"うの";
    special_names[katakanaCellSpecialIndex] = @"マロニー";
  } else {
    special_names[hiraganaCellSpecialIndex] = @"あいう";
    special_names[katakanaCellSpecialIndex] = @"アイウ";
  }
  [self cellAtSpecialIndex:hiraganaCellSpecialIndex].text = special_names[hiraganaCellSpecialIndex];
  [self cellAtSpecialIndex:katakanaCellSpecialIndex].text = special_names[katakanaCellSpecialIndex];
}

#pragma mark - UIView

- (void)setFrame:(CGRect)frame {
  CGFloat height = frame.size.height / 4;
  [super setFrame:CGRectMake(frame.origin.x, frame.origin.y - height, frame.size.width,
                             frame.size.height + height)];
}

- (void)layoutSubviews {
  CGRect frame = self.bounds;
  CGFloat width = frame.size.width / 5;
  CGFloat height = frame.size.height / 5;
  for (NSUInteger i = 0; i < 25; ++i) {
    NSUInteger r = i / 5, c = i % 5;
    _cells[i].frame = CGRectMake(width * c, height * r, width, height);
  }
  _actionCell.frame =
      CGRectMake(_cells[19].frame.origin.x, _cells[19].frame.origin.y, width, 2 * height);
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  if (_state != THKeyboardTouchStateNoTouch) {
    NSLog(@"WARNING: touch must start with |NoTouch| state.");
    return;
  }
  if (touches.count != 1) {
    NSLog(@"WARNING %@ %@: multiple touches detected - a ramdom one will be used.",
          NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  }

  _startPoint = [[touches anyObject] locationInView:self];
  _startTime = [NSDate timeIntervalSinceReferenceDate];
  _currentIndex = _startIndex = [self touchedIndex:_startPoint];
  _previousIndex = NSNotFound;
  // touch is on the padding area or the first row.
  if (_startIndex < 5 || _startIndex == NSNotFound) {
    return;
  }
  _state = THKeyboardTouchStateNormal;
  if (_startIndex != 19 && _startIndex != 24) {
    _cells[_startIndex].state = THKeyboardCellStateFocused;
  } else {
    _actionCell.state = THKeyboardCellStateFocused;
  }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  // if _state is not updated, that means the user touches on the invisible cells
  // or the touch is cancelled or ...
  if (_state == THKeyboardTouchStateNoTouch) {
    return;
  }

  if (touches.count != 1) {
    NSLog(@"WARNING %@ %@: multiple touches detected - a ramdom one will be used.",
          NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  }

  CGPoint point = [[touches anyObject] locationInView:self];
  NSUInteger index = [self touchedIndex:point];

  if (_state != THKeyboardTouchStateMoving) {
    // only show the cross if the touch moves out of the start index.
    if (index != _startIndex && is_char_cell(index_to_core_index(_startIndex))) {
      _state = THKeyboardTouchStateMoving;
    }
  }

  if (_state == THKeyboardTouchStateMoving) {
    [self touchedCharCellWillMove];
    if (index != _startIndex) {
      CGVector vec = CGVectorMake(point.x - _startPoint.x, point.y - _startPoint.y);
      index = calc_neighbor(_startIndex, vec);
    }
    if (index < 25 && belongs_to_cross(_cells[index])) {
      _previousIndex = _currentIndex;
      _currentIndex = index;
      _cells[_previousIndex].state = THKeyboardCellStatePopped;
      _cells[_currentIndex].state = THKeyboardCellStateFocused;
    }
  }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  // if _state is not updated, that means the user touches on the invisible cells
  // or the touch is cancelled or ...
  if (_state == THKeyboardTouchStateNoTouch) {
    return;
  }

  if (touches.count != 1) {
    NSLog(@"WARNING %@ %@: multiple touches detected - a ramdom one will be used.",
          NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  }

  // don't update _lastTime here - it will be used in |commitTouchResult:|.
  CGPoint point = [[touches anyObject] locationInView:self];
  NSUInteger index = [self touchedIndex:point];

  if (_state == THKeyboardTouchStateMoving) {
    // restore the keyboard to the normal UI first as the delegate may cost a lot of time.
    NSString *content = _cells[_currentIndex].text;
    [self touchedCharCellReleased];
    _cells[_startIndex].state = THKeyboardCellStateNormal;
    [self commitTouchResult:THKeyboardTouchResultText object:content];
  } else if (_state == THKeyboardTouchStateNormal) {
    if (_startIndex == 19 || _startIndex == 24) {
      _actionCell.state = THKeyboardCellStateNormal;
      if (index == 19 || index == 24) {
        [self commitTouchResult:THKeyboardTouchResultAction object:nil];
      }
    } else {
      if (_startIndex != _keyboardType * 5) {
        _cells[_startIndex].state = THKeyboardCellStateNormal;
      }
      if (index == _startIndex) {
        THKeyboardTouchResult result = THKeyboardTouchResultUnknown;
        id object = nil;
        switch (index) {
          case leftCellIndex:
            result = THKeyboardTouchResultLeft;
            break;
          case rightCellIndex:
            result = THKeyboardTouchResultRight;
            break;
          case hiraganaCellIndex:
          case katakanaCellIndex:
            result = THKeyboardTouchResultSelf;
            object = _cells[index].text;
            break;
          case numberCellIndex:
          case englishCellIndex:
            break;
          // default means back cell, space cell, or any other char cell.
          default:
            result = THKeyboardTouchResultText;
            object = _cells[index].text;
            break;
        }
        [self commitTouchResult:result object:object];
      }
    }
  }

  _state = THKeyboardTouchStateNoTouch;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  // for any reason, we set it back to |NoTouch| so a new touch can begin.
  NSLog(@"touches cancelled!");
  _state = THKeyboardTouchStateNoTouch;
  [self touchedCharCellReleased];
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
  return _cells[leftCellIndex];
}

- (THKeyboardCell *)rightCell {
  return _cells[rightCellIndex];
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

static BOOL is_char_cell(NSUInteger core_index) {
  return core_index != leftCellCoreIndex && core_index != rightCellCoreIndex &&
         core_index != NSNotFound;
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
}

static BOOL belongs_to_cross(THKeyboardCell *cell) {
  return cell.state == THKeyboardCellStatePopped || cell.state == THKeyboardCellStateFocused;
}

static THKeyboardCellConfig *char_cell_config(THKeyboardType type) {
  if (type == THKeyboardTypeHiragana) {
    return [THKeyboardCellConfig hiraganaCharCellConfig];
  } else if (type == THKeyboardTypeKatakana) {
    return [THKeyboardCellConfig katakanaCharCellConfig];
  } else {
    return [THKeyboardCellConfig defaultInstance];
  }
}

static THKeyboardCharTransformer *transformer(THKeyboardType type) {
  switch (type) {
    case THKeyboardTypeHiragana:
      return [THKeyboardCharTransformer hiraganaTransformer];
    case THKeyboardTypeKatakana:
      return [THKeyboardCharTransformer katakanaTransformer];
    default:
      return nil;
  }
}

static THKeyboardType keyboard_type(NSString *cell_name) {
  if ([cell_name isEqualToString:@"１２３"]) {
    return THKeyboardTypeNumber;
  } else if ([cell_name isEqualToString:@"ＡＢＣ"]) {
    return THKeyboardTypeEnglish;
  } else if ([cell_name isEqualToString:special_names[hiraganaCellSpecialIndex]]) {
    return THKeyboardTypeHiragana;
  } else if ([cell_name isEqualToString:special_names[katakanaCellSpecialIndex]]) {
    return THKeyboardTypeKatakana;
  } else {
    return THKeyboardTypeUnknown;
  }
}

@end
