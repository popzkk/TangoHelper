#import "THWordsManager.h"

#import "THFileCenter.h"
#import "THFileRW.h"
#import "THWord.h"

@implementation THWordsManager

+ (THWordsManagerOverwriteAction)collection:(THWordsCollection *)collection
                      wantsToAddExplanation:(NSString *)explanation
                                     forKey:(THWordKey *)key
                                conflicting:(THWordsCollection **)conflicting {
  THWordsCollection *conflictingCollection =
      [self globalCollectionContainingKey:key defaultCollection:collection];
  *conflicting = conflictingCollection;
  if (!conflictingCollection) {
    return nil;
  }
  THWordObject *target = [conflictingCollection objectForKey:key];
  if ([target.explanation isEqualToString:explanation]) {
    return nil;
  } else {
    return ^{
      target.explanation = explanation;
      [conflictingCollection editObject:target forKey:key oldKey:key];
    };
  }
}

+ (THWordsManagerOverwriteAction)collection:(THWordsCollection *)collection
                     wantsToEditExplanation:(NSString *)explanation
                                     forKey:(THWordKey *)key
                                     oldKey:(THWordKey *)oldKey
                                conflicting:(THWordsCollection **)conflicting {
  THWordsCollection *conflictingCollection =
      [self globalCollectionContainingKey:key defaultCollection:collection];
  *conflicting = conflictingCollection;
  THWordObject *object = [conflictingCollection objectForKey:key];
  if ([key isEqual:oldKey]) {
    if ([object.explanation isEqualToString:explanation]) {
      return nil;
    } else {
      return ^{
        object.explanation = explanation;
        // here conflctingCollection must be equal to collection
        [conflictingCollection editObject:object forKey:key oldKey:key];
      };
    }
  } else {
    if (collection == conflictingCollection) {
      return ^{
        object.explanation = explanation;
        [collection removeObjectForKey:oldKey];
        [collection editObject:object forKey:key oldKey:key];
      };
    } else {
      return ^{
        THWordObject *oldObj = [collection objectForKey:oldKey];
        oldObj.explanation = explanation;
        [collection editObject:oldObj forKey:key oldKey:oldKey];
        object.explanation = explanation;
        [conflictingCollection editObject:object forKey:key oldKey:key];
      };
    }
  }
}

+ (THWordsCollection *)globalCollectionContainingKey:(THWordKey *)key
                                   defaultCollection:(THWordsCollection *)collection {
  if ([collection objectForKey:key]) {
    return collection;
  }
  NSArray<THFileRW *> *array = [[THFileCenter sharedInstance] wordsFiles];
  for (THFileRW *fileRW in array) {
    if ([fileRW objectForKey:key]) {
      return fileRW;
    }
  }
  return nil;
}

@end
