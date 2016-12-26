#import "THFileRW.h"

#import "THFileCenter.h"
#import "THMetadata.h"
#import "THWord.h"
#import "THWordsManager.h"

#pragma mark - THWordsCollection

@interface THWordsCollection ()

@property(nonatomic, readonly) NSMutableDictionary<THWordKey *, THWordObject *> *transformedContent;

- (instancetype)initWithContent:(NSDictionary<NSString *, NSDictionary *> *)content;

- (NSDictionary<NSString *, NSDictionary *> *)content;

@end

@implementation THWordsCollection {
  NSString *_lastSearchString;
  NSMutableArray *_lastSearchResult;
}

- (instancetype)initWithTransformedContent:
    (NSDictionary<THWordKey *, THWordObject *> *)transformedContent {
  self = [super init];
  if (self) {
    _transformedContent = [NSMutableDictionary dictionaryWithDictionary:transformedContent];
  }
  return self;
}

- (NSUInteger)count {
  return _transformedContent.count;
}

- (NSArray<THWordKey *> *)allKeys {
  return _transformedContent.allKeys;
}

- (NSArray<THWordObject *> *)objectsForKeys:(NSArray<THWordKey *> *)keys {
  return [_transformedContent objectsForKeys:keys notFoundMarker:[THWordObject notFoundMarker]];
}

- (THWordObject *)objectForKey:(THWordKey *)key {
  return [_transformedContent objectForKey:key];
}

- (BOOL)addObject:(THWordObject *)object forKey:(THWordKey *)key {
  if ([_transformedContent objectForKey:key]) {
    return NO;
  }
  [_transformedContent setObject:object forKey:key];
  return YES;
}

- (BOOL)removeObjectForKey:(THWordKey *)key {
  if (![_transformedContent objectForKey:key]) {
    return NO;
  }
  [_transformedContent removeObjectForKey:key];
  return YES;
}

- (THWordObject *)editOldKey:(THWordKey *)oldKey
                       toKey:(THWordKey *)key
             withExplanation:(NSString *)explanation {
  BOOL sameKey = [key isEqual:oldKey];
  THWordObject *object = [[THWordsManager sharedInstance] objectForKey:key];
  // If there is a conflict, simply return the conflicting object.
  if (object && !sameKey && ![explanation isEqualToString:object.explanation]) {
    return object;
  }
  // If the word is not changed, simple return nil.
  if (sameKey && [explanation isEqualToString:object.explanation]) {
    return nil;
  }
  // In this case, we have key != oldKey.
  if (!object) {
    object = [[THWordObject alloc] initWithExplanation:explanation];
  } else {
    object.explanation = explanation;
  }
  if (!sameKey) {
    [self removeObjectForKey:oldKey];
    [self removeObjectForKey:key];
    [self addObject:object forKey:key];
  }
  return nil;
}

- (void)addObjects:(NSArray<THWordObject *> *)objects forKeys:(NSArray<THWordKey *> *)keys {
  NSUInteger count = keys.count;
  for (NSUInteger i = 0; i < count; ++i) {
    [self addObject:objects[i] forKey:keys[i]];
  }
}

- (void)removeObjectsForKeys:(NSArray<THWordKey *> *)keys {
  for (THWordKey *key in keys) {
    [self removeObjectForKey:key];
  }
}

- (void)addFromWordsCollection:(THWordsCollection *)collection {
  NSArray<THWordKey *> *keys = collection.allKeys;
  NSArray<THWordObject *> *objects = [collection objectsForKeys:keys];
  [self addObjects:objects forKeys:keys];
}

- (NSArray<THWordKey *> *)searchWithString:(NSString *)string {
  if (!string.length) {
    return [_transformedContent.allKeys copy];
  }
  if (![string isEqualToString:_lastSearchString]) {
    _lastSearchString = [string copy];
    [_lastSearchResult removeAllObjects];
    for (THWordKey *key in _transformedContent) {
      if ([key.outputKey containsString:string] ||
          [[_transformedContent objectForKey:key].explanation containsString:string]) {
        [_lastSearchResult addObject:key];
      }
    }
  }
  return [_lastSearchResult copy];
}

- (instancetype)initWithContent:(NSDictionary<NSString *, NSDictionary *> *)content {
  self = [super init];
  if (self) {
    _transformedContent = [NSMutableDictionary dictionaryWithCapacity:content.count];
    for (NSString *outputKey in content) {
      THWordKey *key = [[THWordKey alloc] initWithOutputKey:outputKey];
      THWordObject *object = [[THWordsManager sharedInstance] objectForKey:key];
      if (!object) {
        object = [[THWordObject alloc] initWithPropertyList:[content objectForKey:outputKey]];
      }
      [_transformedContent setObject:object forKey:key];
    }
    _lastSearchResult = [NSMutableArray array];
  }
  return self;
}

// THWordKey.outputKey -> THWordObject.outputPropertyList
- (NSDictionary<NSString *, NSDictionary *> *)content {
  NSMutableDictionary<NSString *, NSDictionary *> *content =
      [NSMutableDictionary dictionaryWithCapacity:_transformedContent.count];
  for (THWordKey *key in _transformedContent) {
    [content setObject:[_transformedContent objectForKey:key].outputPropertyList
                forKey:key.outputKey];
  }
  return content;
}

@end

#pragma mark - THFileRW

static NSUInteger thres = 10;

@interface THMetadata ()

- (void)setObject:(NSDate *)object forKey:(THMetadataKey)key;

- (void)flush;

@end

@interface THFileRW ()

@property(nonatomic) NSUInteger diff;

@property(nonatomic, readonly) NSString *path;

- (instancetype)initWithFilename:(NSString *)filename;

- (void)updateWithFilename:(NSString *)filename;

@end

@implementation THFileRW

#pragma mark - public

- (BOOL)addObject:(THWordObject *)object forKey:(THWordKey *)key {
  if ([super addObject:object forKey:key]) {
    [[THWordsManager sharedInstance] fileRW:self didAddObject:object forKey:key];
    [_metadata setObject:[NSDate date] forKey:THMetadataKeyModified];
    ++self.diff;
    return YES;
  }
  return NO;
}

- (BOOL)removeObjectForKey:(THWordKey *)key {
  if ([super removeObjectForKey:key]) {
    // This is actually "didRemoveKey"...
    [[THWordsManager sharedInstance] fileRW:self willRemoveKey:key];
    [_metadata setObject:[NSDate date] forKey:THMetadataKeyModified];
    ++self.diff;
    return YES;
  }
  return NO;
}

- (THWordObject *)editOldKey:(THWordKey *)oldKey
                       toKey:(THWordKey *)key
             withExplanation:(NSString *)explanation {
  THWordObject *object = [super editOldKey:oldKey toKey:key withExplanation:explanation];
  if (object) {
    return object;
  } else {
    [_metadata setObject:[NSDate date] forKey:THMetadataKeyModified];
    ++self.diff;
    return nil;
  }
}

- (void)markDirty {
  ++_diff;
  [self flushWithThres:thres];
}

#pragma mark - private

- (NSDictionary *)content {
  return @{
    @"metadata" : _metadata.outputPropertyList,
    @"content" : [super content],
  };
}

- (void)flushWithThres:(NSUInteger)thres {
  if ((thres == 0 && _metadata.dirty) || _diff > thres) {
    NSLog(@"flushing \"%@\"", _filename);
    if ([[self content] writeToFile:_path atomically:NO]) {
      _diff = 0;
      [_metadata flush];
    } else {
      NSLog(@"WARNING: writing to %@ fails.", _filename);
    }
  }
}

- (void)flush {
  [self flushWithThres:0];
}

- (void)setDiff:(NSUInteger)diff {
  if (_diff == diff) {
    return;
  }
  _diff = diff;
  [_metadata setObject:[NSDate date] forKey:THMetadataKeyModified];
  [self flushWithThres:thres];
}

// only called internally, and thus ensures that this file does exist!
- (instancetype)initWithFilename:(NSString *)filename {
  [self updateWithFilename:filename];
  NSDictionary *file = [NSDictionary dictionaryWithContentsOfFile:_path];
  if (!file.count) {
    file = @{
      @"metadata" : [[THMetadata alloc] init].outputPropertyList,
      @"content" : [NSDictionary dictionary],
    };
    [file writeToFile:_path atomically:NO];
  }
  self = [super initWithContent:[file objectForKey:@"content"]];
  if (self) {
    _metadata = [[THMetadata alloc] initWithPropertyList:[file objectForKey:@"metadata"]];
    _diff = 0;
  }
  return self;
}

- (void)updateWithFilename:(NSString *)filename {
  _filename = filename;
  _path = [[THFileCenter sharedInstance].directoryPath stringByAppendingPathComponent:_filename];
}

@end
