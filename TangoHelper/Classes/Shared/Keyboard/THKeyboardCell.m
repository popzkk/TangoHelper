#import "THKeyboardCell.h"

@implementation THKeyboardCell {
  THKeyboardCellState _state;
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

#pragma mark - private

- (void)configSelfWithCellConfig:(THKeyboardCellConfig *)config
                       cellState:(THKeyboardCellState)state {
  if (config) {
    UIFont *font = [config fontForState:state];
    if (font) {
      self.font = font;
    }
    UIColor *textColor = [config textColorForState:state];
    if (textColor) {
      self.textColor = textColor;
    }
    UIColor *backgroundColor = [config backgroundColorForState:state];
    if (backgroundColor) {
      self.backgroundColor = backgroundColor;
    }
  } else {
    NSLog(@"WARNING: cell config is nil!");
  }
}

- (void)configSelf {
  [self configSelfWithCellConfig:self.config cellState:_state];
}

@end
