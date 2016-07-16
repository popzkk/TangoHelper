#import <Foundation/Foundation.h>

@interface THFileRW : NSObject

- (NSString *)filename;

- (NSArray *)allKeys;

- (NSArray *)objectsForKeys:(NSArray *)keys;

- (id)objectForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)setObject:(NSString *)object forKey:(id)key;

// force writing immediately.
- (void)flush;

@end
