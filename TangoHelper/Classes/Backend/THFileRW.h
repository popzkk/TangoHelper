#import <Foundation/Foundation.h>

@interface THFileRW : NSObject

+ (instancetype)instanceForFilename:(NSString *)filename;

+ (instancetype)instanceForFilename:(NSString *)filename create:(BOOL)create;

// will call |flush:| of every instance.
+ (void)flushAll;

- (NSString *)filename;

- (NSArray *)allKeys;

- (NSArray *)objectsForKeys:(NSArray *)keys;

- (NSString *)objectForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)setObject:(NSString *)object forKey:(NSString *)key;

// force writing immediately.
- (void)flush;

// close self. Will flush before closing.
- (void)close;

@end
