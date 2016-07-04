#import <UIKit/UIKit.h>

@protocol THMultiPortionsViewDelegate <NSObject>

- (void)portion:(UIView *)portion isTappedInView:(UIView *)view;

@end

@interface THMultiPortionsView : UIView

@property(nonatomic, weak) id<THMultiPortionsViewDelegate> delegate;

@property(nonatomic) NSArray *portions; // of UIView

- (instancetype)initWithFrame:(CGRect)frame portions:(NSArray *)portions;

@end
