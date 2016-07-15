#import "THItemView.h"

static NSString *kUnselected = @"☐";
static NSString *kSelected = @"✓";

@implementation THItemView {
  UIView *_view;
  UILabel *_tickLabel;
}

#pragma mark - public

- (instancetype)initWithFrame:(CGRect)frame view:(UIView *)view {
  _view = view;
  _view.tag = 1;
  _tickLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  _tickLabel.text = kUnselected;
  _tickLabel.tag = 2;
  self = [super initWithFrame:frame portions:@[ _view, _tickLabel ]];
  self.canToggle = YES;
  self.selected = NO;
  return self;
}

- (void)setSelected:(BOOL)selected {
  if (!self.canToggle) {
    return;
  }
  if (_selected != selected) {
    _selected = selected;
    if (_selected) {
      _tickLabel.text = kSelected;
    } else {
      _tickLabel.text = kUnselected;
    }
  }
}

- (void)toggle {
  if (!self.canToggle) {
    return;
  }
  self.selected = !self.selected;
}

- (void)setShowTick:(BOOL)showTick {
  _showTick = showTick;
  _tickLabel.hidden = _showTick;
}

#pragma mark - UIView

// This assumes that self.bounds is always not tall...
- (void)layoutSubviews {
  CGRect frame = self.bounds;
  _view.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width - frame.size.height, frame.size.height);
  _tickLabel.frame = CGRectMake(frame.origin.x + _view.frame.size.width, frame.origin.y, frame.size.height, frame.size.height);
}

@end
