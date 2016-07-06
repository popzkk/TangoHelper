#import "THMultiPortionsView.h"

@implementation THMultiPortionsView {
  CGPoint _startPoint;
}

#pragma mark - public

- (instancetype)initWithFrame:(CGRect)frame portions:(NSArray *)portions {
  self = [super initWithFrame:frame];
  if (self) {
    for (UIView *view in portions) {
      [self addSubview:view];
    }
  }
  return self;
}

#pragma mark - UIView

// This assumes that self.bounds is always not tall...
- (void)layoutSubviews {
  CGRect frame = self.bounds;
  CGFloat width = frame.size.width / self.subviews.count;
  CGFloat height = frame.size.height;
  for (NSUInteger i = 0; i < self.subviews.count; ++i) {
    [self.subviews objectAtIndex:i].frame = CGRectMake(frame.origin.x + i * width, frame.origin.y, width, height);
  }
}

// This assumes that width == 0 ...
- (CGSize)sizeThatFits:(CGSize)size {
  CGFloat width = 0;
  CGFloat height = 0;
  for (NSUInteger i = 0; i < self.subviews.count; ++i) {
    CGSize tmp = [[self.subviews objectAtIndex:i] sizeThatFits:size];
    width += tmp.width;
    height = MAX(height, tmp.height);
  }
  return CGSizeMake(width, height);
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  _startPoint = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  CGPoint endPoint = [[touches anyObject] locationInView:self];
  UIView *portion = [self targetPortionsWithPoint1:_startPoint point2:endPoint];
  if (portion) {
    [self.delegate portion:portion isTappedInView:self];
  }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
}

// available after iOS 9.1
- (void)touchesEstimatedPropertiesUpdated:(NSSet *)touches {
}

#pragma mark - helpers

- (UIView *)targetPortionsWithPoint1:(CGPoint)point1 point2:(CGPoint)point2 {
  for (UIView *view in self.subviews) {
    if (CGRectContainsPoint(view.frame, point1) && CGRectContainsPoint(view.frame, point2)) {
      return view;
    }
  }
  return nil;
}

@end
