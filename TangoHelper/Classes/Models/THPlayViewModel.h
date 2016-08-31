#import <Foundation/Foundation.h>

@class THWordsCollection;
@class THWordKey;

typedef NS_ENUM(NSUInteger, THPlayOption) {
  THPlayOptionNext = 0,
  THPlayOptionTypo,
  THPlayOptionWrongRight,
  THPlayOptionWrongWrong,
  THPlayOptionRemove,
};

@interface THPlayConfig : NSObject<NSCopying>

@property(nonatomic, assign) NSUInteger repeat;

@property(nonatomic, assign) BOOL lazyAssert;

@end

@interface THPlayResult : NSObject

@property(nonatomic) NSSet<THWordKey *> *wrongWordKeys;

@end

@protocol THPlayViewModelDelegate

- (void)nextWordWithExplanation:(NSString *)explanation;

- (void)wrongAnswer:(NSString *)wrongAnswer
     forExplanation:(NSString *)explanation
            wordKey:(THWordKey *)wordKey;

- (void)playFinishedWithResult:(THPlayResult *)result;

@end

@interface THPlayViewModel : NSObject

- (instancetype)initWithCollection:(THWordsCollection *)collection
                            config:(THPlayConfig *)config
                          delegate:(id<THPlayViewModelDelegate>)delegate;

- (void)start;

- (void)confirmInput:(NSString *)input;

- (void)commitWrongAnswerWithOption:(THPlayOption)option texts:(NSArray<NSString *> *)texts;

@end