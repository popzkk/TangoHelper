#import "THMultiPortionsView.h"

@interface THWordPreview : THMultiPortionsView

@property(nonatomic) BOOL canToggle;

@property(nonatomic) BOOL selected;

- (instancetype)initWithFrame:(CGRect)frame key:(NSString *)key object:(NSString *)object;

- (instancetype)initWithFrame:(CGRect)frame portions:(NSArray *)portions NS_UNAVAILABLE;

- (void)toggle;

@end
