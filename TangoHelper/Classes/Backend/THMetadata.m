#import "THMetadata.h"

#pragma mark - NSDate (THMetadata)

@implementation NSDate (THMetadata)

+ (instancetype)startDate {
  return [NSDate dateWithTimeIntervalSince1970:1456676400];
}

+ (NSString *)translateDate:(NSDate *)date {
  if (!date) {
    return @"Never";
  } else if ([date isEqualToDate:[self startDate]]) {
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

- (NSString *)day {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"dd";
  return [formatter stringFromDate:self];
}

- (NSString *)month {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"MM";
  return [formatter stringFromDate:self];
}

- (NSString *)humanDiffWithDate:(NSDate *)date {
  NSInteger thisYear = [[self year] integerValue];
  NSInteger thatYear = [[date year] integerValue];
  if (thisYear != thatYear) {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale currentLocale];
    formatter.dateFormat = @"yyyy-MMM-dd";
    return [formatter stringFromDate:self];
  } else {
    NSInteger thisMonth = [[self month] integerValue];
    NSInteger thatMonth = [[date month] integerValue];
    if (thisMonth != thatMonth) {
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      formatter.locale = [NSLocale currentLocale];
      formatter.dateFormat = @"MMM-dd";
      return [formatter stringFromDate:self];
    } else {
      NSInteger thisDay = [[self day] integerValue];
      NSInteger thatDay = [[date day] integerValue];
      if (thisDay != thatDay) {
        NSInteger diffDay = thatDay - thisDay;
        if (diffDay == 1) {
          return @"Yesterday";
        } else if (diffDay <= 11) {
          return [NSString stringWithFormat:@"%ld days ago", (long)diffDay];
        } else {
          NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
          formatter.locale = [NSLocale currentLocale];
          formatter.dateFormat = @"MMM-dd";
          return [formatter stringFromDate:self];
        }
      } else {
        NSTimeInterval diff = [date timeIntervalSinceDate:self];
        if (diff < 11) {
          return @"Just now";
        } else if (diff < 60) {
          return [NSString stringWithFormat:@"%.0f seconds ago", diff];
        } else if (diff < 60 * 60) {
          return [NSString stringWithFormat:@"%.0f minutes ago", diff / 60];
        } else {
          return [NSString stringWithFormat:@"%.0f hours ago", diff / (60 * 60)];
        }
      }
    }
  }
}

- (NSString *)humanDiffWithNow {
  return [self humanDiffWithDate:[NSDate date]];
}

@end

#pragma mark - THMetadata

@interface THMetadata ()

- (void)setObject:(NSDate *)object forKey:(THMetadataKey)key;

- (void)flush;

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
  _dirty = YES;
  [_dict setObject:object forKey:_keys[key]];
}

- (void)flush {
  _dirty = NO;
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
