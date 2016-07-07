#import "THMultiPortionsView.h"

@interface THItemView : THMultiPortionsView

@property(nonatomic) BOOL canToggle;

@property(nonatomic) BOOL selected;

// view.tag must be set after passed in.
- (instancetype)initWithFrame:(CGRect)frame view:(UIView *)view;

- (instancetype)initWithFrame:(CGRect)frame portions:(NSArray *)portions NS_UNAVAILABLE;

- (void)toggle;

@end
