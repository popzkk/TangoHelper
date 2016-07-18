#import "THWordsViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THDepot.h"
#import "Backend/THPlaylist.h"
#import "Shared/THHelpers.h"
#import "Shared/THStrings.h"
#import "THPlaylistsViewController.h"

/** TODO
 * save selected rows when switched out.
 */

typedef NS_ENUM(NSUInteger, THWordsViewControllerSituation) {
  THWordsViewControllerDepot = 0,
  THWordsViewControllerPlaylist,
  THWordsViewControllerAddingToPlaylist,
};

static NSString *kCellIdentifier = @"WordsViewCell";
static CGFloat kWordHeight = 50;

@interface NSIndexPath (THWordsViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row;

@end

#pragma mark - THWordsViewController

@interface THWordsViewController ()<UITableViewDataSource, UITableViewDelegate>

@end

@implementation THWordsViewController {
  THDepot *_depot;
  THPlaylist *_playlist;
  THWordsViewControllerSituation _situation;
  THFileRW *_fileRW;
  NSMutableArray *_keys;
  NSMutableArray *_objects;
  NSUInteger _nSelected;

  UIBarButtonItem *_edit;
  UIBarButtonItem *_done;
  UIBarButtonItem *_left;
  UIBarButtonItem *_middle;
  UIBarButtonItem *_right;
  UIBarButtonItem *_padding;
}

#pragma mark - public

- (instancetype)initUsingDepot {
  return [self initUsingDepotWithPlaylist:nil];
}

- (instancetype)initWithPlaylist:(THPlaylist *)playlist {
  return [self initWithDepot:nil playlist:playlist];
}

- (instancetype)initUsingDepotWithPlaylist:(THPlaylist *)playlist {
  return [self initWithDepot:[[THFileCenter sharedInstance] depot] playlist:playlist];
}

#pragma mark - private

- (void)refreshDataSource {
  if (_depot && !_playlist) {
    _keys = [_depot allKeys];
    _objects = [_depot objectsForKeys:_keys];
    _nSelected = 0;
  } else if (!_depot && _playlist) {
    _keys = [_playlist allKeys];
    _objects = [_playlist objectsForKeys:_keys];
    _nSelected = 0;
  } else {
    // must be _depot && _playlist
    NSMutableArray *keys = [_playlist allKeys];
    _nSelected = keys.count;
    NSMutableArray *objects = [_playlist objectsForKeys:keys];
    NSArray *tmpKeys = [_depot allKeys];
    for (NSString *key in tmpKeys) {
      if (![_playlist objectForKey:key]) {
        [keys addObject:key];
        [objects addObject:[_depot objectForKey:key]];
      }
    }
    _keys = keys;
    _objects = objects;
  }
}

- (instancetype)initWithDepot:(THDepot *)depot playlist:(THPlaylist *)playlist {
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    _depot = depot;
    _playlist = playlist;
    if (_depot && !_playlist) {
      _situation = THWordsViewControllerDepot;
      _fileRW = _depot;
      self.title = kDepotTitle;
    } else if (!_depot && _playlist) {
      _situation = THWordsViewControllerPlaylist;
      _fileRW = _playlist;
      self.title = playlist_title(_playlist.partialName);
    } else if (_depot && _playlist) {
      _situation = THWordsViewControllerAddingToPlaylist;
      _fileRW = _depot;
      self.title = add_to_playlist_title(_playlist.partialName);
    } else {
      NSLog(@"both depot and playlist are nil!");
      return nil;
    }

    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    _padding = system_item(UIBarButtonSystemItemFlexibleSpace, nil, nil);
    _edit = system_item(UIBarButtonSystemItemEdit, self, @selector(startEditing));
    _done = system_item(UIBarButtonSystemItemDone, self, @selector(endEditing));
    _left =
        system_item(_depot && _playlist ? UIBarButtonSystemItemCancel : UIBarButtonSystemItemTrash,
                    self, @selector(leftTapped));
    _middle = system_item(UIBarButtonSystemItemAdd, self, @selector(middleTapped));
    _right = system_item(UIBarButtonSystemItemPlay, self, @selector(rightTapped));

    if (_situation == THWordsViewControllerDepot) {
        self.navigationItem.rightBarButtonItem = _edit;
    } else if ( _situation == THWordsViewControllerPlaylist) {
#ifdef RENAME_IN_SWIPE
      self.navigationItem.rightBarButtonItem = _edit;
#else
      UIBarButtonItem *rename = custom_item(kRename, UIBarButtonItemStylePlain, self, @selector(renameTapped));
      self.navigationItem.rightBarButtonItems = @[ _edit, rename ];
#endif
    } else { // THWordsViewControllerAddingToPlaylist
        self.navigationItem.hidesBackButton = YES;
        self.tableView.editing = YES;
        for (NSUInteger i = 0; i < _nSelected; ++i) {
          [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i]
                                      animated:NO
                                scrollPosition:UITableViewScrollPositionNone];
        }
    }
  }
  return self;
}

- (void)startEditing {
  [self.tableView setEditing:YES animated:YES];
  self.navigationItem.rightBarButtonItem = _done;
  // if showing a playlist, there are always three items so we don't change it.
  if (_situation != THWordsViewControllerPlaylist) {
    [self setToolbarItems:@[ _left, _padding, _middle, _padding, _right ] animated:YES];
  }
}

- (void)endEditing {
  // if showing a playlist, there are always three items so we don't change it.
  if (_situation != THWordsViewControllerPlaylist) {
    [self setToolbarItems:@[ _padding, _middle, _padding ] animated:YES];
  }
  self.navigationItem.rightBarButtonItem = _edit;
  [self.tableView setEditing:NO animated:YES];
}

- (void)leftTapped {
  // for "adding to playlist", it is a cancel button.
  if (_situation == THWordsViewControllerAddingToPlaylist) {
    [self.navigationController popViewControllerAnimated:NO];
  } else {
    NSString *title;
    if (_situation == THWordsViewControllerDepot) {
      title = kRemoveDialogTitleFromDepot;
    } else {  // THWordsViewControllerPlaylist
      if (self.tableView.isEditing) {
        title = remove_dialog_title_from_playlist(_playlist.partialName);
      } else {
        title = play_dialog_title(_playlist.partialName);
      }
    }
    if ((_situation == THWordsViewControllerPlaylist && self.tableView.isEditing) ||
        _situation == THWordsViewControllerDepot) {
      // if it is a depot or a non-editing playlist, remove selected.
      NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
      if (!indexPaths) {
        return;
      }
      // _nSelected is 0 here.
      NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
      for (NSIndexPath *indexPath in indexPaths) {
        [indexSet addIndex:indexPath.row];
      }

      [self.navigationController
          presentViewController:basic_alert(
                                    title, nil,
                                    ^() {
                                      NSArray *keys = [_keys objectsAtIndexes:indexSet];
                                      for (NSString *key in keys) {
                                        [_fileRW removeObjectForKey:key];
                                      }
                                      [_keys removeObjectsAtIndexes:indexSet];
                                      [_objects removeObjectsAtIndexes:indexSet];
                                      [self.tableView
                                          deleteRowsAtIndexPaths:indexPaths
                                                withRowAnimation:UITableViewRowAnimationNone];
                                    })
                       animated:YES
                     completion:nil];
    } else {
      // otherwise remove the playlist itself.
      [self.navigationController
          presentViewController:basic_alert(title, nil,
                                            ^() {
                                              [[THFileCenter sharedInstance]
                                                  deletePlaylist:_playlist];
                                              [self.navigationController
                                                  popToRootViewControllerAnimated:YES];
                                            })
                       animated:YES
                     completion:nil];
      return;
    }
  }
}

- (void)middleTapped {
  if (_situation == THWordsViewControllerPlaylist) {
    // if it is showing a playlist, then add words from the depot.
    [self.navigationController
        pushViewController:[[THWordsViewController alloc] initUsingDepotWithPlaylist:_playlist]
                  animated:NO];
  } else {
    // otherwise, it means adding a word.
    [self.navigationController
        presentViewController:texts_alert(kWordDialogTitleAdd, nil, @[ @"", @"" ],
                                          @[ kWordDialogKeyTextField, kWordDialogObjectTextField ],
                                          ^(NSArray<UITextField *> *textFields) {
                                            // check if valid.
                                            NSString *key = textFields.firstObject.text;
                                            // ...object should change.
                                            NSString *object = [textFields objectAtIndex:1].text;
                                            [_fileRW setObject:object forKey:key];
                                            [_keys insertObject:key atIndex:_nSelected];
                                            [_objects insertObject:object atIndex:_nSelected];
                                            [self.tableView
                                                insertRowsAtIndexPaths:@[
                                                  [NSIndexPath indexPathForRow:_nSelected]
                                                ]
                                                      withRowAnimation:UITableViewRowAnimationNone];
                                          })
                     animated:YES
                   completion:nil];
  }
}

- (void)rightTapped {
  if (_situation == THWordsViewControllerPlaylist && !self.tableView.isEditing) {
    // if it is a non-editing playlist, go to play.
    [self.navigationController
        presentViewController:basic_alert(play_dialog_title(_playlist.partialName), nil,
                                          ^() {
                                            NSLog(@"Will play %@", _playlist.partialName);
                                          })
                     animated:YES
                   completion:nil];
  } else {
    // otherwise, it is either "adding to playlist" or "adding a playlist with the selected".

    // pre-selected rows are not counted.
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
      if (indexPath.row >= _nSelected) {
        [indexSet addIndex:indexPath.row];
      }
    }
    if (_situation == THWordsViewControllerAddingToPlaylist) {
      [_playlist setObjects:[_objects objectsAtIndexes:indexSet]
                    forKeys:[_keys objectsAtIndexes:indexSet]];
      [self.navigationController popViewControllerAnimated:YES];
    } else {
      [self.navigationController
          presentViewController:texts_alert(
                                    kPlaylistDialogTitle, nil, @[ @"" ],
                                    @[ kPlaylistDialogTextField ],
                                    ^(NSArray<UITextField *> *texts) {
                                      NSString *partialName = texts.firstObject.text;
                                      THPlaylist *playlist = [[THFileCenter sharedInstance]
                                          playlistWithPartialName:partialName
                                                           create:YES];
                                      [playlist setObjects:[_objects objectsAtIndexes:indexSet]
                                                   forKeys:[_keys objectsAtIndexes:indexSet]];
                                      [self.navigationController
                                          popToRootViewControllerAnimated:YES];
                                      [(THPlaylistsViewController *)
                                              self.navigationController.viewControllers.firstObject
                                          showDialogForPlaylist:playlist];
                                    })
                       animated:YES
                     completion:nil];
    }
  }
}

#ifndef RENAME_IN_SWIPE
- (void)renameTapped {
  [self.navigationController
      presentViewController:texts_alert(kRename, nil, @[ _playlist.partialName ], @[ @"" ],
                                        ^(NSArray<UITextField *> *textFields) {
                                          // ...check if valid.
                                          NSString *newPartialName = textFields.firstObject.text;
                                          [[THFileCenter sharedInstance]
                                               renamePlaylist:_playlist
                                              withPartialName:newPartialName];
                                          self.title = newPartialName;
                                        })
                   animated:YES
                 completion:nil];
}
#endif

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
  switch (_situation) {
    case THWordsViewControllerDepot:
      if (!self.tableView.editing) {
        self.toolbarItems = @[ _padding, _middle, _padding ];
        break;
      }
    default:
      self.toolbarItems = @[ _left, _padding, _middle, _padding, _right ];
      break;
  }
  [self refreshDataSource];
  [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                  reuseIdentifier:kCellIdentifier];
  }
  NSInteger row = indexPath.row;
  cell.textLabel.text = [_keys objectAtIndex:row];
  cell.textLabel.font = [UIFont fontWithName:@"" size:30];
  // ...object should change.
  cell.detailTextLabel.text = [_objects objectAtIndex:row];
  if (indexPath.row < _nSelected) {
    // ...config a different style.
  }
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _keys.count;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kWordHeight;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row < _nSelected) {
    cell.selected = YES;
  }
}

- (NSIndexPath *)tableView:(UITableView *)tableView
willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row < _nSelected) {
    return nil;
  } else {
    return indexPath;
  }
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewRowAction *edit = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kEdit
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   NSUInteger row = indexPath.row;
                   NSString *oldKey = [_keys objectAtIndex:row];
                   // ...object should change.
                   NSString *oldExplanation = [_objects objectAtIndex:row];
                   [self.navigationController
                       presentViewController:
                           texts_alert(kWordDialogTitleEdit, nil, @[ oldKey, oldExplanation ],
                                       @[ @"", @"" ],
                                       ^(NSArray<UITextField *> *textFields) {
                                         // check if valid.
                                         NSString *key = textFields.firstObject.text;
                                         NSString *object = [textFields objectAtIndex:1].text;
                                         if (![oldKey isEqualToString:key]) {
                                           [_fileRW removeObjectForKey:oldKey];
                                         }
                                         [_fileRW setObject:object forKey:key];
                                         [_keys setObject:key atIndexedSubscript:row];
                                         [_objects setObject:object atIndexedSubscript:row];
                                         [self.tableView
                                             reloadRowsAtIndexPaths:@[ indexPath ]
                                                   withRowAnimation:UITableViewRowAnimationNone];
                                       })
                                    animated:YES
                                  completion:nil];
                 }];
  UITableViewRowAction *remove = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kRemove
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   NSUInteger row = indexPath.row;
                   [self.navigationController
                       presentViewController:
                           basic_alert(remove_dialog_title_normal([_keys objectAtIndex:row]), nil,
                                       ^() {
                                         [_fileRW removeObjectForKey:[_keys objectAtIndex:row]];
                                         [_keys removeObjectAtIndex:row];
                                         [_objects removeObjectAtIndex:row];
                                         [self.tableView
                                             deleteRowsAtIndexPaths:@[ indexPath ]
                                                   withRowAnimation:UITableViewRowAnimationNone];
                                       })
                                    animated:YES
                                  completion:nil];
                 }];
  remove.backgroundColor = [UIColor redColor];
  return @[ remove, edit ];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  self.navigationItem.rightBarButtonItem = nil;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  self.navigationItem.rightBarButtonItem = _edit;
}

@end

#pragma mark - NSIndexPath (THWordsViewController)

@implementation NSIndexPath (THWordsViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row {
  return [self indexPathForRow:row inSection:0];
}

@end
