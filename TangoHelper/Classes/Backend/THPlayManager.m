#import "THPlayManager.h"

#import "../Shared/THHelpers.h"
#import "../Shared/THStrings.h"
#import "THPlaylist.h"

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

#pragma mark - THPlayManager

@implementation THPlayManager {
  NSMutableDictionary *_available;
  // current key
  NSString *_current;
  NSMutableSet *_errors;
  __weak id<THPlayManagerDelegate> _delegate;
}

#pragma mark - public

- (instancetype)initWithPlaylist:(THPlaylist *)playlist
                          config:(THPlayConfig *)config
                        delegate:(id<THPlayManagerDelegate>)delegate {
  self = [super init];
  if (self) {
    _playlist = playlist;
    _config = [config copy];
    _delegate = delegate;
    _available = [NSMutableDictionary dictionaryWithCapacity:_playlist.count];
    for (NSString *key in _playlist.allKeys) {
      [_available setObject:@(_config.repeat) forKey:key];
    }
    _errors = [NSMutableSet set];
    _isPlaying = NO;
  }
  return self;
}

- (void)start {
  if (_isPlaying) {
    NSLog(@"WARNING: calling start when already started.");
    return;
  }
  _isPlaying = YES;
  [self next];
}

- (void)commitInput:(NSString *)input {
  THBasicAlertAction nextStep = ^() {
    if (_available.count) {
      [self next];
    } else {
      [self finish];
    }
  };

  if (![_current isEqualToString:input]) {
    [_errors addObject:_current];
    if (!_config.lazyAssert) {
      [_delegate showAlert:super_basic_alert(play_wrong_answer_dialog_title(_current),
                                             play_wrong_answer_dialog_message(input), nextStep)];
    } else {
      nextStep();
    }
  } else {
    NSNumber *remaining = [_available objectForKey:_current];
    if (remaining.integerValue == 1) {
      [_available removeObjectForKey:_current];
    } else {
      [_available setObject:@(remaining.integerValue - 1) forKey:_current];
    }
    nextStep();
  }
}

#pragma mark - private

- (void)next {
  if (_available.count == 0) {
    NSLog(@"Internal error: calling next when all words are done.");
    return;
  }
  _current = [_available.allKeys objectAtIndex:arc4random_uniform((int)_available.allKeys.count)];
  [_delegate showWithText:[_playlist objectForKey:_current]];
}

- (void)finish {
  if (!_isPlaying) {
    NSLog(@"WARNING: calling finish when already finished.");
    return;
  }
  THPlayResult *result = [[THPlayResult alloc] init];
  result.errors = _errors;
  _isPlaying = NO;
  [_delegate playFinishedWithResult:result];
}

@end
