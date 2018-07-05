#import "THWord.h"

#import "THMetadata.h"

#pragma mark - THWordKey

@implementation THWordKey

#pragma mark - public

- (instancetype)initWithInput:(NSString *)input extra:(NSString *)extra {
  self = [super init];
  if (self) {
    _input = [input copy];
    _extra = [extra copy];
    _outputKey = [NSString stringWithFormat:@"%@\\%@", _input, _extra];
    if (extra.length) {
      _contentForDisplay = [NSString stringWithFormat:@"%@ [%@]", _input, _extra];
    } else {
      _contentForDisplay = _input;
    }
  }
  return self;
}

- (instancetype)initWithOutputKey:(NSString *)outputKey {
  NSUInteger location = [outputKey rangeOfString:@"\\"].location;
  if (location == NSNotFound) {
    return [self initWithInput:outputKey extra:@""];
  } else {
    return [self initWithInput:[outputKey substringToIndex:location]
                         extra:[outputKey substringFromIndex:location + 1]];
  }
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[THWordKey alloc] initWithInput:_input extra:_extra];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)another {
  if (![another isKindOfClass:[THWordKey class]]) {
    return NO;
  }
  return [_outputKey isEqualToString:((THWordKey *)another).outputKey];
}

- (NSUInteger)hash {
  return [_outputKey hash];
}

@end

#pragma mark - THWordObject

@interface THMetadata ()

- (void)setObject:(NSDate *)object forKey:(THMetadataKey)key;

@end

@interface THWordObject ()

- (void)willPlay;

- (void)didPass;

@end

@implementation THWordObject

#pragma mark - public

+ (instancetype)notFoundMarker {
  THWordObject *object = [[self alloc] init];
  object->_explanation = @"";
  object->_metadata = nil;
  return object;
}

- (void)setExplanation:(NSString *)explanation {
  // No checking needed as setting the same explanation will trigger a refresh on last modified date
  _explanation = [explanation copy];
  [_metadata setObject:[NSDate date] forKey:THMetadataKeyModified];
}

- (void)willPlay {
  [_metadata setObject:[NSDate date] forKey:THMetadataKeyPlayed];
}

- (void)didPass {
  [_metadata setObject:[NSDate date] forKey:THMetadataKeyPassed];
}

- (instancetype)initWithExplanation:(NSString *)explanation {
  self = [super init];
  if (self) {
    _explanation = [explanation copy];
    _metadata = [[THMetadata alloc] init];
  }
  return self;
}

#pragma mark - THPropertyList

- (instancetype)initWithPropertyList:(id)input {
  if (![input isKindOfClass:[NSDictionary class]]) {
    NSLog(@"WARNING: must init THWordObject with a dictionary");
    return nil;
  }
  NSDictionary *propertyList = input;
  self = [super init];
  if (self) {
    _metadata = [[THMetadata alloc] initWithPropertyList:[propertyList objectForKey:@"metadata"]];
    _explanation = [[propertyList objectForKey:@"explanation"] copy];
  }
  return self;
}

- (id)outputPropertyList {
  return @{
    @"metadata" : _metadata.outputPropertyList,
    @"explanation" : _explanation,
  };
}

@end

#pragma mark - THWordEntity

@implementation THWordEntity

@end
