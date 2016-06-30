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
  // No need to do deep comparasion...
  if (_config != config) {
    _config = config;
    [self configSelf];
  }
}

#pragma mark - private

- (void)configSelfWithCellConfig:(THKeyboardCellConfig *)config
                       cellState:(THKeyboardCellState)state {
  if (config) {
    self.font = [config fontForState:state];
    self.textColor = [config textColorForState:state];
    self.backgroundColor = [config backgroundColorForState:state];
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
  } else {
    NSLog(@"WARNING: empty cell config!");
  }
}

- (void)configSelf {
  [self configSelfWithCellConfig:self.config cellState:_state];
}

@end
