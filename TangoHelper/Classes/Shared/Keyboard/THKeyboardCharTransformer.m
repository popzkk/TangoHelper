#import "THKeyboardCharTransformer.h"

#import "THKeyboardJaConstants.h"

@implementation THKeyboardCharTransformer {
  NSArray *_sources;  // of NSString
}

- (NSString *)nextFormOfContent:(NSString *)content {
  if (!content) {
    return nil;
  }
  NSUInteger cur = 0, index = [_sources.firstObject rangeOfString:content].location;
  while (index == NSNotFound) {
    if (++cur >= _sources.count) {
      break;
    }
    index = [[_sources objectAtIndex:cur] rangeOfString:content].location;
  }
  // not in the charset of this language, return the original.
  if (index == NSNotFound) {
    return content;
  }

  NSUInteger tmp = cur;
  do {
    cur = (cur + 1) % _sources.count;
    NSString *nextForm = [[_sources objectAtIndex:cur] substringWithRange:NSMakeRange(index, 1)];
    if (![nextForm isEqualToString:content]) {
      return nextForm;
    }
  } while (cur != tmp);

  // this char doesn't have any variants, return the original.
  return content;
}

+ (instancetype)hiraganaTransformer {
  static dispatch_once_t onceToken;
  static THKeyboardCharTransformer *instance;
  dispatch_once(&onceToken, ^{
    instance = [[[self class] alloc] init];
    instance->_sources =
        @[ hiragana_original, hiragana_small, hiragana_dakuten, hiragana_handakuten ];
  });
  return instance;
}

+ (instancetype)katakanaTransformer {
  static dispatch_once_t onceToken;
  static THKeyboardCharTransformer *instance;
  dispatch_once(&onceToken, ^{
    instance = [[[self class] alloc] init];
    instance->_sources =
        @[ katakana_original, katakana_small, katakana_dakuten, katakana_handakuten ];
  });
  return instance;
}

@end
