#import "THPropertyList.h"

@class THMetadata;

@interface THWordKey : NSObject <NSCopying>

// The string the user recites with (e.g. kana of Japanese).
@property(nonatomic, readonly) NSString *input;

// The extra part of the key (e.g. kanji of Japanese).
@property(nonatomic, readonly) NSString *extra;

@property(nonatomic, readonly) NSString *outputKey;

@property(nonatomic, readonly) NSString *contentForDisplay;

- (instancetype)initWithInput:(NSString *)input extra:(NSString *)extra;

- (instancetype)initWithOutputKey:(NSString *)outputKey;

@end

@interface THWordObject : NSObject <THPropertyList>

@property(nonatomic, readonly) THMetadata *metadata;

@property(nonatomic, copy) NSString *explanation;

+ (instancetype)notFoundMarker;

- (instancetype)initWithExplanation:(NSString *)explanation;

@end

@interface THWordEntity : NSObject

@property(nonatomic) THWordKey *key;

@property(nonatomic) THWordObject *object;

@end
