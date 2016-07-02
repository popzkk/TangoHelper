#import <Foundation/Foundation.h>

@interface THKeyboardCharTransformer : NSObject

// for convenience, pass in NSString here - only the first char will be used.
- (NSString *)nextFormOfContent:(NSString *)content;

+ (instancetype)hiraganaTransformer;

+ (instancetype)katakanaTransformer;

// add other transformers...

@end
