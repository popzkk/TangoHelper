#import "THWordPreview.h"

@implementation THWordPreview {
  UILabel *_wordLabel;
  UILabel *_tickLabel;
}

#pragma mark - public

- (instancetype)initWithFrame:(CGRect)frame key:(NSString *)key object:(NSString *)object {
  _wordLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  _wordLabel.text = [NSString stringWithFormat:@" %@ %@", key, object];
  _wordLabel.font = [UIFont fontWithName:_wordLabel.font.fontName size:20];
  //_wordLabel.layer.borderWidth = 0.5;
  //_wordLabel.layer.borderColor = [UIColor grayColor].CGColor;
  //_wordLabel.textAlignment = NSTextAlignmentCenter;
  _tickLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  _tickLabel.text = @"☐";
  self = [super initWithFrame:frame portions:@[ _wordLabel, _tickLabel ]];
  self.delegate = self;
  return self;
}

#pragma mark - THMultiPortionsViewDelegate

- (void)portion:(UIView *)portion isTappedInView:(UIView *)view {
  if (portion == _wordLabel) {
    NSLog(@"wordLabel is tapped");
  } else if (portion == _tickLabel) {
    NSLog(@"tickLabel is tapped");
    _tickLabel.text = @"✓";
  } else {
    NSLog(@"something else is tapped");
  }
}

#pragma mark - UIView

// This assumes that self.bounds is always not tall...
- (void)layoutSubviews {
  CGRect frame = self.bounds;
  _wordLabel.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width - frame.size.height, frame.size.height);
  _tickLabel.frame = CGRectMake(frame.origin.x + _wordLabel.frame.size.width, frame.origin.y, frame.size.height, frame.size.height);
}

// This assumes that width == 0 ...
- (CGSize)sizeThatFits:(CGSize)size {
  CGSize size1 = [_wordLabel sizeThatFits:size];
  CGSize size2 = [_wordLabel sizeThatFits:size];
  return CGSizeMake(size1.width + size2.width, MAX(size1.height, size2.height));
}

@end
