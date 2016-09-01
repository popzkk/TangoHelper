#import "THPlayViewModel.h"

#import "../Backend/THFileRW.h"
#import "../Backend/THWord.h"
#import "../Shared/THHelpers.h"

#pragma mark - THPlayConfig

@implementation THPlayConfig

- (instancetype)init {
  self = [super init];
  if (self) {
    _repeat = 1;
    _lazyAssert = NO;
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
  THPlayConfig *config = [[THPlayConfig alloc] init];
  config.repeat = _repeat;
  config.lazyAssert = _lazyAssert;
  return config;
}

@end

#pragma mark - THPlayResult

@implementation THPlayResult

@end

#pragma mark - THPlayViewModel

@implementation THPlayViewModel {
  THWordsCollection *_collection;
  THPlayConfig *_config;

  NSMutableArray<THWordKey *> *_availableKeys;
  NSMutableDictionary<THWordKey *, NSNumber *> *_availableCounts;
  THWordKey *_key;
  THWordObject *_object;
  NSMutableSet<THWordKey *> *_wrongWordKeys;

  __weak id<THPlayViewModelDelegate> _delegate;
}

#pragma mark - public

- (instancetype)initWithCollection:(THWordsCollection *)collection
                            config:(THPlayConfig *)config
                          delegate:(id<THPlayViewModelDelegate>)delegate {
#if (DEBUG)
  if (!collection.count) {
    NSLog(@"WARNING: cannot initialise THPlayModel with an empty collection");
  }
#endif
  self = [super init];
  if (self) {
    _collection = collection;
    _config = [config copy];
    _delegate = delegate;
    _availableKeys = [NSMutableArray arrayWithArray:_collection.allKeys];
    _availableCounts = [NSMutableDictionary dictionaryWithCapacity:_collection.count];
    for (THWordKey *key in _availableKeys) {
      [_availableCounts setObject:@(_config.repeat) forKey:key];
    }
    _wrongWordKeys = [NSMutableSet set];
  }
  return self;
}

- (void)start {
  [self next];
}

- (void)confirmInput:(NSString *)input {
  if (![_key.input isEqualToString:input]) {
    [_delegate wrongAnswer:input forExplanation:_object.explanation wordKey:_key];
  } else {
    [self rightAnswer];
    [self next];
  }
}

- (void)commitWrongAnswerWithOption:(THPlayOption)option texts:(NSArray<NSString *> *)texts {
  if (option == THPlayOptionRemove) {
    [_collection removeObjectForKey:_key];
    [_availableKeys removeObject:_key];
    [_availableCounts removeObjectForKey:_key];
  } else {
    if (option == THPlayOptionWrongWrong || option == THPlayOptionWrongRight) {
      // _collection and all files are already updated (that means _object is updated).
      THWordKey *key = [[THWordKey alloc] initWithInput:texts[0] extra:texts[1]];
      // no action needed if keys are the same.
      if (![_key isEqual:key]) {
        [_availableCounts removeObjectForKey:_key];
        [_availableKeys removeObject:_key];
        // if the new key is still waiting to be recited, just remove the old key
        // if the new key is not recitable, add it to the list as it is never recited
        if (![_availableCounts objectForKey:key]) {
          [_availableCounts setObject:@(_config.repeat) forKey:key];
          [_availableKeys addObject:key];
        }
        _key = key;
      }
    }
    if (option == THPlayOptionNext || option == THPlayOptionWrongWrong) {
      [_wrongWordKeys addObject:_key];
    } else {
      [self rightAnswer];
    }
  }
  [self next];
}

- (void)finish {
  THPlayResult *result = [[THPlayResult alloc] init];
  result.wrongWordKeys = _wrongWordKeys;
  [_delegate playFinishedWithResult:result];
}

#pragma mark - private

- (void)rightAnswer {
  NSUInteger remaining = [_availableCounts objectForKey:_key].unsignedIntegerValue - 1;
  if (!remaining) {
    [_availableKeys removeObject:_key];
    [_availableCounts removeObjectForKey:_key];
  } else {
    [_availableCounts setObject:@(remaining) forKey:_key];
  }
}

- (void)next {
  if (!_availableKeys.count) {
    [self finish];
    return;
  }
  _key = [_availableKeys objectAtIndex:arc4random_uniform((int)_availableKeys.count)];
  _object = [_collection objectForKey:_key];
  [_delegate nextWordWithExplanation:_object.explanation];
}

@end
