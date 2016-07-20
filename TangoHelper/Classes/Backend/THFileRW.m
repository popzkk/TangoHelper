#import "THFileRW.h"

#import "THFileCenter.h"

static NSUInteger thres = 20;

@interface THFileRW ()

@property(nonatomic) NSUInteger diff;
@property(nonatomic, readonly) NSMutableDictionary *content;

@end

@implementation THFileRW {
  NSString *_path;
}

#pragma mark - public

- (NSUInteger)count {
  return _content.count;
}

- (NSMutableArray *)allKeys {
  return [NSMutableArray arrayWithArray:_content.allKeys];
}

- (NSMutableArray *)objectsForKeys:(NSArray *)keys {
  return [NSMutableArray arrayWithArray:[_content objectsForKeys:keys notFoundMarker:@""]];
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

- (void)setObjects:(NSArray *)objects forKeys:(NSArray *)keys {
  [_content addEntriesFromDictionary:[NSDictionary dictionaryWithObjects:objects forKeys:keys]];
  self.diff += keys.count;
}

- (void)addFromFileRW:(THFileRW *)otherFileRW {
  [_content addEntriesFromDictionary:otherFileRW.content];
  self.diff += otherFileRW.count;
}

- (void)flush {
  [self flushWithThres:0];
}

#pragma mark - private

- (void)setDiff:(NSUInteger)diff {
  _diff = diff;
  [self flushWithThres:thres];
}

- (void)flushWithThres:(NSUInteger)thres {
  if (self.diff > thres) {
    NSLog(@"flush \"%@\"", _filename);
    if ([_content writeToFile:_path atomically:NO]) {
      _diff = 0;
    } else {
      NSLog(@"writing to %@ fails.", _filename);
    }
  }
}

// only called internally, and thus ensures that this file does exist!
- (instancetype)initWithFilename:(NSString *)filename {
  self = [super init];
  if (self) {
    [self updateWithFilename:filename];
    _content = [NSMutableDictionary dictionaryWithContentsOfFile:_path];
    if (!_content) {
      _content = [NSMutableDictionary dictionary];
    }
    _diff = 0;
  }
  return self;
}

- (void)updateWithFilename:(NSString *)filename {
  _filename = filename;
  _path = [[THFileCenter sharedInstance].directoryPath stringByAppendingPathComponent:_filename];
}

@end
