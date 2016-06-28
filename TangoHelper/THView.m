#import "THView.h"

@implementation THView {
  UIButton *_depot;
  UIButton *_lists;
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
  }
  return self;
}

- (void)layoutSubviews {
  CGFloat kPadding = 10;
  CGRect frame = self.bounds;
  CGFloat kWidth = (frame.size.width - 3 * kPadding) / 2;
  _depot.frame = CGRectMake(kPadding, 200 + kPadding, kWidth, [_depot sizeThatFits:CGSizeMake(kWidth, 0)].height);
  _lists.frame = CGRectMake(kPadding + _depot.frame.size.width + kPadding / 2, 200 + kPadding, kWidth, [_lists sizeThatFits:CGSizeMake(kWidth, 0)].height);
}

@end
