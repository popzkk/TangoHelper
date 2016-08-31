#import "THMetadata.h"

#pragma mark - NSDate (THMetadata)

@implementation NSDate (THMetadata)

+ (instancetype)startDate {
  return [NSDate dateWithTimeIntervalSince1970:1456676400];
}

+ (NSString *)translateDate:(NSDate *)date {
  if (!date) {
    return @"Never";
  } else if ([date isEqualToDate:[NSDate startDate]]) {
    return @"Before Kaikai implemented this feature";
  } else {
#if (DEBUG)
    if ([date timeIntervalSinceDate:[self startDate]] < 0) {
      NSLog(@"WARNING: invalid data");
    }
#endif
    return [date humanDiffWithNow];
  }
}

- (NSString *)year {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyy";
  return [formatter stringFromDate:self];
}

- (NSString *)humanDiffWithDate:(NSDate *)date {
  NSTimeInterval diff = [date timeIntervalSinceDate:self];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.locale = [NSLocale currentLocale];
  if (diff < 11) {
    return @"Just now";
  } else if (diff < 60) {
    return [NSString stringWithFormat:@"%.0f seconds ago", diff];
  } else if (diff < 60 * 60) {
    return [NSString stringWithFormat:@"%.0f minutes ago", diff / 60];
  } else if (diff < 60 * 60 * 24) {
    return [NSString stringWithFormat:@"%.0f hours ago", diff / (60 * 60)];
  } else if (diff < 60 * 60 * 24 * 2) {
    return @"Yesterday";
  } else if (diff < 60 * 60 * 24 * 3) {
    return @"The day before yesterday";
  } else if (diff < 60 * 60 * 24 * 11) {
    return [NSString stringWithFormat:@"%.0f days ago", diff / (60 * 60 * 24)];
  } else if ([[self year] isEqualToString:[date year]]) {
    formatter.dateFormat = @"dd MMM";
    return [formatter stringFromDate:self];
  } else {
    formatter.dateFormat = @"dd MMM yyyy";
    return [formatter stringFromDate:self];
  }
}

- (NSString *)humanDiffWithNow {
  return [self humanDiffWithDate:[NSDate date]];
}

@end

#pragma mark - THMetadata

@interface THMetadata ()

- (void)setObject:(NSDate *)object forKey:(THMetadataKey)key;

@end

@implementation THMetadata {
  NSArray<NSString *> *_keys;
  NSMutableDictionary *_dict;
}

@synthesize outputPropertyList = _dict;

#pragma mark - public

- (instancetype)init {
  self = [super init];
  if (self) {
    _keys = @[
      @"Created",
      @"Modified",
      @"Last Played",
      @"Last Finished",
      @"Last Passed",
    ];
    _dict =
        [NSMutableDictionary dictionaryWithObject:[NSDate date] forKey:_keys[THMetadataKeyCreated]];
  }
  return self;
}

- (NSDate *)objectForKey:(THMetadataKey)key {
  return [_dict objectForKey:_keys[key]];
}

- (NSString *)translateDateWithKey:(THMetadataKey)key {
  return [NSString
      stringWithFormat:@"%@: %@", _keys[key], [NSDate translateDate:[self objectForKey:key]]];
}

#pragma mark - private

- (void)setObject:(NSDate *)object forKey:(THMetadataKey)key {
  [_dict setObject:object forKey:_keys[key]];
}

#pragma mark - THPropertyListDictionary

- (instancetype)initWithPropertyList:(id)propertyList {
  if (![propertyList isKindOfClass:[NSDictionary class]]) {
    NSLog(@"WARNING: must init THMetadata with a dictionary");
    return nil;
  }
  self = [super init];
  if (self) {
    _keys = @[
      @"Created",
      @"Modified",
      @"Last Played",
      @"Last Finished",
      @"Last Passed",
    ];
    _dict = [NSMutableDictionary dictionaryWithDictionary:propertyList];
  }
  return self;
}

@end
