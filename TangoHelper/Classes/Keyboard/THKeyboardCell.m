#import "THKeyboardCell.h"

@implementation THKeyboardCell {
  THKeyboardCellState _state;

  THKeyboardCellConfig *_savedConfig;
  NSString *_savedText;
  BOOL _savedHidden;
  THKeyboardCellState _savedState;

  BOOL _saved;
}

- (THKeyboardCellState)state {
  return _state;
}

- (void)setState:(THKeyboardCellState)state {
  if (_state != state) {
    _state = state;
    [self configSelf];
  }
}

- (void)setConfig:(THKeyboardCellConfig *)config {
  // no need to do deep comparasion...
  if (_config != config) {
    _config = config;
    [self configSelf];
  }
}

- (void)save {
  if (_saved) {
    NSLog(@"WARNING: save after saving!");
  }

  _savedState = _state;
  _savedConfig = _config;
  _savedText = self.text;
  _savedHidden = self.hidden;

  _saved = YES;
}

- (void)restore {
  if (!_saved) {
    NSLog(@"try to restore without saving before!");
    return;
  }

  _state = _savedState;
  _config = _savedConfig;
  [self configSelf];
  self.text = _savedText;
  self.hidden = _savedHidden;

  _saved = NO;
}

- (void)onlySetState:(THKeyboardCellState)state {
  _state = state;
}

- (void)onlySetConfig:(THKeyboardCellConfig *)config {
  _config = config;
}

- (void)configSelf {
  [self configSelfWithCellConfig:self.config cellState:_state];
}

#pragma mark - private

- (void)configSelfWithCellConfig:(THKeyboardCellConfig *)config
                       cellState:(THKeyboardCellState)state {
  if (config) {
    UIFont *font = [config fontForState:state];
    UIColor *textColor = [config textColorForState:state];
    UIColor *backgroundColor = [config backgroundColorForState:state];
    CGFloat borderWidth = [config borderWidthForState:state];
    UIColor *borderColor = [config borderColorForState:state];

    if (!font) {
      font = [config fontForState:kTHKeyboardCellStateNormal];
    }
    if (!textColor) {
      textColor = [config textColorForState:kTHKeyboardCellStateNormal];
    }
    if (!backgroundColor) {
      backgroundColor = [config backgroundColorForState:kTHKeyboardCellStateNormal];
    }
    if (borderWidth < 0) {
      borderWidth = [config borderWidthForState:kTHKeyboardCellStateNormal];
    }
    if (!borderColor) {
      borderColor = [config borderColorForState:kTHKeyboardCellStateNormal];
    }

    if (font) {
      self.font = font;
    }
    if (textColor) {
      self.textColor = textColor;
    }
    if (backgroundColor) {
      self.backgroundColor = backgroundColor;
    }
    if (borderWidth > 0) {
      self.layer.borderWidth = borderWidth;
    }
    if (borderColor) {
      self.layer.borderColor = borderColor.CGColor;
    }
  } else {
    // NSLog(@"WARNING: cell config is nil!");
  }
}

@end
