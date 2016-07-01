#import "THKeyboardConfig.h"
#import "THKeyboardJaConstants.h"

typedef void (^onceBlock)(NSMutableArray *, NSMutableArray *);

@implementation THKeyboardConfig {
  NSArray *_texts;
  NSArray *_arrows;
}

- (NSArray *)texts {
  return _texts;
}

- (NSArray *)arrows {
  return _arrows;
}

+ (instancetype)hiraganaConfig {
  static dispatch_once_t once;
  static THKeyboardConfig *instance = nil;
  dispatch_once(&once, ^{
    instance = [[[self class] alloc] init];
    NSMutableArray *texts = [NSMutableArray array];
    NSMutableArray *arrows = [NSMutableArray array];
    [self blockWithSource:hiragana_original](texts, arrows);
    instance->_texts = texts;
    instance->_arrows = arrows;
  });
  return instance;
}

+ (instancetype)katakanaConfig {
  static dispatch_once_t once;
  static THKeyboardConfig *instance = nil;
  dispatch_once(&once, ^{
    instance = [[[self class] alloc] init];
    NSMutableArray *texts = [NSMutableArray array];
    NSMutableArray *arrows = [NSMutableArray array];
    [self blockWithSource:katakana_original](texts, arrows);
    instance->_texts = texts;
    instance->_arrows = arrows;
  });
  return instance;
}

#pragma mark - private

+ (onceBlock)blockWithSource:(NSString *)source {
  return ^void(NSMutableArray *texts, NSMutableArray *arrows) {
    // text for each cell
    for (NSUInteger i = 0; i < 10; ++i) {
      [texts addObject:[source substringWithRange:NSMakeRange(i * 5, 1)]];
    }
    [texts insertObject:@"変換"/*@"　゛　゜\n小"*/ atIndex:texts.count - 1];
    [texts addObject:@"♪"];
    // arrow for each cell
    for (NSUInteger i = 0; i < 10; ++i) {
      [arrows addObject:[source substringWithRange:NSMakeRange(i * 5 + 1,
                                                               MIN(4, source.length - i * 5 - 1))]];
    }
    [arrows insertObject:@"" atIndex:arrows.count - 1];
    [arrows addObject:@""];
  };
};

@end