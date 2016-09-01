#import "THPlaylistsViewModel.h"

#import "../Backend/THFileCenter.h"
#import "../Backend/THMetadata.h"
#import "../Backend/THPlaylist.h"

@implementation THPlaylistsViewModel {
  NSArray<THPlaylist *> *_excluded;
  NSMutableArray<THPlaylist *> *_playlists;

  NSString *_searchString;
  NSMutableArray<THPlaylist *> *_outputPlaylists;
  NSMutableArray<NSNumber *> *_rowIndex;

  __weak id<THTableViewModelDelegate> _delegate;
}

@synthesize delegate = _delegate;

- (instancetype)initWithExcluded:(NSArray<THPlaylist *> *)excluded {
  self = [super init];
  if (self) {
    _excluded = [excluded copy];
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
  return _outputPlaylists.count;
}

- (NSString *)textAtRow:(NSUInteger)row {
  return _outputPlaylists[row].partialName;
}

- (NSString *)detailTextAtRow:(NSUInteger)row {
  if (_searchString.length) {
    return [_outputPlaylists[row] descWithString:_searchString];
  } else {
    return _outputPlaylists[row].desc;
  }
}

- (void)filterContentWithString:(NSString *)string ignoresEmptyString:(BOOL)ignoresEmptyString {
  if (!string.length) {
    if (ignoresEmptyString) {
      return;
    }
    _searchString = nil;
    _outputPlaylists = _playlists;
  } else {
    _searchString = [string copy];
    _outputPlaylists = [NSMutableArray array];
    _rowIndex = [NSMutableArray array];
    for (NSUInteger i = 0; i < _playlists.count; ++i) {
      THPlaylist *playlist = _playlists[i];
      if ([self searchStringMatchingRowIndex:i]) {
        [_outputPlaylists addObject:playlist];
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
  if (texts.count != 1) {
    NSLog(@"WARNING: can only add a playlist with 1 string");
    return;
  }
  if (_searchString.length) {
    NSLog(@"WARNING: cannot add a playlist during search");
    return;
  }
  if (!globalCheck) {
    NSLog(@"WARNING: globalCheck must be YES for playlists");
  }
  if (content && ![content isKindOfClass:[THWordsCollection class]]) {
    NSLog(@"WARNING: content must be a words collection");
    return;
  }
#endif
  NSString *partialName = texts.firstObject;
  THPlaylist *playlist = try_to_create(partialName);
  if (!playlist) {
    [_delegate globalCheckFailedWithHints:@[ partialName ] positiveAction:nil];
  } else {
    if (content) {
      [playlist addFromWordsCollection:content];
    }
    [_playlists insertObject:playlist atIndex:0];
    [_delegate modelDidAddAtRow:0];
  }
}

- (void)remove:(NSIndexSet *)rows {
#if (DEBUG)
  // this check is not 100% - a single selection can still pass this check.
  if (_searchString.length && rows.count > 1) {
    NSLog(@"WARNING: cannot remove multiple playlists during search");
    return;
  }
#endif
  if (rows.count > 1) {
    NSArray<THPlaylist *> *playlists = [_playlists objectsAtIndexes:rows];
    for (THPlaylist *playlist in playlists) {
      [[THFileCenter sharedInstance] deletePlaylist:playlist];
    }
    [_playlists removeObjectsAtIndexes:rows];
  } else {
    NSUInteger row = rows.firstIndex;
    [[THFileCenter sharedInstance] deletePlaylist:_outputPlaylists[row]];
    [_outputPlaylists removeObjectAtIndex:row];
    if (_searchString.length) {
      [_playlists removeObjectAtIndex:_rowIndex[row].unsignedIntegerValue];
      [_rowIndex removeObjectAtIndex:row];
    }
  }
  [_delegate modelDidRemoveRows:rows];
}

- (NSArray<NSString *> *)textsForModifyingRow:(NSUInteger)row {
  return @[ _outputPlaylists[row].partialName ];
}

- (void)modifyRow:(NSUInteger)row
        withTexts:(NSArray<NSString *> *)texts
      globalCheck:(BOOL)globalCheck {
#if (DEBUG)
  if (texts.count != 1) {
    NSLog(@"WARNING: can only edit a playlist with 1 strings");
    return;
  }
  if (!globalCheck) {
    NSLog(@"WARNING: globalCheck must be YES for playlists");
  }
#endif
  NSString *partialName = texts.firstObject;
  THPlaylist *playlist = _outputPlaylists[row];
  if ([playlist.partialName isEqualToString:partialName]) {
    return;
  }
  if ([[THFileCenter sharedInstance] playlistWithPartialName:partialName create:NO]) {
    [_delegate globalCheckFailedWithHints:@[ partialName ] positiveAction:nil];
  } else {
    [[THFileCenter sharedInstance] renamePlaylist:playlist withPartialName:partialName];
    [_delegate modelDidModifyAtRow:row];
  }
}

- (NSString *)infoOfRow:(NSUInteger)row {
  THMetadata *metadata = _playlists[row].metadata;
  return [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@",
                                    [metadata translateDateWithKey:THMetadataKeyCreated],
                                    [metadata translateDateWithKey:THMetadataKeyModified],
                                    [metadata translateDateWithKey:THMetadataKeyPlayed],
                                    [metadata translateDateWithKey:THMetadataKeyFinished],
                                    [metadata translateDateWithKey:THMetadataKeyPassed]];
}

- (THWordsCollection *)mergedContentOfRows:(NSIndexSet *)rows {
#if (DEBUG)
  if (_searchString.length) {
    NSLog(@"WARNING: cannot calc merged content in search mode");
    return nil;
  }
#endif
  THWordsCollection *collection = [[THWordsCollection alloc] initWithTransformedContent:nil];
  NSArray<THWordsCollection *> *collections = [_outputPlaylists objectsAtIndexes:rows];
  for (THWordsCollection *anotherCollection in collections) {
    [collection addFromWordsCollection:anotherCollection];
  }
  return collection;
}

- (id)itemAtRow:(NSUInteger)row {
  return _outputPlaylists[row];
}

- (NSArray<THPlaylist *> *)itemsAtRows:(NSIndexSet *)rows {
  return [_outputPlaylists objectsAtIndexes:rows];
}

- (NSSet<THPlaylist *> *)allItems {
  return [NSSet setWithArray:_outputPlaylists];
}

#pragma mark - private

- (void)reloadResources {
  _playlists = [[THFileCenter sharedInstance] playlists];
  [_playlists removeObjectsInArray:_excluded];
  _outputPlaylists = _playlists;
}

- (BOOL)searchStringMatchingRowIndex:(NSUInteger)rowIndex {
  if (!_searchString.length) {
    return YES;
  }
  THPlaylist *playlist = _playlists[rowIndex];
  return ([playlist.partialName containsString:_searchString] ||
          [playlist searchWithString:_searchString].count);
}

@end
