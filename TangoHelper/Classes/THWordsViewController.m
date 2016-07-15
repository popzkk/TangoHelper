#import "THWordsViewController.h"
#import "Backend/THFileRW.h"
#import "Shared/THStrings.h"

typedef void (^THRemoveConfirmAction)(UIAlertAction *);
typedef void (^THWordConfirmAction)(NSString *, id, UIAlertAction *);

static NSString *kCellIdentifier = @"WordsViewCell";

@interface THWordsViewController ()<UITableViewDataSource, UITableViewDelegate>

@end

@implementation THWordsViewController {
  THFileRW *_depot;
  THFileRW *_playlist;
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

- (instancetype)initWithPlaylist:(THFileRW *)playlist {
  return [self initWithDepot:nil playlist:playlist];
}

- (instancetype)initUsingDepotWithPlaylist:(THFileRW *)playlist {
  return [self initWithDepot:[THFileRW instanceForFilename:@"test.depot" create:YES]
                    playlist:playlist];
}

#pragma mark - private

- (instancetype)initWithDepot:(THFileRW *)depot playlist:(THFileRW *)playlist {
  self = [super init];
  if (self) {
    _depot = depot;
    _playlist = playlist;
    if (_depot && !_playlist) {
      _keys = [NSMutableArray arrayWithArray:[_depot allKeys]];
      _objects = [NSMutableArray arrayWithArray:[_depot objectsForKeys:_keys]];
      _nSelected = 0;
    } else if (!_depot && _playlist) {
      _keys = [NSMutableArray arrayWithArray:[_playlist allKeys]];
      _objects = [NSMutableArray arrayWithArray:[_playlist objectsForKeys:_keys]];
      _nSelected = 0;
    } else if (_depot && _playlist) {
      NSMutableArray *keys = [NSMutableArray arrayWithArray:[_playlist allKeys]];
      _nSelected = keys.count;
      NSMutableArray *objects = [NSMutableArray arrayWithArray:[_playlist objectsForKeys:keys]];
      NSArray *tmpKeys = [_depot allKeys];
      for (NSString *key in tmpKeys) {
        id object = [_playlist objectForKey:key];
        if (!object) {
          [keys addObject:key];
          [objects addObject:object];
        }
      }
      _keys = keys;
      _objects = objects;
    } else {
      NSLog(@"both depot and playlist are nil!");
      return nil;
    }

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.title = kTitleDepot;

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
      self.tableView.editing = YES;
      for (NSUInteger i = 0; i < _nSelected; ++i) {
        // ...config a different style. probably move to viewDidLoad:
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_nSelected inSection:0]
                              atScrollPosition:UITableViewScrollPositionNone animated:NO];
      }
    }
  }
  return self;
}

- (void)startEditing {
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
  NSLog(@"left tapped");
  if (_depot && _playlist) {
    // ...dismiss self.
  } else {
    NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
    if (!indexPaths) {
      return;
    }
    [self showRemoveDialogWithBlock:^(UIAlertAction *action) {
      // _nSelected must be 0.
      NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
      for (NSIndexPath *indexPath in indexPaths) {
        [indexSet addIndex:indexPath.row];
      }
      NSArray *keys = [_keys objectsAtIndexes:indexSet];
      for (NSString *key in keys) {
        if (_depot) {
          [_depot removeObjectForKey:key];
        } else {
          [_playlist removeObjectForKey:key];
        }
      }
      [_keys removeObjectsAtIndexes:indexSet];
      [_objects removeObjectsAtIndexes:indexSet];
      [self.tableView deleteRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }];
  }
}

- (void)middleTapped {
  // middle is always add.
  [self showWordDialogWithBlock:^(NSString *key, id object, UIAlertAction *action) {
    NSLog(@"Will add %@:%@", key, object);
    if (_depot) {
      [_depot setObject:object forKey:key];
    } else {
      [_playlist setObject:object forKey:key];
    }
    [_keys insertObject:key atIndex:_nSelected];
    [_objects insertObject:object atIndex:_nSelected];
    [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:_nSelected inSection:0] ]
                     withRowAnimation:UITableViewRowAnimationNone];
  } key:nil explanation:nil];
}

- (void)rightTapped {
  NSLog(@"right tapped");
}

- (void)showRemoveDialogWithBlock:(THRemoveConfirmAction)block {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:kRemoveDialogTitle
                                          message:@""
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancel = [UIAlertAction actionWithTitle:kCancel
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  UIAlertAction *confirm = [UIAlertAction actionWithTitle:kConfirm
                                                    style:UIAlertActionStyleDestructive
                                                  handler:^(UIAlertAction *action) {
                                                    block(action);
                                                  }];
  [alert addAction:cancel];
  [alert addAction:confirm];
  [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (void)showWordDialogWithBlock:(THWordConfirmAction)block
                            key:(NSString *)key
                    explanation:(NSString *)explanation {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:kWordDialogTitle
                                          message:@""
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancel = [UIAlertAction actionWithTitle:kCancel
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil];
  UIAlertAction *confirm =
      [UIAlertAction actionWithTitle:kConfirm
                               style:UIAlertActionStyleDestructive
                             handler:^(UIAlertAction *action) {
                               NSString *key = alert.textFields.firstObject.text;
                               // ...object should change.
                               id object = [alert.textFields objectAtIndex:1].text;
                               // check these two fields are not nil.
                               block(key, object, action);
                             }];
  [alert addAction:cancel];
  [alert addAction:confirm];
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
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _keys.count;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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
                   title:kViewEdit
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   NSLog(@"edit at %ld", (long)indexPath.row);
                 }];
  UITableViewRowAction *remove = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kRemove
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   NSLog(@"will remove %ld", (long)indexPath.row);
                 }];
  remove.backgroundColor = [UIColor redColor];
  return @[ remove, edit ];
}

@end
