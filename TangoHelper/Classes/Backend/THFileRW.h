#import <Foundation/Foundation.h>

@interface THFileRW : NSObject

- (NSString *)filename;

// returns an empty array if no entries exist.
- (NSMutableArray *)allKeys;

- (NSMutableArray *)objectsForKeys:(NSArray *)keys;

- (id)objectForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)setObject:(NSString *)object forKey:(id)key;

- (void)setObjects:(NSArray *)objects forKeys:(NSArray *)keys;

// force writing immediately.
- (void)flush;

@end
