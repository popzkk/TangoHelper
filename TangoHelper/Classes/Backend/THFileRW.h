#import <Foundation/Foundation.h>

@interface THFileRW : NSObject

@property(nonatomic, readonly) NSString *filename;

@property(nonatomic, readonly) NSUInteger count;

// returns an empty array if no entries exist.
- (NSMutableArray *)allKeys;

- (NSMutableArray *)objectsForKeys:(NSArray *)keys;

- (id)objectForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)setObject:(NSString *)object forKey:(id)key;

- (void)setObjects:(NSArray *)objects forKeys:(NSArray *)keys;

- (void)addFromFileRW:(THFileRW *)otherFileRW;

// force writing immediately.
- (void)flush;

@end
