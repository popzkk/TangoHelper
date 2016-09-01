#import "THFileRW.h"

#import "THFileCenter.h"
#import "THMetadata.h"
#import "THWord.h"

#pragma mark - THWordsCollection

@interface THWordsCollection ()

// THWordKey -> THWordObject
@property(nonatomic, readonly) NSMutableDictionary<THWordKey *, THWordObject *> *transformedContent;

// THWordkey.outputKey -> THWordObject.outputPropertyList
@property(nonatomic, readonly) NSMutableDictionary<NSString *, NSDictionary *> *content;

- (instancetype)initWithContent:(NSDictionary<NSString *, NSDictionary *> *)content;

// this silently allows a word to be added or edited.
- (void)setObject:(THWordObject *)object forKey:(THWordKey *)key;

@end

@implementation THWordsCollection {
  NSString *_lastSearchString;
  NSMutableArray *_lastSearchResult;
}

- (instancetype)initWithTransformedContent:
    (NSDictionary<THWordKey *, THWordObject *> *)transformedContent {
  self = [super init];
  if (self) {
    // we don't set _content here.
    _transformedContent = [NSMutableDictionary dictionaryWithDictionary:transformedContent];
    _lastSearchResult = [NSMutableArray array];
  }
  return self;
}

- (instancetype)initWithContent:(NSDictionary<NSString *, NSDictionary *> *)content {
  self = [super init];
  if (self) {
    _content = [NSMutableDictionary dictionaryWithDictionary:content];
    _transformedContent = [NSMutableDictionary dictionaryWithCapacity:_content.count];
    for (NSString *key in _content) {
      [_transformedContent
          setObject:[[THWordObject alloc] initWithPropertyList:[_content objectForKey:key]]
             forKey:[[THWordKey alloc] initWithOutputKey:key]];
    }
    _lastSearchResult = [NSMutableArray array];
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

- (void)addObject:(THWordObject *)object forKey:(THWordKey *)key {
  if ([_transformedContent objectForKey:key]) {
#if (DEBUG)
    NSLog(@"WARNING: cannot add an object for an existing key %@", key.outputKey);
#endif
    return;
  }
  [_transformedContent setObject:object forKey:key];
  [_content setObject:object.outputPropertyList forKey:key.outputKey];
}

- (void)removeObjectForKey:(THWordKey *)key {
#if (DEBUG)
  if (![_transformedContent objectForKey:key]) {
    NSLog(@"WARNING: cannot remove an object for a non-existing key %@", key.outputKey);
    return;
  }
#endif
  [_transformedContent removeObjectForKey:key];
  [_content removeObjectForKey:key.outputKey];
}

/**
 * Calling this method requires the reference of the object the same as before, because metadata is
 * updated quietly through THWordObject itself.
 */
- (void)editObject:(THWordObject *)object forKey:(THWordKey *)key oldKey:(THWordKey *)oldKey {
  // no action needed if keys are the same as the two objects are the same object.
  if (![oldKey isEqual:key]) {
    [_transformedContent removeObjectForKey:oldKey];
    [_transformedContent setObject:object forKey:key];
    [_content removeObjectForKey:oldKey.outputKey];
    [_content setObject:object.outputPropertyList forKey:key.outputKey];
  }
}

- (void)addObjects:(NSArray<THWordObject *> *)objects forKeys:(NSArray<THWordKey *> *)keys {
  NSUInteger count = keys.count;
  for (NSUInteger i = 0; i < count; ++i) {
    THWordKey *key = keys[i];
    THWordObject *object = objects[i];
    if ([_transformedContent objectForKey:key]) {
#if (DEBUG)
      NSLog(@"WARNING: cannot add an object for an existing key %@", key.outputKey);
#endif
      continue;
    }
    [_transformedContent setObject:object forKey:key];
    [_content setObject:object.outputPropertyList forKey:key.outputKey];
  }
}

- (void)removeObjectsForKeys:(NSArray<THWordKey *> *)keys {
  NSUInteger count = keys.count;
  for (NSUInteger i = 0; i < count; ++i) {
    THWordKey *key = keys[i];
#if (DEBUG)
    if (![_transformedContent objectForKey:key]) {
      NSLog(@"WARNING: cannot remove an object for a non-existing key %@", key.outputKey);
    }
#endif
    [_transformedContent removeObjectForKey:key];
    [_content removeObjectForKey:key.outputKey];
  }
}

- (void)addFromWordsCollection:(THWordsCollection *)collection {
  [_transformedContent addEntriesFromDictionary:collection.transformedContent];
  [_content addEntriesFromDictionary:collection.content];
}

- (void)setObject:(THWordObject *)object forKey:(THWordKey *)key {
  [_transformedContent setObject:object forKey:key];
  [_content setObject:object.outputPropertyList forKey:key.outputKey];
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

@end

#pragma mark - THFileRW related

static NSUInteger thres = 20;

@interface THMetadata ()

- (void)setObject:(NSDate *)object forKey:(THMetadataKey)key;

@end

#pragma mark - THFileRW

@interface THFileRW ()

@property(nonatomic) NSUInteger diff;

@property(nonatomic, readonly) NSString *path;

- (instancetype)initWithFilename:(NSString *)filename;

- (void)updateWithFilename:(NSString *)filename;

// this silently allows a word to be added or edited.
- (void)setObject:(THWordObject *)object forKey:(THWordKey *)key;

@end

@implementation THFileRW

#pragma mark - public

- (void)addObject:(THWordObject *)object forKey:(THWordKey *)key {
  [super addObject:object forKey:key];
  ++self.diff;
}

- (void)removeObjectForKey:(THWordKey *)key {
  [super removeObjectForKey:key];
  ++self.diff;
}

- (void)editObject:(THWordObject *)object forKey:(THWordKey *)key oldKey:(THWordKey *)oldKey {
  [super editObject:object forKey:key oldKey:oldKey];
  ++self.diff;
  if ([key isEqual:oldKey]) {
    [[THFileCenter sharedInstance] fileRW:self didUpdateKey:key withObject:object];
  }
}

- (void)addObjects:(NSArray<THWordObject *> *)objects forKeys:(NSArray<THWordKey *> *)keys {
  [super addObjects:objects forKeys:keys];
  self.diff += keys.count;
}

- (void)removeObjectsForKeys:(NSArray<THWordKey *> *)keys {
  [super removeObjectsForKeys:keys];
  self.diff += keys.count;
}

- (void)addFromWordsCollection:(THWordsCollection *)collection {
  [super addFromWordsCollection:collection];
  self.diff += collection.count;
}

- (void)flushWithThres:(NSUInteger)thres {
  if (self.diff > thres) {
    NSLog(@"flush \"%@\"", _filename);
    NSDictionary *dictionary = @{
      @"metadata" : _metadata.outputPropertyList,
      @"content" : self.content
    };
    if ([dictionary writeToFile:_path atomically:NO]) {
      _diff = 0;
    } else {
      NSLog(@"WARNING: writing to %@ fails.", _filename);
    }
  }
}

- (void)flush {
  [self flushWithThres:0];
}

#pragma mark - private

- (void)setDiff:(NSUInteger)diff {
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

- (void)setObject:(THWordObject *)object forKey:(THWordKey *)key {
  [super setObject:object forKey:key];
  ++self.diff;
}

@end
