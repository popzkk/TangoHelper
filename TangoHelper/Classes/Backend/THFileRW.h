#import <Foundation/Foundation.h>

@interface THFileRW : NSObject

+ (instancetype)instanceForPath:(NSString *)path;

// will call flush: of every instance.
+ (void)flushAll;

- (NSString *)objectForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)setObject:(NSString *)object forKey:(NSString *)key;

// force writing immediately.
- (void)flush;

// close self. Will flush before closing.
- (void)close;

@end
