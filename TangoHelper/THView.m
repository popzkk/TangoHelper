#import "THView.h"

#import "Classes/Shared/Keyboard/THKeyboard.h"

@implementation THView {
  UIButton *_depot;
  UIButton *_lists;
  THKeyboard *_keyboard;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _depot = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_depot setTitle:@"Depot" forState:UIControlStateNormal];
    _depot.titleLabel.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
    _lists = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_lists setTitle:@"Lists" forState:UIControlStateNormal];
    _lists.titleLabel.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
    [self addSubview:_depot];
    [self addSubview:_lists];
    _keyboard = [THKeyboard sharedInstance];
    _keyboard.keyboardType = kTHKeyboardKatakana;
    [self addSubview:_keyboard];
  }
  return self;
}

- (void)layoutSubviews {
  CGFloat padding = 20;
  CGRect frame = self.bounds;
  CGFloat width = (frame.size.width - 3 * padding) / 2;
  _keyboard.frame = CGRectMake(padding, frame.size.height - frame.size.width + padding, frame.size.width - 2 * padding, frame.size.width - 2 * padding);
  _depot.frame = CGRectMake(padding, _keyboard.frame.origin.y, width, [_depot sizeThatFits:CGSizeMake(width, 0)].height);
  _lists.frame = CGRectMake(padding + _depot.frame.size.width + padding / 2, _depot.frame.origin.y, width, [_lists sizeThatFits:CGSizeMake(width, 0)].height);
}

@end
