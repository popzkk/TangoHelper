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
    _keyboard.keyboardType = kTHKeyboardHiragana;
    _keyboard.actionText = @"確認";
    [self addSubview:_keyboard];
  }
  return self;
}

- (void)layoutSubviews {
  CGFloat padding = 20;
  CGRect frame = self.bounds;
  CGFloat width = (frame.size.width - 3 * padding) / 2;
  _depot.frame = CGRectMake(padding, 320 + padding, width, [_depot sizeThatFits:CGSizeMake(width, 0)].height);
  _lists.frame = CGRectMake(padding + _depot.frame.size.width + padding / 2, 320 + padding, width, [_lists sizeThatFits:CGSizeMake(width, 0)].height);
  _keyboard.frame = CGRectMake(padding, frame.size.height - frame.size.width + padding, frame.size.width - 2 * padding, frame.size.width - 2 * padding);
}

@end
