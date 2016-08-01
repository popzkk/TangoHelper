#import <Foundation/Foundation.h>

@interface THFileRW : NSObject

@property(nonatomic, readonly) NSString *filename;

@property(nonatomic, readonly) NSUInteger count;

- (NSArray *)allKeys;

- (NSArray *)objectsForKeys:(NSArray *)keys;

- (id)objectForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)setObject:(id)object forKey:(id)key;

- (void)setObjects:(NSArray *)objects forKeys:(NSArray *)keys;

- (void)addFromFileRW:(THFileRW *)anotherFileRW;

- (void)flushWithThres:(NSUInteger)thres;

// force writing immediately.
- (void)flush;

@end
