#import <UIKit/UIKit.h>

@protocol THMultiPortionsViewDelegate <NSObject>

- (void)portion:(UIView *)portion isTappedInView:(UIView *)view;

@end

@interface THMultiPortionsView : UIView

@property(nonatomic, weak) id<THMultiPortionsViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame portions:(NSArray *)portions;

@end
