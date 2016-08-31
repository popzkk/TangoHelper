#import "THWordsViewModel.h"

#import "../Backend/THFileCenter.h"
#import "../Backend/THFileRW.h"
#import "../Backend/THMetadata.h"
#import "../Backend/THPlaylist.h"
#import "../Backend/THWord.h"
#import "../Backend/THWordsManager.h"

@implementation THWordsViewModel {
  THWordsCollection *_collection;

  NSMutableArray<THWordKey *> *_keys;
  NSMutableArray<THWordObject *> *_objects;

  NSString *_searchString;
  NSMutableArray<THWordKey *> *_outputKeys;
  NSMutableArray<THWordObject *> *_outputObjects;
  NSMutableArray<NSNumber *> *_rowIndex;

  __weak NSObject<THTableViewModelDelegate, THWordsViewModelDelegate> *_delegate;
}

@synthesize delegate = _delegate;

- (instancetype)initWithCollection:(THWordsCollection *)collection {
  self = [super init];
  if (self) {
    _collection = collection;
    [self reloadResources];
  }
  return self;
}

- (void)reload {
  [self reloadResources];
  // _searchString must be empty, no need to filter.
  [_delegate modelDidGetUpdated];
}

- (NSUInteger)numberOfRows {
  return _outputKeys.count;
}

- (NSString *)textAtRow:(NSUInteger)row {
  return _outputKeys[row].contentForDisplay;
}

- (NSString *)detailTextAtRow:(NSUInteger)row {
  return _outputObjects[row].explanation;
}

- (void)filterContentWithString:(NSString *)string ignoresEmptyString:(BOOL)ignoresEmptyString {
  if (!string.length) {
    if (ignoresEmptyString) {
      return;
    }
    _searchString = nil;
    _outputKeys = _keys;
    _outputObjects = _objects;
  } else {
    _searchString = [string copy];
    _outputKeys = [NSMutableArray array];
    _outputObjects = [NSMutableArray array];
    _rowIndex = [NSMutableArray array];
    for (NSUInteger i = 0; i < _keys.count; ++i) {
      THWordKey *key = _keys[i];
      THWordObject *object = _objects[i];
      if ([self searchStringMatchingRowIndex:i]) {
        [_outputKeys addObject:key];
        [_outputObjects addObject:object];
        [_rowIndex addObject:@(i)];
      }
    }
  }
  [_delegate modelDidGetUpdated];
}

- (void)add:(NSArray<NSString *> *)texts globalCheck:(BOOL)globalCheck {
  [self add:texts content:nil globalCheck:globalCheck];
}

- (void)add:(NSArray<NSString *> *)texts content:(id)content globalCheck:(BOOL)globalCheck {
#if (DEBUG)
  if (!content && texts.count != 3) {
    NSLog(@"WARNING: can only add a word with 3 strings");
    return;
  }
  if (content && texts.count != 1) {
    NSLog(@"WARNING: can only add a playlist with 1 string");
    return;
  }
  if (_searchString.length) {
    NSLog(@"WARNING: cannot add a word during search");
    return;
  }
#endif
  if (content) {
    NSString *partialName = texts.firstObject;
    THPlaylist *playlist = try_to_create(partialName);
    if (!playlist) {
      [_delegate globalCheckFailedWithHints:@[ partialName ] positiveAction:nil];
    } else {
      [playlist addFromWordsCollection:content];
      [_delegate modelDidCreatePlaylist:playlist];
    }
    return;
  }
  THWordKey *key = [[THWordKey alloc] initWithInput:texts[0] extra:texts[1]];
  NSString *explanation = texts[2];
  THWordsCollection *collection;
  THWordsManagerOverwriteAction action = [THWordsManager collection:_collection
                                              wantsToAddExplanation:explanation
                                                             forKey:key
                                                        conflicting:&collection];
  // that means the same words
  if (!action && collection == _collection) {
    return;
  }
  void (^add_block)(THWordObject *object) = ^(THWordObject *object) {
    [_collection addObject:object forKey:key];
    // must be zero.
    [_keys insertObject:key atIndex:0];
    [_objects insertObject:object atIndex:0];
    [_delegate modelDidAddAtRow:0];
  };
  if (globalCheck && action) {
    [_delegate globalCheckFailedWithHints:@[
      key.contentForDisplay,
      explanation,
      [collection objectForKey:key].explanation,
    ]
                           positiveAction:^{
                             if (action) {
                               action();
                             }
                             if (collection == _collection) {
                               [_delegate modelDidModifyAtRow:[_outputKeys indexOfObject:key]];
                             } else {
                               // if there is a conflicting collection, there will be a editing to
                               // that THWordObject
                               // and anyway we are going to reference that object.
                               add_block([collection objectForKey:key]);
                             }
                           }];
    return;
  }
  add_block([[THWordObject alloc] initWithExplanation:explanation]);
}

- (void)remove:(NSIndexSet *)rows {
#if (DEBUG)
  // this check is not 100% - a single selection can still pass this check.
  if (_searchString.length && rows.count > 1) {
    NSLog(@"WARNING: cannot remove multiple words during search");
    return;
  }
#endif
  if (rows.count > 1) {
    [_collection removeObjectsForKeys:[_keys objectsAtIndexes:rows]];
    [_keys removeObjectsAtIndexes:rows];
    [_objects removeObjectsAtIndexes:rows];
  } else {
    NSUInteger row = rows.firstIndex;
    [_collection removeObjectForKey:_outputKeys[row]];
    if (_searchString.length) {
      NSUInteger rowIndex = _rowIndex[row].unsignedIntegerValue;
      [_keys removeObjectAtIndex:rowIndex];
      [_objects removeObjectAtIndex:rowIndex];
      [_rowIndex removeObjectAtIndex:row];
    }
    [_outputKeys removeObjectAtIndex:row];
    [_outputObjects removeObjectAtIndex:row];
  }
  [_delegate modelDidRemoveRows:rows];
}

- (NSArray<NSString *> *)textsForModifyingRow:(NSUInteger)row {
  return @[ _outputKeys[row].input, _outputKeys[row].extra, _outputObjects[row].explanation ];
}

/** TODO: migrate this to use THWordsManager */
- (void)modifyRow:(NSUInteger)row
        withTexts:(NSArray<NSString *> *)texts
      globalCheck:(BOOL)globalCheck {
#if (DEBUG)
  if (texts.count != 3) {
    NSLog(@"WARNING: can only edit a word with 3 strings");
    return;
  }
#endif
  THWordKey *oldKey = _outputKeys[row];
  THWordKey *key = [[THWordKey alloc] initWithInput:texts[0] extra:texts[1]];
  NSString *newExplanation = texts[2];
  THWordObject *object = _outputObjects[row];
  if ([oldKey isEqual:key] && [object.explanation isEqualToString:newExplanation]) {
    return;
  }

  __block NSUInteger trueRow = row;
  if (globalCheck && ![oldKey isEqual:key]) {
    THWordsCollection *tmpFileRW = [self globalFileRWContainingKey:key];
    THWordObject *tmpObj = [tmpFileRW objectForKey:key];
    THAlertBasicAction removeUnnecessary = ^() {
      NSUInteger anotherRow = [_outputKeys indexOfObject:key];
      if (anotherRow != NSNotFound) {
        [self remove:[NSIndexSet indexSetWithIndex:anotherRow]];
        if (anotherRow < trueRow) {
          --trueRow;
        }
      } else {
        if (tmpFileRW == _collection) {
          [_collection removeObjectForKey:key];
          [_keys removeObject:key];
          [_objects removeObject:tmpObj];
        }
      }
    };
    if (tmpObj) {
      if (![newExplanation isEqualToString:tmpObj.explanation]) {
        [_delegate globalCheckFailedWithHints:@[
          oldKey.contentForDisplay,
          key.contentForDisplay,
          newExplanation,
          tmpObj.explanation
        ]
                               positiveAction:^{
                                 tmpObj.explanation = newExplanation;
                                 [tmpFileRW editObject:tmpObj forKey:key oldKey:key];
                                 removeUnnecessary();
                                 [self modifyRow:trueRow withTexts:texts globalCheck:NO];
                               }];
        return;
      }
      removeUnnecessary();
    }
  }

  object.explanation = newExplanation;
  [_collection editObject:object forKey:key oldKey:oldKey];
  if (![oldKey isEqual:key]) {
    if (_searchString.length) {
      _keys[_rowIndex[trueRow].unsignedIntegerValue] = key;
    }
    [_outputKeys removeObjectAtIndex:trueRow];
    [_outputKeys insertObject:key atIndex:trueRow];
  }

  if (!_searchString.length ||
      [self searchStringMatchingRowIndex:_rowIndex[trueRow].unsignedIntegerValue]) {
    [_delegate modelDidModifyAtRow:trueRow];
  } else {
    [_outputKeys removeObjectAtIndex:trueRow];
    [_outputObjects removeObjectAtIndex:trueRow];
    [_rowIndex removeObjectAtIndex:trueRow];
    [_delegate modelDidRemoveRows:[NSIndexSet indexSetWithIndex:trueRow]];
  }
}

- (NSString *)infoOfRow:(NSUInteger)row {
  THMetadata *metadata = _objects[row].metadata;
  return [NSString stringWithFormat:@"%@\n%@\n%@\n%@",
                                    [metadata translateDateWithKey:THMetadataKeyCreated],
                                    [metadata translateDateWithKey:THMetadataKeyModified],
                                    [metadata translateDateWithKey:THMetadataKeyPlayed],
                                    [metadata translateDateWithKey:THMetadataKeyPassed]];
}

- (THWordsCollection *)mergedContentOfRows:(NSIndexSet *)rows {
#if (DEBUG)
  if (_searchString.length) {
    NSLog(@"WARNING: cannot calc merged content in search mode");
    return nil;
  }
#endif
  NSArray<THWordKey *> *selectedKeys = [_outputKeys objectsAtIndexes:rows];
  return [[THWordsCollection alloc]
      initWithTransformedContent:[NSDictionary
                                     dictionaryWithObjects:[_collection objectsForKeys:selectedKeys]
                                                   forKeys:selectedKeys]];
}

- (id)itemAtRow:(NSUInteger)row {
  return _outputKeys[row];
}

- (NSArray<THWordKey *> *)itemsAtRows:(NSIndexSet *)rows {
  return [_outputKeys objectsAtIndexes:rows];
}

- (NSSet<THWordKey *> *)allItems {
  return [NSSet setWithArray:_outputKeys];
}

#pragma mark - private

- (void)reloadResources {
  _keys = [NSMutableArray arrayWithArray:[_collection allKeys]];
  shuffle(_keys);
  _objects = [NSMutableArray arrayWithArray:[_collection objectsForKeys:_keys]];
  _outputKeys = _keys;
  _outputObjects = _objects;
}

- (BOOL)searchStringMatchingRowIndex:(NSUInteger)rowIndex {
  if (!_searchString.length) {
    return YES;
  }
  THWordKey *key = _keys[rowIndex];
  THWordObject *object = _objects[rowIndex];
  return ([key.contentForDisplay containsString:_searchString] ||
          [object.explanation containsString:_searchString]);
}

- (THWordsCollection *)globalFileRWContainingKey:(THWordKey *)key {
  if ([_collection objectForKey:key]) {
    return _collection;
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
