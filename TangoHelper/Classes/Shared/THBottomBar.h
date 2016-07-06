#import <UIKit/UIKit.h>

@interface THBottomBar : UIView

- (instancetype)initWithFrame:(CGRect)frame
                    upperView:(UIView *)upperView
                   lowerViews:(NSArray *)lowerViews;

@end
