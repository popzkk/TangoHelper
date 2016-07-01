#import <Foundation/Foundation.h>

@interface THKeyboardCharTransformer : NSObject

// for convenience, pass in NSString here - only the first char will be used.
- (NSString *)nextFormOfContent:(NSString *)content;

+ (instancetype)THKeyboardHiraganaTransformer;

+ (instancetype)THKeyboardKatakanaTransformer;

// add other transformers...

@end
