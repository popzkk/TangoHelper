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

- (void)someFileRWDidAddObject:(THWordObject *)object forKey:(THWordKey *)key;

- (void)someFileRWDidRemoveKey:(THWordKey *)key;

@end
