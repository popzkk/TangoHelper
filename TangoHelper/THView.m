#import "THView.h"

#import "Classes/Shared/Keyboard/THKeyboard.h"

@implementation THView {
  THKeyboard *_keyboard;
  UIScrollView *_scrollView;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _keyboard = [THKeyboard sharedInstanceWithKeyboardType:kTHKeyboardKatakana];
    [self addSubview:_keyboard];
    //[self addSubview:_preview];
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scrollView.scrollEnabled = YES;
    [self addSubview:_scrollView];
  }
  return self;
}

- (void)layoutSubviews {
  CGFloat padding = 20;
  CGRect frame = self.bounds;
  CGFloat width = frame.size.width - 2 * padding;
  _keyboard.frame = CGRectMake(padding, frame.size.height - frame.size.width + padding, frame.size.width - 2 * padding, frame.size.width - 2 * padding);
  //_preview.frame = CGRectMake(padding, _keyboard.frame.origin.y, width, [_preview sizeThatFits:CGSizeMake(width, 0)].height);
  _scrollView.frame = CGRectMake(padding, 100, width, frame.size.height - padding - _keyboard.frame.size.height - 50);
  CGFloat h = 0;
  for (UIView *view in _scrollView.subviews) {
    view.frame = CGRectMake(0, h, width, 20);
    h += 20;
  }
  _scrollView.contentSize = CGSizeMake(width, h);
}

@end
