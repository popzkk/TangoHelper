#import "THWordsManager.h"

#import "THFileRW.h"
#import "THWord.h"

@interface THWordObject ()

- (void)willPlay;

- (void)didPass;

@end

@implementation THWordsManager {
  NSMutableDictionary<THWordKey *, NSMutableSet<THFileRW *> *> *_globalOwners;
}

#pragma mark - public

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static THWordsManager *instance = nil;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
    instance->_globalOwners = [NSMutableDictionary dictionary];
  });
  return instance;
}

- (THWordObject *)objectForKey:(THWordKey *)key {
  return [[[_globalOwners objectForKey:key] anyObject] objectForKey:key];
}

- (void)didInitializeFileRW:(THFileRW *)fileRW {
  NSArray<THWordKey *> *keys = fileRW.allKeys;
  for (THWordKey *key in keys) {
    [self fileRW:fileRW didAddObject:[fileRW objectForKey:key] forKey:key];
  }
}

- (void)willRemoveFileRW:(THFileRW *)fileRW {
  NSArray<THWordKey *> *keys = fileRW.allKeys;
  for (THWordKey *key in keys) {
    [self fileRW:fileRW willRemoveKey:key];
  }
}

- (void)fileRW:(THFileRW *)fileRW didAddObject:(THWordObject *)object forKey:(THWordKey *)key {
#if (DEBUG)
  THWordObject *oldObj = [self objectForKey:key];
  if (oldObj && oldObj != object) {
    NSLog(@"Internal error: adding a globally existing object");
    return;
  }
#endif
  NSMutableSet<THFileRW *> *owners = [_globalOwners objectForKey:key];
  if (owners) {
    [owners addObject:fileRW];
  } else {
    [_globalOwners setObject:[NSMutableSet setWithObject:fileRW] forKey:key];
  }
}

- (void)fileRW:(THFileRW *)fileRW willRemoveKey:(THWordKey *)key {
  [[_globalOwners objectForKey:key] removeObject:fileRW];
}

- (void)willPlayKey:(THWordKey *)key {
  [[self objectForKey:key] willPlay];
  [self markOwnersDirtyForKey:key];
}

- (void)didPassKey:(THWordKey *)key {
  [[self objectForKey:key] didPass];
  [self markOwnersDirtyForKey:key];
}

#pragma mark - private

- (void)markOwnersDirtyForKey:(THWordKey *)key {
  NSSet *owners = [_globalOwners objectForKey:key];
  for (THFileRW *fileRW in owners) {
    [fileRW markDirty];
  }
}

@end
