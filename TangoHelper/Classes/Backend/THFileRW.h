#import <Foundation/Foundation.h>

@class THMetadata;
@class THWordKey;
@class THWordObject;

#pragma mark - THWordsCollection

@interface THWordsCollection : NSObject

@property(nonatomic, readonly) NSUInteger count;

- (instancetype)initWithTransformedContent:
    (NSDictionary<THWordKey *, THWordObject *> *)transformedContent;

- (NSArray<THWordKey *> *)allKeys;

- (NSArray<THWordObject *> *)objectsForKeys:(NSArray<THWordKey *> *)keys;

- (THWordObject *)objectForKey:(THWordKey *)key;

- (BOOL)addObject:(THWordObject *)object forKey:(THWordKey *)key;

- (BOOL)removeObjectForKey:(THWordKey *)key;

- (THWordObject *)editOldKey:(THWordKey *)oldKey
                       toKey:(THWordKey *)key
             withExplanation:(NSString *)explanation;

- (void)addObjects:(NSArray<THWordObject *> *)objects forKeys:(NSArray<THWordKey *> *)keys;

- (void)removeObjectsForKeys:(NSArray<THWordKey *> *)keys;

- (void)addFromWordsCollection:(THWordsCollection *)collection;

- (NSArray<THWordKey *> *)searchWithString:(NSString *)string;

@end

#pragma mark - THFileRW

@interface THFileRW : THWordsCollection

@property(nonatomic, readonly) NSString *filename;

@property(nonatomic, readonly) THMetadata *metadata;

- (void)flushWithThres:(NSUInteger)thres;

// force writing immediately.
- (void)flush;

@end
