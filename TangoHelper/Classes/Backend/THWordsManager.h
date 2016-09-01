#import <Foundation/Foundation.h>

@class THWordsCollection;
@class THWordKey;
@class THWordObject;

typedef void (^THWordsManagerOverwriteAction)();

@interface THWordsManager : NSObject

/**
 * @return A block. If nil and conflicting is not set, you should add the word yourself,
 * else if block is nil but conflicting is set, that means no adding is needed (same words)
 * otherwise this block will *add* the word for you and get rid of all the conflicts.
 */
+ (THWordsManagerOverwriteAction)collection:(THWordsCollection *)collection
                      wantsToAddExplanation:(NSString *)explanation
                                     forKey:(THWordKey *)key
                                conflicting:(THWordsCollection **)conflicting;

/**
 * @return A block, which will get rid of all the conflicts *and* edit the word for you. (nil means
 * no editing is needed)
 */
+ (THWordsManagerOverwriteAction)collection:(THWordsCollection *)collection
                     wantsToEditExplanation:(NSString *)expanation
                                     forKey:(THWordKey *)key
                                     oldKey:(THWordKey *)oldKey
                                conflicting:(THWordsCollection **)conflicting;

+ (THWordsCollection *)globalCollectionContainingKey:(THWordKey *)key
                                   defaultCollection:(THWordsCollection *)collection;

@end
