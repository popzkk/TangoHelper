#import "THFileRW.h"

#import "THFileCenter.h"

static NSUInteger thres = 20;

@interface THFileRW ()

@property(nonatomic) NSUInteger diff;

@end

@implementation THFileRW {
  NSString *_filename;
  NSString *_path;
  NSMutableDictionary *_content;
}

#pragma mark - public

- (NSString *)filename {
  return _filename;
}

- (NSArray *)allKeys {
  return _content.allKeys;
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
  // ...sync playlists with depot?
}

- (void)setObject:(NSString *)object forKey:(NSString *)key {
  [_content setObject:object forKey:key];
  ++self.diff;
  // ...sync depot with playlists, though no need to sync adding.
}

- (void)flush {
  [self flushWithThres:0];
}

#pragma mark - private

- (instancetype)initWithFilename:(NSString *)filename {
  self = [super init];
  if (self) {
    _filename = filename;
    _path = [[THFileCenter sharedInstance].directoryPath stringByAppendingPathComponent:_filename];
    _content = [NSMutableDictionary dictionaryWithContentsOfFile:_path];
    _diff = 0;
  }
  return _content ? self : nil;
}

- (void)setDiff:(NSUInteger)diff {
  _diff = diff;
  [self flushWithThres:thres];
}

- (void)flushWithThres:(NSUInteger)thres {
  if (self.diff > thres) {
    if ([_content writeToFile:_path atomically:NO]) {
      _diff = 0;
    } else {
      NSLog(@"writing to %@ fails.", _filename);
    }
  }
}

@end
