#import "THKeyboardCharTransformer.h"
#import "THKeyboardJaConstants.h"

@implementation THKeyboardCharTransformer {
  NSArray *_sources; // of NSString
}

- (NSString *)nextFormOfContent:(NSString *)content {
  NSUInteger cur = 0, index = NSNotFound;
  for (; cur < _sources.count && index == NSNotFound; ++cur) {
    index = [[_sources objectAtIndex:cur] rangeOfString:content].location;
  }
  // not in the charset of this language, return the original
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

  NSLog(@"ERROR: transformer doesn't work...will return the original.");
  return content;
}

+ (instancetype)THKeyboardHiraganaTransformer {
  static dispatch_once_t onceToken;
  static THKeyboardCharTransformer *instance;
  dispatch_once(&onceToken, ^{
    instance = [[self class] init];
    instance->_sources =
        @[ hiragana_original, hiragana_small, hiragana_dakuten, hiragana_handakuten ];
  });
  return instance;
}

+ (instancetype)THKeyboardKatakanaTransformer {
  static dispatch_once_t onceToken;
  static THKeyboardCharTransformer *instance;
  dispatch_once(&onceToken, ^{
    instance = [[self class] init];
    instance->_sources =
        @[ katakana_original, katakana_small, katakana_dakuten, katakana_handakuten ];
  });
  return instance;
}

@end
