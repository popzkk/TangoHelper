#import "THWordsViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THDepot.h"
#import "Backend/THPlaylist.h"
#import "Shared/THHelpers.h"
#import "Shared/THStrings.h"
#import "THPlaylistsViewController.h"
#import "THPlayViewController.h"

typedef NS_ENUM(NSUInteger, THWordsViewControllerSituation) {
  kTHWordsViewControllerDepot = 0,
  kTHWordsViewControllerPlaylist,
  kTHWordsViewControllerAddingToPlaylist,
};

static NSString *kCellIdentifier = @"WordsViewCell";
static CGFloat kWordHeight = 40;

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
  NSString *_oldKey;  // when a cell is being editted, it records the cell's original key.

  UIBarButtonItem *_edit;
  UIBarButtonItem *_done;
  UIBarButtonItem *_left;
  UIBarButtonItem *_middle;
  UIBarButtonItem *_right;
  UIBarButtonItem *_rename;
  UIBarButtonItem *_padding;

  NSLock *lock;
  BOOL _middleSecondTap;  // whether the next tap is the second tap on the middle button.
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
    _keys = [NSMutableArray arrayWithArray:[_depot allKeys]];
    _objects = [NSMutableArray arrayWithArray:[_depot objectsForKeys:_keys]];
    _nSelected = 0;
  } else if (!_depot && _playlist) {
    _keys = [NSMutableArray arrayWithArray:[_playlist allKeys]];
    _objects = [NSMutableArray arrayWithArray:[_playlist objectsForKeys:_keys]];
    _nSelected = 0;
  } else {
    // must be _depot && _playlist
    NSMutableArray *keys = [NSMutableArray arrayWithArray:[_playlist allKeys]];
    _nSelected = keys.count;
    NSMutableArray *objects = [NSMutableArray arrayWithArray:[_playlist objectsForKeys:keys]];
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
      _situation = kTHWordsViewControllerDepot;
      _fileRW = _depot;
      self.title = kDepotTitle;
    } else if (!_depot && _playlist) {
      _situation = kTHWordsViewControllerPlaylist;
      _fileRW = _playlist;
      self.title = playlist_title(_playlist.partialName);
    } else if (_depot && _playlist) {
      _situation = kTHWordsViewControllerAddingToPlaylist;
      _fileRW = _depot;
      self.title = add_to_playlist_title(_playlist.partialName);
    } else {
      NSLog(@"Internal error: both depot and playlist are nil!");
      return nil;
    }

    self.tableView.rowHeight = kWordHeight;
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
    _middleSecondTap = 0;
    _right = system_item(UIBarButtonSystemItemPlay, self, @selector(rightTapped));

    if (_situation == kTHWordsViewControllerDepot) {
      self.navigationItem.rightBarButtonItem = _edit;
    } else if (_situation == kTHWordsViewControllerPlaylist) {
      _rename = custom_item(kRename, UIBarButtonItemStylePlain, self, @selector(renameTapped));
      self.navigationItem.rightBarButtonItems = @[ _edit, _rename ];
    } else {  // THWordsViewControllerAddingToPlaylist
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
  if (_situation == kTHWordsViewControllerPlaylist) {
    self.navigationItem.rightBarButtonItems = @[ _done, _rename ];
  } else {
    self.navigationItem.rightBarButtonItem = _done;
  }
  // if showing a playlist, there are always three items so we don't change it.
  if (_situation != kTHWordsViewControllerPlaylist) {
    [self setToolbarItems:@[ _left, _padding, _middle, _padding, _right ] animated:YES];
  }
}

- (void)endEditing {
  // if showing a playlist, there are always three items so we don't change it.
  if (_situation != kTHWordsViewControllerPlaylist) {
    [self setToolbarItems:@[ _padding, _middle, _padding ] animated:YES];
  }
  if (_situation == kTHWordsViewControllerPlaylist) {
    self.navigationItem.rightBarButtonItems = @[ _edit, _rename ];
  } else {
    self.navigationItem.rightBarButtonItem = _edit;
  }
  [self.tableView setEditing:NO animated:YES];
}

- (void)leftTapped {
  // for "adding to playlist", it is a cancel button.
  if (_situation == kTHWordsViewControllerAddingToPlaylist) {
    [self.navigationController popViewControllerAnimated:NO];
  } else {
    NSString *title;
    if (_situation == kTHWordsViewControllerDepot) {
      title = kRemoveDialogTitleFromDepot;
    } else {  // THWordsViewControllerPlaylist
      if (self.tableView.isEditing) {
        title = remove_dialog_title_from_playlist(_playlist.partialName);
      } else {
        title = remove_dialog_title_normal(_playlist.partialName);
      }
    }
    if ((_situation == kTHWordsViewControllerPlaylist && self.tableView.isEditing) ||
        _situation == kTHWordsViewControllerDepot) {
      // if it is a depot or a non-editing playlist, remove selected.
      NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
      if (!indexPaths.count) {
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

- (void)clearMiddleTaps {
  [lock lock];
  if (_middleSecondTap) {
    [self.navigationController
        presentViewController:
            [self wrapWordDialogAdd:texts_alert(
                                        kWordDialogTitleAdd, nil, @[ @"", @"" ],
                                        @[ kWordDialogKeyTextField, kWordDialogObjectTextField ],
                                        ^(NSArray<UITextField *> *textFields) {
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
                                        })]
                     animated:YES
                   completion:nil];
  }
  _middleSecondTap = NO;
  [lock unlock];
}

- (void)middleTapped {
  if (_situation == kTHWordsViewControllerPlaylist) {
    // if it is showing a playlist, then add words directly or from the depot.
    [lock lock];
    if (_middleSecondTap) {
      _middleSecondTap = NO;
      [self.navigationController
          pushViewController:[[THWordsViewController alloc] initUsingDepotWithPlaylist:_playlist]
                    animated:NO];
    } else {  // it is the first tap
      _middleSecondTap = YES;
      [NSTimer scheduledTimerWithTimeInterval:0.2
                                       target:self
                                     selector:@selector(clearMiddleTaps)
                                     userInfo:nil
                                      repeats:NO];
    }
    [lock unlock];
  } else {
    // otherwise, it means adding a word.
    [self.navigationController
        presentViewController:
            [self wrapWordDialogAdd:texts_alert(
                                        kWordDialogTitleAdd, nil, @[ @"", @"" ],
                                        @[ kWordDialogKeyTextField, kWordDialogObjectTextField ],
                                        ^(NSArray<UITextField *> *textFields) {
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
                                          if (_situation ==
                                              kTHWordsViewControllerAddingToPlaylist) {
                                            [self.tableView
                                                selectRowAtIndexPath:[NSIndexPath
                                                                         indexPathForRow:_nSelected]
                                                            animated:YES
                                                      scrollPosition:UITableViewScrollPositionNone];
                                          }
                                        })]
                     animated:YES
                   completion:nil];
  }
}

- (void)rightTapped {
  if (_situation == kTHWordsViewControllerPlaylist && !self.tableView.isEditing) {
    // if it is a non-editing playlist, go to play.
    [self.navigationController
        presentViewController:basic_alert(play_dialog_title(_playlist.partialName), nil,
                                          ^() {
                                            [self.navigationController
                                                pushViewController:[[THPlayViewController alloc]
                                                                       initWithPlaylist:_playlist]
                                                          animated:YES];
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
    if (!indexSet.count) {
      return;
    }
    if (_situation == kTHWordsViewControllerAddingToPlaylist) {
      [_playlist setObjects:[_objects objectsAtIndexes:indexSet]
                    forKeys:[_keys objectsAtIndexes:indexSet]];
      [self.navigationController popViewControllerAnimated:YES];
    } else {
      [self.navigationController
          presentViewController:
              [self wrapPlaylistDialogAdd:texts_alert(
                                              kPlaylistDialogTitle, nil, @[ @"" ],
                                              @[ kPlaylistDialogTextField ],
                                              ^(NSArray<UITextField *> *texts) {
                                                NSString *partialName = texts.firstObject.text;
                                                THPlaylist *playlist =
                                                    [[THFileCenter sharedInstance]
                                                        playlistWithPartialName:partialName
                                                                         create:YES];
                                                [playlist
                                                    setObjects:[_objects objectsAtIndexes:indexSet]
                                                       forKeys:[_keys objectsAtIndexes:indexSet]];
                                                [self.navigationController
                                                    popToRootViewControllerAnimated:YES];
                                                [(THPlaylistsViewController *)
                                                        self.navigationController.viewControllers
                                                            .firstObject
                                                    showDialogForPlaylist:playlist];
                                              })]
                       animated:YES
                     completion:nil];
    }
  }
}

- (void)renameTapped {
  [self.navigationController
      presentViewController:[self
                                wrapPlaylistDialogRename:texts_alert(
                                                             kRename, nil,
                                                             @[ _playlist.partialName ],
                                                             @[ kPlaylistDialogTextField ],
                                                             ^(NSArray<UITextField *> *textFields) {
                                                               NSString *newPartialName =
                                                                   textFields.firstObject.text;
                                                               [[THFileCenter sharedInstance]
                                                                    renamePlaylist:_playlist
                                                                   withPartialName:newPartialName];
                                                               self.title = newPartialName;
                                                             })]
                   animated:YES
                 completion:nil];
}

- (BOOL)canAddKey:(NSString *)key {
  return ![_fileRW objectForKey:key];
}

- (BOOL)canEditOldKey:(NSString *)oldKey toKey:(NSString *)key {
  return [key isEqualToString:oldKey] || [self canAddKey:key];
}

- (BOOL)canAddPlaylistWithPartialName:(NSString *)partialName {
  return ![[THFileCenter sharedInstance] playlistWithPartialName:partialName create:NO];
}

- (BOOL)canRenamePlaylist:(THPlaylist *)playlist withPartialName:(NSString *)partialName {
  return [playlist.partialName isEqualToString:partialName] ||
         [self canAddPlaylistWithPartialName:partialName];
}

- (void)wordDialogAddTextFieldDidChange {
  UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
  if (alertController) {
    NSString *key = alertController.textFields.firstObject.text;
    NSString *object = [alertController.textFields objectAtIndex:1].text;
    UIAlertAction *action = alertController.actions.lastObject;
    action.enabled = key.length && object.length && [self canAddKey:key];
  }
}

- (void)wordDialogEditTextFieldDidChange {
  UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
  if (alertController) {
    NSString *key = alertController.textFields.firstObject.text;
    NSString *object = [alertController.textFields objectAtIndex:1].text;
    UIAlertAction *action = alertController.actions.lastObject;
    action.enabled = key.length && object.length && [self canEditOldKey:_oldKey toKey:key];
  }
}

- (void)playlistDialogAddTextFieldDidChange {
  UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
  if (alertController) {
    NSString *partialName = alertController.textFields.firstObject.text;
    UIAlertAction *action = alertController.actions.lastObject;
    action.enabled = partialName.length && [self canAddPlaylistWithPartialName:partialName];
  }
}

- (void)playlistDialogRenameTextFieldDidChange {
  UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
  if (alertController) {
    NSString *partialName = alertController.textFields.firstObject.text;
    UIAlertAction *action = alertController.actions.lastObject;
    action.enabled =
        partialName.length && [self canRenamePlaylist:_playlist withPartialName:partialName];
  }
}

- (UIAlertController *)wrapWordDialogAdd:(UIAlertController *)alert {
  alert.actions.lastObject.enabled = NO;
  for (UITextField *textField in alert.textFields) {
    [textField addTarget:self
                  action:@selector(wordDialogAddTextFieldDidChange)
        forControlEvents:UIControlEventEditingChanged];
  }
  return alert;
}

- (UIAlertController *)wrapWordDialogEdit:(UIAlertController *)alert {
  alert.actions.lastObject.enabled = YES;
  for (UITextField *textField in alert.textFields) {
    [textField addTarget:self
                  action:@selector(wordDialogEditTextFieldDidChange)
        forControlEvents:UIControlEventEditingChanged];
  }
  return alert;
}

- (UIAlertController *)wrapPlaylistDialogAdd:(UIAlertController *)alert {
  alert.actions.lastObject.enabled = NO;
  [alert.textFields.firstObject addTarget:self
                                   action:@selector(playlistDialogAddTextFieldDidChange)
                         forControlEvents:UIControlEventEditingChanged];
  return alert;
}

- (UIAlertController *)wrapPlaylistDialogRename:(UIAlertController *)alert {
  alert.actions.lastObject.enabled = YES;
  [alert.textFields.firstObject addTarget:self
                                   action:@selector(playlistDialogRenameTextFieldDidChange)
                         forControlEvents:UIControlEventEditingChanged];
  return alert;
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.toolbarHidden = NO;
  switch (_situation) {
    case kTHWordsViewControllerDepot:
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
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                  reuseIdentifier:kCellIdentifier];
  }
  NSInteger row = indexPath.row;
  cell.textLabel.text = [_keys objectAtIndex:row];
  cell.textLabel.font = cj_regular_small();
  // ...object should change.
  cell.detailTextLabel.text = [_objects objectAtIndex:row];
  cell.detailTextLabel.font = zh_light_small();
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
                   _oldKey = [_keys objectAtIndex:row];
                   // ...object should change.
                   NSString *oldExplanation = [_objects objectAtIndex:row];
                   [self.navigationController
                       presentViewController:
                           [self wrapWordDialogEdit:
                                     texts_alert(
                                         kWordDialogTitleEdit, nil, @[ _oldKey, oldExplanation ],
                                         @[ kWordDialogKeyTextField, kWordDialogObjectTextField ],
                                         ^(NSArray<UITextField *> *textFields) {
                                           NSString *key = textFields.firstObject.text;
                                           NSString *object = [textFields objectAtIndex:1].text;
                                           if (![_oldKey isEqualToString:key]) {
                                             [_fileRW removeObjectForKey:_oldKey];
                                           }
                                           [_fileRW setObject:object forKey:key];
                                           [[THFileCenter sharedInstance] fileRW:_fileRW
                                                                   updatedOldKey:_oldKey
                                                                         withKey:key
                                                                          object:object];
                                           [_keys setObject:key atIndexedSubscript:row];
                                           [_objects setObject:object atIndexedSubscript:row];
                                           [self.tableView
                                               reloadRowsAtIndexPaths:@[ indexPath ]
                                                     withRowAnimation:UITableViewRowAnimationNone];
                                         })]
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
  if (_situation == kTHWordsViewControllerPlaylist ) {
    self.navigationItem.rightBarButtonItems = nil;
  } else {
    self.navigationItem.rightBarButtonItem = nil;
  }
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  if (_situation == kTHWordsViewControllerPlaylist) {
    self.navigationItem.rightBarButtonItems = @[ _edit, _rename ];
  } else {
    self.navigationItem.rightBarButtonItem = _edit;
  }
}

@end

#pragma mark - NSIndexPath (THWordsViewController)

@implementation NSIndexPath (THWordsViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row {
  return [self indexPathForRow:row inSection:0];
}

@end
