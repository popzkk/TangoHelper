#import "THWordsViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THDepot.h"
#import "Backend/THPlaylist.h"
#import "Shared/THStrings.h"
#import "THPlaylistsViewController.h"

/** TODO
 * save selected rows when switched out.
 * edit the table when a cell is being editted?
 */

typedef void (^THRemoveConfirmAction)();
typedef void (^THWordConfirmAction)(NSString *, id);

static NSString *kCellIdentifier = @"WordsViewCell";

@interface NSIndexPath (THWordsViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row;

@end

#pragma mark - THWordsViewController

@interface THWordsViewController ()<UITableViewDataSource, UITableViewDelegate>

@end

@implementation THWordsViewController {
  THDepot *_depot;
  THPlaylist *_playlist;
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

  NSIndexPath *_current;
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

- (instancetype)initWithDepot:(THDepot *)depot playlist:(THPlaylist *)playlist {
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    _depot = depot;
    _playlist = playlist;
    if (_depot && !_playlist) {
      _fileRW = _depot;
      _keys = [_depot allKeys];
      _objects = [_depot objectsForKeys:_keys];
      _nSelected = 0;
      self.title = kTitleDepot;
    } else if (!_depot && _playlist) {
      _fileRW = _playlist;
      _keys = [_playlist allKeys];
      _objects = [_playlist objectsForKeys:_keys];
      _nSelected = 0;
      self.title = [NSString stringWithFormat:kTitlePlaylist, [_playlist partialName]];
    } else if (_depot && _playlist) {
      _fileRW = _depot;
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
      self.title = [NSString stringWithFormat:kTitleAddWords, [_playlist partialName]];
    } else {
      NSLog(@"both depot and playlist are nil!");
      return nil;
    }

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    _padding =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];
    _edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                          target:self
                                                          action:@selector(startEditing)];
    _done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                          target:self
                                                          action:@selector(endEditing)];
    _left = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:_depot && _playlist ? UIBarButtonSystemItemCancel
                                                        : UIBarButtonSystemItemTrash
                             target:self
                             action:@selector(leftTapped)];
    _middle = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                            target:self
                                                            action:@selector(middleTapped)];
    _right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                           target:self
                                                           action:@selector(rightTapped)];
    if (!_depot || !_playlist) {
      self.navigationItem.rightBarButtonItem = _edit;
    } else {
      self.navigationItem.hidesBackButton = YES;
      self.tableView.editing = YES;
      for (NSUInteger i = 0; i < _nSelected; ++i) {
        // ...probably move to viewDidLoad:
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i]
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_nSelected]
                              atScrollPosition:UITableViewScrollPositionNone
                                      animated:NO];
      }
    }
  }
  return self;
}

- (void)startEditing {
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_current];
  if (cell.editing) {
    return;
  }
  [self.tableView setEditing:YES animated:YES];
  self.navigationItem.rightBarButtonItem = _done;
  [self setToolbarItems:@[ _left, _padding, _middle, _padding, _right ] animated:YES];
}

- (void)endEditing {
  [self setToolbarItems:@[ _padding, _middle, _padding ] animated:YES];
  self.navigationItem.rightBarButtonItem = _edit;
  [self.tableView setEditing:NO animated:YES];
}

- (void)leftTapped {
  if (_depot && _playlist) {
    [self.navigationController popViewControllerAnimated:NO];
  } else {
    NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
    if (!indexPaths) {
      return;
    }
    [self showRemoveDialogWithBlock:^() {
      // _nSelected must be 0.
      NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
      for (NSIndexPath *indexPath in indexPaths) {
        [indexSet addIndex:indexPath.row];
      }
      NSArray *keys = [_keys objectsAtIndexes:indexSet];
      for (NSString *key in keys) {
        [_fileRW removeObjectForKey:key];
      }
      [_keys removeObjectsAtIndexes:indexSet];
      [_objects removeObjectsAtIndexes:indexSet];
      [self.tableView deleteRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }];
  }
}

- (void)middleTapped {
  if (!_depot && _playlist) {
    [self.navigationController
        pushViewController:[[THWordsViewController alloc] initUsingDepotWithPlaylist:_playlist]
                  animated:YES];
  } else {
    [self showWordDialogWithBlock:^(NSString *key, id object) {
      [_fileRW setObject:object forKey:key];
      [_keys insertObject:key atIndex:_nSelected];
      [_objects insertObject:object atIndex:_nSelected];
      [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:_nSelected] ]
                            withRowAnimation:UITableViewRowAnimationNone];
    }
                              key:nil
                      explanation:nil];
  }
}

- (void)rightTapped {
  if (!_depot || !_playlist) {
    NSLog(@"right tapped");
  } else {
    NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
    if (indexPaths.count <= _nSelected) {
      return;
    }
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *indexPath in indexPaths) {
      if (indexPath.row > _nSelected) {
        [indexSet addIndex:indexPath.row];
      }
    }
    [_playlist setObjects:[_objects objectsAtIndexes:indexSet]
                  forKeys:[_keys objectsAtIndexes:indexSet]];
    [self.navigationController popViewControllerAnimated:YES];
  }
}

- (void)showRemoveDialogWithBlock:(THRemoveConfirmAction)block {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:kRemoveDialogTitle
                                          message:@""
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert
      addAction:[UIAlertAction actionWithTitle:kCancel style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:kConfirm
                                            style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                            block();
                                          }]];
  [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void)showWordDialogWithBlock:(THWordConfirmAction)block
                            key:(NSString *)key
                    explanation:(NSString *)explanation {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:kWordDialogTitle
                                          message:@""
                                   preferredStyle:UIAlertControllerStyleAlert];

  [alert
      addAction:[UIAlertAction actionWithTitle:kCancel style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:kConfirm
                                            style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                            NSString *key = alert.textFields.firstObject.text;
                                            // ...object should change.
                                            id object = [alert.textFields objectAtIndex:1].text;
                                            // ...check these two fields are valid.
                                            block(key, object);
                                          }]];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    if (!key || key.length == 0) {
      textField.placeholder = kWordKeyTextField;
    } else {
      textField.text = key;
    }
  }];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    if (!explanation || explanation.length == 0) {
      textField.placeholder = kWordObjectTextField;
    } else {
      textField.text = explanation;
    }
  }];
  [self.navigationController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
  if (!_depot || !_playlist) {
    self.toolbarItems = @[ _padding, _middle, _padding ];
  } else {
    self.toolbarItems = @[ _left, _padding, _middle, _padding, _right ];
  }
  // ... refresh dataSource.
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  cell = [cell initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellIdentifier];
  NSInteger row = indexPath.row;
  cell.textLabel.text = [_keys objectAtIndex:row];
  cell.textLabel.font = [UIFont fontWithName:@"" size:24];
  // ...object should change.
  cell.detailTextLabel.text = [_objects objectAtIndex:row];
  if (indexPath.row < _nSelected) {
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
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
                   [self showWordDialogWithBlock:^(NSString *key, id object) {
                     if (![oldKey isEqualToString:key]) {
                       [_fileRW removeObjectForKey:oldKey];
                     }
                     [_fileRW setObject:object forKey:key];
                     [_keys setObject:key atIndexedSubscript:row];
                     [_objects setObject:object atIndexedSubscript:row];
                     [self.tableView rectForRowAtIndexPath:indexPath];
                   }
                                             key:oldKey
                                     explanation:[_objects
                                                     objectAtIndex:row]];  // ...object will change.
                 }];
  UITableViewRowAction *remove = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kRemove
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   NSUInteger row = indexPath.row;
                   [self showRemoveDialogWithBlock:^() {
                     [_fileRW removeObjectForKey:[_keys objectAtIndex:row]];
                     [_keys removeObjectAtIndex:row];
                     [_objects removeObjectAtIndex:row];
                     [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                           withRowAnimation:UITableViewRowAnimationNone];
                   }];
                 }];
  remove.backgroundColor = [UIColor redColor];
  return @[ remove, edit ];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  _current = indexPath;
}

@end

#pragma mark - NSIndexPath (THWordsViewController)

@implementation NSIndexPath (THWordsViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row {
  return [self indexPathForRow:row inSection:0];
}

@end
