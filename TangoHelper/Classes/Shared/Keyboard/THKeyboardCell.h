#import <UIKit/UIKit.h>
#import "THKeyboardCellConfig.h"

@class THKeyboardCellConfig;

@interface THKeyboardCell : UILabel

@property(nonatomic, copy) NSString *arrow;

@property(nonatomic) THKeyboardCellState state;

// if nil, no config will be made.
@property(nonatomic) THKeyboardCellConfig *config;

@end
