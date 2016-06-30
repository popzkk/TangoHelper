#import <UIKit/UIKit.h>
#import "THKeyboardCellConfig.h"

@class THKeyboardCellConfig;

@interface THKeyboardCell : UILabel

@property(nonatomic, copy) NSString *arrow;

// if nil, [THKeyboardCellConfig defaultInstance] will be used.
@property(nonatomic) THKeyboardCellConfig *config;

- (THKeyboardCellState)state;

- (void)setState:(THKeyboardCellState)state;

@end
