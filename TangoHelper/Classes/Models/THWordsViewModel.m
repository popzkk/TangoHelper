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

  __weak NSObject<THTableViewModelDelegate, THWordsViewModelDelegate> *_delegate;
}

@synthesize delegate = _delegate;

- (instancetype)initWithCollection:(THWordsCollection *)collection {
  self = [super init];
  if (self) {
    _collection = collection;
    [self reload];
  }
  return self;
}

- (void)reload {
  _keys = [NSMutableArray arrayWithArray:[_collection allKeys]];
  shuffle(_keys);
  _objects = [NSMutableArray arrayWithArray:[_collection objectsForKeys:_keys]];
  _outputKeys = _keys;
  _outputObjects = _objects;
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
    for (NSUInteger i = 0; i < _keys.count; ++i) {
      THWordKey *key = _keys[i];
      THWordObject *object = _objects[i];
      if ([self searchStringMatchingKey:key object:object]) {
        [_outputKeys addObject:key];
        [_outputObjects addObject:object];
      }
    }
  }
  [_delegate modelDidGetUpdated];
}

- (void)add:(NSArray<NSString *> *)texts {
  [self add:texts content:nil];
}

- (void)add:(NSArray<NSString *> *)texts content:(id)content {
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
  void (^add_block)(THWordObject *object) = ^(THWordObject *object) {
    [_collection addObject:object forKey:key];
    // must be zero.
    [_keys insertObject:key atIndex:0];
    [_objects insertObject:object atIndex:0];
    [_delegate modelDidAddAtRow:0];
  };
  BOOL inside = [_collection objectForKey:key] != nil;
  THWordObject *oldObj = [[THWordsManager sharedInstance] objectForKey:key];
  if (oldObj && ![oldObj.explanation isEqualToString:explanation]) {
    [_delegate
        globalCheckFailedWithHints:@[ key.contentForDisplay, explanation, oldObj.explanation ]
                    positiveAction:^{
                      oldObj.explanation = explanation;
                      if (inside) {
                        [_delegate modelDidModifyAtRow:[_keys indexOfObject:key]];
                      } else {
                        add_block(oldObj);
                      }
                    }];
  } else {
    if (inside) {
      return;
    }
    if (oldObj) {
      add_block(oldObj);
    } else {
      add_block([[THWordObject alloc] initWithExplanation:explanation]);
    }
  }
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
      [_keys removeObject:_outputKeys[row]];
      [_objects removeObject:_outputObjects[row]];
    }
    [_outputKeys removeObjectAtIndex:row];
    [_outputObjects removeObjectAtIndex:row];
  }
  [_delegate modelDidRemoveRows:rows];
}

- (NSArray<NSString *> *)textsForModifyingRow:(NSUInteger)row {
  return @[ _outputKeys[row].input, _outputKeys[row].extra, _outputObjects[row].explanation ];
}

- (void)modifyRow:(NSUInteger)row withTexts:(NSArray<NSString *> *)texts {
#if (DEBUG)
  if (texts.count != 3) {
    NSLog(@"WARNING: can only edit a word with 3 strings");
    return;
  }
#endif
  THWordKey *oldKey = _outputKeys[row];
  THWordObject *oldObject = _outputObjects[row];
  THWordKey *key = [[THWordKey alloc] initWithInput:texts[0] extra:texts[1]];
  NSString *explanation = texts[2];
  if ([key isEqual:oldKey] && [explanation isEqualToString:oldObject.explanation]) {
    return;
  }
  THWordObject *object = [_collection editOldKey:oldKey toKey:key withExplanation:explanation];
  if (object) {
    [_delegate globalCheckFailedWithHints:@[
      oldKey.contentForDisplay,
      key.contentForDisplay,
      explanation,
      object.explanation
    ]
                           positiveAction:^{
                             object.explanation = explanation;
                             [self modifyRow:row withTexts:texts];
                           }];
  } else {
    object = [_collection objectForKey:key];
    // If one word is removed in the collection, remove the same word again.
    if (_collection.count != _keys.count) {
      NSUInteger anotherRow = [_outputKeys indexOfObject:key];
      if (anotherRow != NSNotFound) {
        [_outputKeys removeObjectAtIndex:anotherRow];
        [_outputObjects removeObjectAtIndex:anotherRow];
        [_delegate modelDidRemoveRows:[NSIndexSet indexSetWithIndex:anotherRow]];
        if (anotherRow < row) {
          --row;
        }
      }
      if (_searchString.length) {
        [_keys removeObject:key];
        [_objects removeObject:object];
      }
    }
    // Then change the "row" to <key, object>
    if (_searchString.length) {
      _keys[[_keys indexOfObject:oldKey]] = key;
      _objects[[_objects indexOfObject:oldObject]] = object;
    }
    _outputKeys[row] = key;
    _outputObjects[row] = object;
    // Finally see if the modified word still matches the filter.
    if (!_searchString.length || [self searchStringMatchingKey:key object:object]) {
      [_delegate modelDidModifyAtRow:row];
    } else {
      [_outputKeys removeObjectAtIndex:row];
      [_outputObjects removeObjectAtIndex:row];
      [_delegate modelDidRemoveRows:[NSIndexSet indexSetWithIndex:row]];
    }
  }
}

- (NSString *)infoOfRow:(NSUInteger)row {
  THMetadata *metadata = _outputObjects[row].metadata;
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

- (NSString *)accessibilityLabelAtRow:(NSUInteger)row {
  return _outputKeys[row].input;
}

#pragma mark - private

- (BOOL)searchStringMatchingKey:(THWordKey *)key object:(THWordObject *)object {
  if (!_searchString.length) {
    return YES;
  }
  return ([key.contentForDisplay containsString:_searchString] ||
          [object.explanation containsString:_searchString]);
}

@end
