#import "THFileRW.h"

@interface THFileCenter : NSObject

+ (THFileRW *)associatedFileRWForPath:(NSString *)path;

+ (void)setFileRW:(THFileRW *)fileRW forPath:(NSString *)path;

+ (void)removeFileRWForPath:(NSString*)path;

+ (void)flushAll;

@end

#pragma mark - THFileRW

@interface THFileRW ()

@property(nonatomic) NSUInteger diff;

@end

static NSUInteger thres = 10;

@implementation THFileRW {
  NSString *_path;
  NSMutableDictionary *_content;
}

#pragma mark - public

+ (instancetype)instanceForPath:(NSString *)path {
  id instance = [THFileCenter associatedFileRWForPath:path];
  if (!instance) {
    instance = [[self alloc] initWithPath:path];
    [THFileCenter setFileRW:instance forPath:path];
  }
  return instance;
}

+ (void)flushAll {
  [THFileCenter flushAll];
}

- (NSString *)objectForKey:(NSString *)key {
  return [_content objectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
  [_content removeObjectForKey:key];
  ++self.diff;
}

- (void)setObject:(NSString *)object forKey:(NSString *)key {
  [_content setObject:object forKey:key];
  ++self.diff;
}

- (void)flush {
  [self flushWithThres:0];
}

- (void)close {
  [self flush];
  [THFileCenter removeFileRWForPath:_path];
}

#pragma mark - private

- (void)setDiff:(NSUInteger)diff {
  _diff = diff;
  [self flushWithThres:thres];
}

// only called internally
- (instancetype)initWithPath:(NSString *)path {
  self = [super init];
  if (self) {
    _content = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (!_content) {
      return nil;
    }
    _path = path;
    _diff = 0;
  }
  return self;
}

- (void)flushWithThres:(NSUInteger)thres {
  if (_diff > thres) {
    if ([_content writeToFile:_path atomically:NO]) {
      _diff = 0;
    }
  }
}

@end

#pragma mark - THFileCenter

@implementation THFileCenter {
  NSMutableDictionary *_openedFiles;
}

#pragma mark - public

+ (THFileRW *)associatedFileRWForPath:(NSString *)path {
  return [[self sharedInstance] associatedFileRWForPath:path];
}

+ (void)setFileRW:(THFileRW *)fileRW forPath:(NSString *)path {
  [[self sharedInstance] setFileRW:fileRW forPath:path];
}

+ (void)removeFileRWForPath:(NSString *)path {
  [[self sharedInstance] removeFileRWForPath:path];
}

+ (void)flushAll {
  [[self sharedInstance] flushAll];
}

#pragma mark - private

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static THFileCenter *instance = nil;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _openedFiles = [NSMutableDictionary dictionary];
  }
  return self;
}

- (THFileRW *)associatedFileRWForPath:(NSString *)path {
  return [_openedFiles objectForKey:path];
}

- (void)setFileRW:(THFileRW *)fileRW forPath:(NSString *)path {
  [_openedFiles setObject:fileRW forKey:path];
}

- (void)removeFileRWForPath:(NSString *)path {
  [_openedFiles removeObjectForKey:path];
}

- (void)flushAll {
  for (THFileRW *fileRW in _openedFiles.allValues) {
    [fileRW close];
  }
}

@end
