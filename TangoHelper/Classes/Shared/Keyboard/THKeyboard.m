#import "THKeyboard.h"

#import "THKeyboardCell.h"
#import "THKeyboardCellConfig.h"
#import "THKeyboardCharTransformer.h"
#import "THKeyboardConfig.h"

/** TODO
 * merge hiragana and katakana buttons and add a button to switch to system keyboards.
 */

typedef NS_ENUM(NSUInteger, THKeyboardTouchState) {
  kTHKeyboardTouchStateNoTouch = 0,  // no touch
  kTHKeyboardTouchStateNormal,       // already touched, but not a char cell
  kTHKeyboardTouchStateMoving,       // already touched, and is a char cell
};

typedef NS_ENUM(NSUInteger, THKeyboardTouchResult) {
  kTHKeyboardTouchResultText = 0,  // add or delete text
  kTHKeyboardTouchResultSelf,      // touched on a cell related to the keyboard itself
  kTHKeyboardTouchResultLeft,      // touched on the left cell
  kTHKeyboardTouchResultRight,     // touched on the right cell
  kTHKeyboardTouchResultAction,    // touched on the action cell
};

static CGFloat kPadding = 3;

static const NSUInteger numberCellIndex = 5;
static const NSUInteger englishCellIndex = 10;
static const NSUInteger hiraganaCellIndex = 15;
static const NSUInteger katakanaCellIndex = 20;
static const NSUInteger backCellIndex = 9;
static const NSUInteger spaceCellIndex = 14;
static NSString *special_names[] = {@"１２３", @"ＡＢＣ", @"あいう", @"アイウ", @"⌫", @"空白"};
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
  NSUInteger _startIndex;     // index of the cell when the touch begins.
  BOOL _crossIsShown;         // whether the cross is shown.
  CGPoint _startPoint;        // touch point at the beginning.
  NSUInteger _previousIndex;  // the previous index of the cell when the user is moving.
  NSUInteger _currentIndex;   // index of the cell when the user is moving.
}

#pragma mark - public

+ (instancetype)sharedInstanceWithKeyboardType:(THKeyboardType)type
                                    actionText:(NSString *)actionText
                                      delegate:(id<THKeyboardDelegate>)delegate {
  THKeyboard *sharedInstance = [self sharedInstance];
  [sharedInstance setKeyboardType:type];
  [sharedInstance setActionText:actionText];
  sharedInstance->_delegate = delegate;
  return sharedInstance;
}

+ (instancetype)sharedInstanceWithKeyboardType:(THKeyboardType)type
                                    actionText:(NSString *)actionText {
  return [self sharedInstanceWithKeyboardType:type actionText:actionText delegate:nil];
}

+ (instancetype)sharedInstanceWithKeyboardType:(THKeyboardType)type {
  return [self sharedInstanceWithKeyboardType:type actionText:nil delegate:nil];
}

- (void)setKeyboardType:(THKeyboardType)keyboardType {
  if (keyboardType == _keyboardType) {
    return;
  }

  _cells[keyboardType * 5].state = kTHKeyboardCellStateFocused;
  _cells[_keyboardType * 5].state = kTHKeyboardCellStateNormal;
  _keyboardType = keyboardType;

  THKeyboardConfig *keyboardConfig;
  THKeyboardCellConfig *charCellConfig, *leftCellConfig, *rightCellConfig;
  switch (keyboardType) {
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

- (void)setDelegate:(id<THKeyboardDelegate>)delegate {
  _delegate = delegate;
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
}

- (void)touchedCharCellWillMove {
  if (_crossIsShown) {
    return;
  }
  _crossIsShown = YES;

  for (NSUInteger i = 0; i < 25; ++i) {
    [_cells[i] save];
  }

  for (NSUInteger i = 0; i < 25; ++i) {
    //[_cells[i] onlySetState:kTHKeyboardCellStateFaded];
  }
  THKeyboardCell *cell = _cells[_startIndex];
  [cell onlySetState:kTHKeyboardCellStateFocused];

  THKeyboardCellConfig *config = char_cell_config(_keyboardType);
  for (NSUInteger i = 0; i < cell.arrow.length; ++i) {
    THKeyboardCell *arrow = _cells[neighbor(_startIndex, i)];
    [arrow onlySetState:kTHKeyboardCellStatePopped];
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
  switch (result) {
    // right cell has no function currently...
    case kTHKeyboardTouchResultRight:
      // NSLog(@"right cell tapped");
      break;
    case kTHKeyboardTouchResultAction:
      // NSLog(@"action cell tapped");
      [_delegate actionCellTapped];
      break;
    case kTHKeyboardTouchResultLeft:
      // NSLog(@"left cell tapped");
      [_delegate changeLastInputTo:[transformer(self.keyboardType)
                                       nextFormOfContent:[_delegate lastInput]]];
      break;
    case kTHKeyboardTouchResultSelf:
      // NSLog(@"will change keyboard to %@", object);
      self.keyboardType = keyboard_type(object);
      break;
    // kTHKeyboardTouchResultText
    default:
      // NSLog(@"will add text: %@", object);
      if ([object isEqualToString:@"⌫"]) {
        [_delegate backCellTapped];
      } else if ([object isEqualToString:@"空白"]) {
        [_delegate addContent:space_for_keyboard(self.keyboardType)];
      } else {
        [_delegate addContent:object];
      }
      break;
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
  _previousIndex = NSNotFound;
  // touch is on the padding area or the first row.
  if (_startIndex < 5 || _startIndex == NSNotFound) {
    return;
  }
  _state = kTHKeyboardTouchStateNormal;
  if (_startIndex != 19 && _startIndex != 24) {
    _cells[_startIndex].state = kTHKeyboardCellStateFocused;
  } else {
    _actionCell.state = kTHKeyboardCellStateFocused;
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

  if (_state != kTHKeyboardTouchStateMoving) {
    if (is_char_cell(index_to_core_index(_startIndex))) {
      _state = kTHKeyboardTouchStateMoving;
    }
  }

  if (_state == kTHKeyboardTouchStateMoving) {
    [self touchedCharCellWillMove];
    if (index != _startIndex) {
      CGVector vec = CGVectorMake(point.x - _startPoint.x, point.y - _startPoint.y);
      index = calc_neighbor(_startIndex, vec);
    }
    if (index < 25 && belongs_to_cross(_cells[index])) {
      _previousIndex = _currentIndex;
      _currentIndex = index;
      _cells[_previousIndex].state = kTHKeyboardCellStatePopped;
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
    // restore the keyboard to the normal UI first as the delegate may cost a lot of time.
    NSString *content = _cells[_currentIndex].text;
    [self touchedCharCellReleased];
    _cells[_startIndex].state = kTHKeyboardCellStateNormal;
    [self commitTouchResult:kTHKeyboardTouchResultText object:content];
  } else if (_state == kTHKeyboardTouchStateNormal) {
    if (_startIndex == 19 || _startIndex == 24) {
      _actionCell.state = kTHKeyboardCellStateNormal;
      if (index == 19 || index == 24) {
        [self commitTouchResult:kTHKeyboardTouchResultAction object:nil];
      }
    } else {
      if (_startIndex != self.keyboardType * 5) {
        _cells[_startIndex].state = kTHKeyboardCellStateNormal;
      }
      if (index == _startIndex) {
        THKeyboardTouchResult result = kTHKeyboardTouchResultText;
        id object = nil;
        switch (index) {
          case leftCellIndex:
            result = kTHKeyboardTouchResultLeft;
            break;
          case rightCellIndex:
            result = kTHKeyboardTouchResultRight;
            break;
          case hiraganaCellIndex:
          case katakanaCellIndex:
          case numberCellIndex:
          case englishCellIndex:
            result = kTHKeyboardTouchResultSelf;
            object = _cells[index].text;
            break;
          // default means back cell, space cell, or any other char cell.
          default:
            object = _cells[index].text;
            break;
        }
        [self commitTouchResult:result object:object];
      }
    }
  }

  _state = kTHKeyboardTouchStateNoTouch;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  // for any reason, we set it back to |NoTouch| so a new touch can begin.
  _state = kTHKeyboardTouchStateNoTouch;
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
  return cell.state == kTHKeyboardCellStatePopped || cell.state == kTHKeyboardCellStateFocused;
}

static THKeyboardCellConfig *char_cell_config(THKeyboardType type) {
  if (type == kTHKeyboardHiragana) {
    return [THKeyboardCellConfig hiraganaCharCellConfig];
  } else if (type == kTHKeyboardKatakana) {
    return [THKeyboardCellConfig katakanaCharCellConfig];
  } else {
    return [THKeyboardCellConfig defaultInstance];
  }
}

static THKeyboardCharTransformer *transformer(THKeyboardType type) {
  switch (type) {
    case kTHKeyboardHiragana:
      return [THKeyboardCharTransformer hiraganaTransformer];
    case kTHKeyboardKatakana:
      return [THKeyboardCharTransformer katakanaTransformer];
    default:
      return nil;
  }
}

static THKeyboardType keyboard_type(NSString *cell_name) {
  if ([cell_name isEqualToString:@"１２３"]) {
    return kTHKeyboardNumber;
  } else if ([cell_name isEqualToString:@"ＡＢＣ"]) {
    return kTHKeyboardEnglish;
  } else if ([cell_name isEqualToString:@"あいう"]) {
    return kTHKeyboardHiragana;
  } else if ([cell_name isEqualToString:@"アイウ"]) {
    return kTHKeyboardKatakana;
  } else {
    return kTHKeyboardUnknown;
  }
}

static NSString *space_for_keyboard(THKeyboardType type) {
  switch (type) {
    case kTHKeyboardHiragana:
    case kTHKeyboardKatakana:
      return @"　";
    default:
      return @" ";
  }
}

@end
