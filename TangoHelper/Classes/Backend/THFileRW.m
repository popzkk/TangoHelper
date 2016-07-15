#import "THFileRW.h"

@interface THFileCenter : NSObject

+ (THFileRW *)associatedFileRWForFilename:(NSString *)filename;

+ (void)setFileRW:(THFileRW *)fileRW forFilename:(NSString *)filename;

+ (void)removeFileRWForFilename:(NSString*)filename;

+ (void)flushAll;

@end

#pragma mark - THFileRW

@interface THFileRW ()

@property(nonatomic) NSUInteger diff;

@end

static NSUInteger thres = 20;

@implementation THFileRW {
  NSString *_filename;
  NSString *_path;
  NSMutableDictionary *_content;

  NSArray *_keys;
  NSArray *_objects;
}

#pragma mark - public

+ (instancetype)instanceForFilename:(NSString *)filename {
  return [self instanceForFilename:filename create:NO];
}

+ (instancetype)instanceForFilename:(NSString *)filename create:(BOOL)create {
  id instance = [THFileCenter associatedFileRWForFilename:filename];
  if (!instance) {
    instance = [[self alloc] initWithFilename:filename create:create];
    if (!instance) {
      NSLog(@"File %@ doesn't exist or cannot be created!", filename);
      return nil;
    }
    [THFileCenter setFileRW:instance forFilename:filename];
  }
  return instance;
}

+ (void)flushAll {
  [THFileCenter flushAll];
}

- (NSString *)filename {
  return _filename;
}

- (NSArray *)allKeys {
  if (!_keys) {
    _keys = _content.allKeys;
  }
  return _keys;
}

- (NSArray *)objectsForKeys:(NSArray *)keys {
  return [_content objectsForKeys:keys notFoundMarker:@""];
}

- (NSString *)objectForKey:(NSString *)key {
  return [_content objectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
  [_content removeObjectForKey:key];
  ++self.diff;
  // ...sync depot with playlists
}

- (void)setObject:(NSString *)object forKey:(NSString *)key {
  [_content setObject:object forKey:key];
  ++self.diff;
  // ...sync depot with playlists, though no need to sync adding.
}

- (void)flush {
  [self flushWithThres:0];
}

- (void)close {
  [self flush];
  [THFileCenter removeFileRWForFilename:_filename];
}

#pragma mark - private

- (void)setDiff:(NSUInteger)diff {
  _diff = diff;
  [self flushWithThres:thres];
}

// only called internally
- (instancetype)initWithFilename:(NSString *)filename create:(BOOL)create {
  self = [super init];
  if (self) {
    _path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                 .firstObject stringByAppendingPathComponent:filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (create && ![fileManager fileExistsAtPath:_path]) {
      [fileManager createFileAtPath:_path contents:nil attributes:nil];
    }
    _content = [NSMutableDictionary dictionaryWithContentsOfFile:_path];
    //if (!_content) {
      //return nil;
    //}
    _filename = filename;
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

+ (THFileRW *)associatedFileRWForFilename:(NSString *)filename {
  return [[self sharedInstance] associatedFileRWForFilename:filename];
}

+ (void)setFileRW:(THFileRW *)fileRW forFilename:(NSString *)filename {
  [[self sharedInstance] setFileRW:fileRW forFilename:filename];
}

+ (void)removeFileRWForFilename:(NSString *)filename {
  [[self sharedInstance] removeFileRWForFilename:filename];
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

- (THFileRW *)associatedFileRWForFilename:(NSString *)filename {
  return [_openedFiles objectForKey:filename];
}

- (void)setFileRW:(THFileRW *)fileRW forFilename:(NSString *)filename {
  [_openedFiles setObject:fileRW forKey:filename];
}

- (void)removeFileRWForFilename:(NSString *)filename {
  [_openedFiles removeObjectForKey:filename];
}

- (void)flushAll {
  for (THFileRW *fileRW in _openedFiles.allValues) {
    [fileRW close];
  }
}

@end
