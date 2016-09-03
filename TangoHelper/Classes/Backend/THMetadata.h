#import "THPropertyList.h"

typedef NS_ENUM(NSUInteger, THMetadataKey) {
  THMetadataKeyCreated = 0,
  THMetadataKeyModified,
  THMetadataKeyPlayed,
  THMetadataKeyFinished,
  THMetadataKeyPassed,
  numbersOfTHMetadataKey,
};

@interface NSDate (THMetadata)

+ (instancetype)startDate;

+ (NSString *)translateDate:(NSDate *)date;

- (NSString *)humanDiffWithDate:(NSDate *)date;

- (NSString *)humanDiffWithNow;

@end

@interface THMetadata : NSObject<THPropertyList>

@property(nonatomic, readonly) BOOL dirty;

- (NSDate *)objectForKey:(THMetadataKey)key;

// Will automtically set "created".
- (instancetype)init;

- (NSString *)translateDateWithKey:(THMetadataKey)key;

@end
