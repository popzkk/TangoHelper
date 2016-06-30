#import "THKeyboardCellConfig.h"

@interface THKeyboardConfig : NSObject

- (NSArray *)texts; // of NSString

- (NSArray *)arrows; // of NSString

+ (instancetype)hiraganaConfig;

+ (instancetype)katakanaConfig;

@end
