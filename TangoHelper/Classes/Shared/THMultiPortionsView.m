#import "THMultiPortionsView.h"

@implementation THMultiPortionsView {
  CGPoint _startPoint;
}

#pragma mark - public

- (instancetype)initWithFrame:(CGRect)frame portions:(NSArray *)portions {
  self = [super initWithFrame:frame];
  if (self) {
    self.portions = portions;
    for (UIView *view in portions) {
      [self addSubview:view];
    }
  }
  return self;
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
  for (UIView *view in self.portions) {
    if (CGRectContainsPoint(view.frame, point1) && CGRectContainsPoint(view.frame, point2)) {
      return view;
    }
  }
  return nil;
}

@end
