#import "THBottomBar.h"
#import "THMultiPortionsView.h"

@implementation THBottomBar {
  UIView *_upperView;
  THMultiPortionsView *_lowerView;
}

- (instancetype)initWithFrame:(CGRect)frame
                    upperView:(UIView *)upperView
                   lowerViews:(NSArray *)lowerViews {
  self = [super initWithFrame:frame];
  if (self) {
    _upperView = upperView;
    _lowerView = [[THMultiPortionsView alloc] initWithFrame:CGRectZero portions:lowerViews];
  }
  return self;
}

@end
