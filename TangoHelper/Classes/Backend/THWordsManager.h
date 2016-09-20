#import <Foundation/Foundation.h>

@class THFileRW;
@class THWordKey;
@class THWordObject;

typedef void (^THWordsManagerOverwriteAction)();

@interface THWordsManager : NSObject

+ (instancetype)sharedInstance;

- (THWordObject *)objectForKey:(THWordKey *)key;

- (void)didInitializeFileRW:(THFileRW *)fileRW;

- (void)willRemoveFileRW:(THFileRW *)fileRW;

- (void)fileRW:(THFileRW *)fileRW didAddObject:(THWordObject *)object forKey:(THWordKey *)key;

- (void)fileRW:(THFileRW *)fileRW willRemoveKey:(THWordKey *)key;

- (void)willPlayKey:(THWordKey *)key;

- (void)didPassKey:(THWordKey *)key;

@end
