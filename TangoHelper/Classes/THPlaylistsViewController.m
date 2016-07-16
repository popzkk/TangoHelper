#import "THPlaylistsViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THPlaylist.h"
#import "Shared/THStrings.h"
#import "THWordsViewController.h"

typedef void (^THBasicConfirmAction)();
typedef void (^THPlaylistConformAction)(NSString *);

static NSString *kCellIdentifier = @"PlaylistsViewCell";

@interface NSIndexPath (THPlaylistsViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row;

@end

#pragma mark - THPlaylistsViewController

@interface THPlaylistsViewController ()<UITableViewDataSource, UITableViewDelegate>

@end

@implementation THPlaylistsViewController {
  NSMutableArray *_playlists;

  UIBarButtonItem *_edit;
  UIBarButtonItem *_done;
  UIBarButtonItem *_trash;
  UIBarButtonItem *_toDepot;
  UIBarButtonItem *_play;
  UIBarButtonItem *_add;
  UIBarButtonItem *_padding;

  NSIndexPath *_current;
}

#pragma mark - public

- (instancetype)init {
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    _playlists = [[THFileCenter sharedInstance] playlists];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.title = kTitlePlaylists;

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
    _trash = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                           target:self
                                                           action:@selector(trashTapped)];
    _toDepot = [[UIBarButtonItem alloc] initWithTitle:kToDepot
                                                style:UIBarButtonItemStylePlain
                                               target:self
                                               action:@selector(toDepotTapped)];
    _play = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                          target:self
                                                          action:@selector(playTapped)];
    _add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                         target:self
                                                         action:@selector(addTapped)];
    self.navigationItem.rightBarButtonItem = _edit;
  }
  return self;
}

- (void)showDialogForPlaylist:(THFileRW *)playlist {
}

#pragma mark - private

- (void)startEditing {
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_current];
  if (cell.editing) {
    return;
  }
  [self.tableView setEditing:YES animated:YES];
  self.navigationItem.rightBarButtonItem = _done;
  [self setToolbarItems:@[ _trash, _padding, _play ] animated:YES];
}

- (void)endEditing {
  [self setToolbarItems:@[ _toDepot, _padding, _add ] animated:YES];
  self.navigationItem.rightBarButtonItem = _edit;
  [self.tableView setEditing:NO animated:YES];
}

- (void)trashTapped {
  NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
  if (!indexPaths) {
    return;
  }
  [self showBasicDialogWithBlock:^() {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *indexPath in indexPaths) {
      [indexSet addIndex:indexPath.row];
      [[THFileCenter sharedInstance] deletePlaylist:[_playlists objectAtIndex:indexPath.row]];
    }
    [_playlists removeObjectsAtIndexes:indexSet];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
  }];
}

- (void)toDepotTapped {
  [self.navigationController pushViewController:[[THWordsViewController alloc] initUsingDepot]
                                       animated:YES];
}

- (void)addTapped {
  [self showPlaylistDialogWithBlock:^(NSString *partialName) {
    THPlaylist *playlist =
        [[THFileCenter sharedInstance] playlistWithPartialName:partialName create:YES];
    [_playlists insertObject:playlist atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0] ]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.navigationController
        pushViewController:[[THWordsViewController alloc] initUsingDepotWithPlaylist:playlist]
                  animated:NO];
  }];
}

- (void)playTapped {
  NSLog(@"right tapped");
}

- (void)showBasicDialogWithBlock:(THBasicConfirmAction)block {
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

- (void)showPlaylistDialogWithBlock:(THPlaylistConformAction)block {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:kPlaylistDialogTitle
                                          message:@""
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert
      addAction:[UIAlertAction actionWithTitle:kCancel style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:kConfirm
                                            style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                            NSString *partialName =
                                                alert.textFields.firstObject.text;
                                            // ...check if valid.
                                            block(partialName);
                                          }]];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = kPlaylistTextField;
  }];
  [self.navigationController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
  self.toolbarItems = @[ _toDepot, _padding, _add ];
  // ...refresh dataSource.
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  cell = [cell initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellIdentifier];
  THPlaylist *playlist = [_playlists objectAtIndex:indexPath.row];
  cell.textLabel.text = [playlist partialName];
  // cell.textLabel.font = [UIFont fontWithName:@"" size:24];
  cell.detailTextLabel.text = [playlist desc];
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _playlists.count;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - UITableViewDelegate

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewRowAction *recite = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kRecite
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   NSLog(@"recite at %ld", (long)indexPath.row);
                 }];
  recite.backgroundColor = [UIColor brownColor];
  UITableViewRowAction *edit = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kEdit
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   [self.navigationController
                       pushViewController:[[THWordsViewController alloc]
                                              initWithPlaylist:[_playlists
                                                                   objectAtIndex:indexPath.row]]
                                 animated:YES];
                 }];
  UITableViewRowAction *remove = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kRemove
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   NSUInteger row = indexPath.row;
                   THPlaylist *playlist = [_playlists objectAtIndex:row];
                   [self showBasicDialogWithBlock:^() {
                     [[THFileCenter sharedInstance] deletePlaylist:playlist];
                     [_playlists removeObjectAtIndex:row];
                     [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                           withRowAnimation:UITableViewRowAnimationNone];
                   }];
                 }];
  remove.backgroundColor = [UIColor redColor];
  return @[ remove, edit, recite ];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  _current = indexPath;
}

@end

#pragma mark - NSIndexPath (THPlaylistsViewController)

@implementation NSIndexPath (THPlaylistsViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row {
  return [self indexPathForRow:row inSection:0];
}

@end
