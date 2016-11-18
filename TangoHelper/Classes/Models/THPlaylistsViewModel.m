#import "THPlaylistsViewModel.h"

#import "../Backend/THFileCenter.h"
#import "../Backend/THMetadata.h"
#import "../Backend/THPlaylist.h"

@implementation THPlaylistsViewModel {
  NSArray<THPlaylist *> *_excluded;
  NSMutableArray<THPlaylist *> *_playlists;
  BOOL _specialPlaylistExisting;

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
    [self reload];
  }
  return self;
}

- (void)reload {
  _playlists = [[THFileCenter sharedInstance] playlists];
  [_playlists removeObjectsInArray:_excluded];
  THPlaylist *specialPlaylist =
      [[THFileCenter sharedInstance] playlistWithPartialName:kSpecialPlaylistPartialName create:NO];
  NSUInteger indexOfSpecialPlaylist = [_playlists indexOfObject:specialPlaylist];
  if (indexOfSpecialPlaylist != NSNotFound) {
    _specialPlaylistExisting = YES;
    for (NSUInteger i = indexOfSpecialPlaylist; i > 0; --i) {
      _playlists[i] = _playlists[i - 1];
    }
    _playlists[0] = specialPlaylist;
  } else {
    _specialPlaylistExisting = NO;
  }
  _outputPlaylists = _playlists;
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

- (void)add:(NSArray<NSString *> *)texts {
  [self add:texts content:nil];
}

- (void)add:(NSArray<NSString *> *)texts content:(id)content {
#if (DEBUG)
  if (texts.count != 1) {
    NSLog(@"WARNING: can only add a playlist with 1 string");
    return;
  }
  if (_searchString.length) {
    NSLog(@"WARNING: cannot add a playlist during search");
    return;
  }
  if (content && ![content isKindOfClass:[THWordsCollection class]]) {
    NSLog(@"WARNING: content must be a words collection");
    return;
  }
#endif
  NSString *partialName = texts.firstObject;
  THPlaylist *playlist =
      [[THFileCenter sharedInstance] tryToCreatePlaylistWithPartialName:partialName];
  if (!playlist) {
    [_delegate globalCheckFailedWithHints:@[ partialName ] positiveAction:nil];
  } else {
    if (content) {
      [playlist addFromWordsCollection:content];
    }
    NSUInteger rowToInsertAt = _specialPlaylistExisting ? 1 : 0;
    if ([partialName isEqualToString:kSpecialPlaylistPartialName]) {
      _specialPlaylistExisting = YES;
    }
    [_playlists insertObject:playlist atIndex:rowToInsertAt];
    [_delegate modelDidAddAtRow:rowToInsertAt];
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
  // Deny removing the special playlist.
  if (_specialPlaylistExisting && [rows containsIndex:0]) {
    [_delegate modelDidRemoveRows:nil];
    return;
  }
  if (rows.count > 1) {
    NSArray<THPlaylist *> *playlists = [_playlists objectsAtIndexes:rows];
    for (THPlaylist *playlist in playlists) {
      [[THFileCenter sharedInstance] removePlaylist:playlist];
    }
    [_playlists removeObjectsAtIndexes:rows];
  } else {
    NSUInteger row = rows.firstIndex;
    [[THFileCenter sharedInstance] removePlaylist:_outputPlaylists[row]];
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

- (void)modifyRow:(NSUInteger)row withTexts:(NSArray<NSString *> *)texts {
#if (DEBUG)
  if (texts.count != 1) {
    NSLog(@"WARNING: can only edit a playlist with 1 strings");
    return;
  }
#endif
  NSString *partialName = texts.firstObject;
  THPlaylist *playlist = _outputPlaylists[row];
  if ([playlist.partialName isEqualToString:partialName]) {
    return;
  }
  // Deny renaming the special playlist.
  if (_specialPlaylistExisting && row == 0) {
    [_delegate modelDidModifyAtRow:NSNotFound];
    return;
  }
  if ([[THFileCenter sharedInstance] playlistWithPartialName:partialName create:NO]) {
    [_delegate globalCheckFailedWithHints:@[ partialName ] positiveAction:nil];
  } else {
    [[THFileCenter sharedInstance] renamePlaylist:playlist withPartialName:partialName];
    if ([partialName isEqualToString:kSpecialPlaylistPartialName]) {
      NSLog(@"Here");
      _specialPlaylistExisting = YES;
    }
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

- (BOOL)searchStringMatchingRowIndex:(NSUInteger)rowIndex {
  if (!_searchString.length) {
    return YES;
  }
  THPlaylist *playlist = _playlists[rowIndex];
  return ([playlist.partialName containsString:_searchString] ||
          [playlist searchWithString:_searchString].count);
}

@end
