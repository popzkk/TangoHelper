#import "THWordsManager.h"

#import "THFileRW.h"
#import "THWord.h"

@implementation THWordsManager {
  NSMutableDictionary<THWordKey *, THWordObject *> *_globalTransformedContent;
  NSMutableDictionary<THWordKey *, NSNumber *> *_globalReferenceCount;
}

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static THWordsManager *instance = nil;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
    instance->_globalTransformedContent = [NSMutableDictionary dictionary];
    instance->_globalReferenceCount = [NSMutableDictionary dictionary];
  });
  return instance;
}

- (THWordObject *)objectForKey:(THWordKey *)key {
  return [_globalTransformedContent objectForKey:key];
}

- (void)didInitializeFileRW:(THFileRW *)fileRW {
  NSArray<THWordKey *> *keys = fileRW.allKeys;
  for (THWordKey *key in keys) {
    [self someFileRWDidAddObject:[fileRW objectForKey:key] forKey:key];
  }
}

- (void)willRemoveFileRW:(THFileRW *)fileRW {
  NSArray<THWordKey *> *keys = fileRW.allKeys;
  for (THWordKey *key in keys) {
    [self someFileRWDidRemoveKey:key];
  }
}

- (void)someFileRWDidAddObject:(THWordObject *)object forKey:(THWordKey *)key {
#if (DEBUG)
  THWordObject *oldObj = [_globalTransformedContent objectForKey:key];
  if (oldObj && oldObj != object) {
    NSLog(@"Internal error: adding a globally existing object");
    return;
  }
#endif
  NSUInteger refCount = [_globalReferenceCount objectForKey:key].unsignedIntegerValue + 1;
  if (refCount > 1) {
    [_globalReferenceCount setObject:@(refCount) forKey:key];
  } else {
    [_globalTransformedContent setObject:object forKey:key];
    [_globalReferenceCount setObject:@(1) forKey:key];
  }
}

- (void)someFileRWDidRemoveKey:(THWordKey *)key {
  NSUInteger refCount = [_globalReferenceCount objectForKey:key].unsignedIntegerValue - 1;
  if (refCount) {
    [_globalReferenceCount setObject:@(refCount) forKey:key];
  } else {
    [_globalReferenceCount removeObjectForKey:key];
    [_globalTransformedContent removeObjectForKey:key];
  }
}

@end
