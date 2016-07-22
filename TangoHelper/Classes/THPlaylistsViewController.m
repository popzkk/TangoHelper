#import "THPlaylistsViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THPlaylist.h"
#import "Shared/THHelpers.h"
#import "Shared/THStrings.h"
#import "THPlayViewController.h"
#import "THWordsViewController.h"

static NSString *kCellIdentifier = @"PlaylistsViewCell";

static CGFloat kPlaylistHeight = 80;

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
  UIBarButtonItem *_browserDepot;
  UIBarButtonItem *_play;
  UIBarButtonItem *_add;
  UIBarButtonItem *_padding;
}

#pragma mark - public

- (instancetype)init {
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.title = kPlaylistsTitle;

    _padding = system_item(UIBarButtonSystemItemFlexibleSpace, nil, nil);
    _edit = system_item(UIBarButtonSystemItemEdit, self, @selector(startEditing));
    _done = system_item(UIBarButtonSystemItemDone, self, @selector(endEditing));
    _trash = system_item(UIBarButtonSystemItemTrash, self, @selector(trashTapped));
    _browserDepot =
        custom_item(kBrowserDepot, UIBarButtonItemStylePlain, self, @selector(browserDepotTapped));
    _play = system_item(UIBarButtonSystemItemPlay, self, @selector(playTapped));
    _add = system_item(UIBarButtonSystemItemAdd, self, @selector(addTapped));

    self.navigationItem.rightBarButtonItem = _edit;
  }
  return self;
}

- (void)showDialogForPlaylist:(THPlaylist *)playlist {
  [self.navigationController
      presentViewController:basic_alert(play_immediately_dialog_title(playlist.partialName),
                                        kPlayImmediatelyDialogMessage,
                                        ^() {
                                          [self playWithPlaylist:playlist];
                                        })
                   animated:YES
                 completion:nil];
}

#pragma mark - private

- (void)startEditing {
  [self.tableView setEditing:YES animated:YES];
  self.navigationItem.rightBarButtonItem = _done;
  [self setToolbarItems:@[ _trash, _padding, _play ] animated:YES];
}

- (void)endEditing {
  [self setToolbarItems:@[ _browserDepot, _padding, _add ] animated:YES];
  self.navigationItem.rightBarButtonItem = _edit;
  [self.tableView setEditing:NO animated:YES];
}

- (void)trashTapped {
  NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
  if (!indexPaths) {
    return;
  }
  [self.navigationController
      presentViewController:basic_alert(
                                kRemoveDialogTitleFromPlaylists, nil,
                                ^() {
                                  NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
                                  for (NSIndexPath *indexPath in indexPaths) {
                                    [indexSet addIndex:indexPath.row];
                                    [[THFileCenter sharedInstance]
                                        deletePlaylist:[_playlists objectAtIndex:indexPath.row]];
                                  }
                                  [_playlists removeObjectsAtIndexes:indexSet];
                                  [self.tableView
                                      deleteRowsAtIndexPaths:indexPaths
                                            withRowAnimation:UITableViewRowAnimationNone];
                                })
                   animated:YES
                 completion:nil];
}

- (void)browserDepotTapped {
  [self.navigationController pushViewController:[[THWordsViewController alloc] initUsingDepot]
                                       animated:YES];
}

- (void)addTapped {
  [self.navigationController
      presentViewController:texts_alert(
                                kPlaylistDialogTitle, nil, @[ @"" ], @[ kPlaylistDialogTextField ],
                                ^(NSArray<UITextField *> *texts) {
                                  // check if valid.
                                  NSString *partialName = texts.firstObject.text;
                                  THPlaylist *playlist =
                                      [self newPlaylistWithPartialName:partialName atRow:0];
                                  [self.navigationController
                                      pushViewController:[[THWordsViewController alloc]
                                                             initUsingDepotWithPlaylist:playlist]
                                                animated:NO];
                                })
                   animated:YES
                 completion:nil];
}

- (void)playTapped {
  [self.navigationController
      presentViewController:texts_alert(
                                kPlaylistDialogTitle, nil, @[ @"" ], @[ kPlaylistDialogTextField ],
                                ^(NSArray<UITextField *> *texts) {
                                  // check if valid.
                                  NSString *partialName = texts.firstObject.text;
                                  THPlaylist *playlist =
                                      [self newPlaylistWithPartialName:partialName atRow:0];
                                  for (NSIndexPath *indexPath in self.tableView
                                           .indexPathsForSelectedRows) {
                                    [playlist
                                        addFromFileRW:[_playlists objectAtIndex:indexPath.row]];
                                  }
                                  [self.navigationController
                                      presentViewController:basic_alert(
                                                                kPlayDialogTitle, nil,
                                                                ^() {
                                                                  [self playWithPlaylist:playlist];
                                                                })
                                                   animated:YES
                                                 completion:nil];
                                })
                   animated:YES
                 completion:nil];
}

- (THPlaylist *)newPlaylistWithPartialName:(NSString *)partialName atRow:(NSUInteger)row {
  THPlaylist *playlist =
      [[THFileCenter sharedInstance] playlistWithPartialName:partialName create:YES];
  [_playlists insertObject:playlist atIndex:0];
  [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0] ]
                        withRowAnimation:UITableViewRowAnimationNone];
  return playlist;
}

- (void)playWithPlaylist:(THPlaylist *)playlist {
  // NSLog(@"Will play: %@", playlist.partialName);
  [self.navigationController
      pushViewController:[[THPlayViewController alloc] initWithPlaylist:playlist]
                animated:YES];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
  self.navigationController.toolbarHidden = NO;
  self.toolbarItems = @[ _browserDepot, _padding, _add ];
  _playlists = [[THFileCenter sharedInstance] playlists];
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
  THPlaylist *playlist = [_playlists objectAtIndex:indexPath.row];
  cell.textLabel.text = playlist.partialName;
  // cell.textLabel.font = [UIFont fontWithName:@"" size:24];
  cell.detailTextLabel.text = playlist.desc;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kPlaylistHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView.isEditing) {
    return;
  }
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  THPlaylist *playlist = [_playlists objectAtIndex:indexPath.row];
  [self.navigationController
      presentViewController:basic_alert(play_dialog_title(playlist.partialName), nil,
                                        ^() {
                                          [self playWithPlaylist:playlist];
                                        })
                   animated:YES
                 completion:nil];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
#ifndef RENAME_IN_SWIPE
  UITableViewRowAction *play = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kPlay
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   [self playWithPlaylist:[_playlists objectAtIndex:indexPath.row]];
                 }];
  play.backgroundColor = [UIColor brownColor];
#endif

  UITableViewRowAction *view = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kView
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   [self.navigationController
                       pushViewController:[[THWordsViewController alloc]
                                              initWithPlaylist:[_playlists
                                                                   objectAtIndex:indexPath.row]]
                                 animated:YES];
                 }];
#ifdef RENAME_IN_SWIPE
  view.backgroundColor = [UIColor brownColor];
#else
  view.backgroundColor = [UIColor lightGrayColor];
#endif

#ifdef RENAME_IN_SWIPE
  UITableViewRowAction *rename = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kRename
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   THPlaylist *playlist = [_playlists objectAtIndex:indexPath.row];
                   [self.navigationController
                       presentViewController:texts_alert(
                                                 kRename, nil, @[ playlist.partialName ], @[ @"" ],
                                                 ^(NSArray<UITextField *> *textFields) {
                                                   // ...check if valid.
                                                   NSString *newPartialName =
                                                       textFields.firstObject.text;
                                                   [[THFileCenter sharedInstance]
                                                        renamePlaylist:playlist
                                                       withPartialName:newPartialName];
                                                   UITableViewCell *cell =
                                                       [tableView cellForRowAtIndexPath:indexPath];
                                                   cell.textLabel.text = newPartialName;
                                                   // ...how to exit the editing state?
                                                 })
                                    animated:YES
                                  completion:nil];
                 }];
  rename.backgroundColor = [UIColor lightGrayColor];
#endif

  UITableViewRowAction *remove = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kRemove
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   NSUInteger row = indexPath.row;
                   THPlaylist *playlist = [_playlists objectAtIndex:row];
                   [self.navigationController
                       presentViewController:
                           basic_alert(remove_dialog_title_normal(playlist.partialName), nil,
                                       ^() {
                                         [[THFileCenter sharedInstance] deletePlaylist:playlist];
                                         [_playlists removeObjectAtIndex:row];
                                         [self.tableView
                                             deleteRowsAtIndexPaths:@[ indexPath ]
                                                   withRowAnimation:UITableViewRowAnimationNone];
                                       })
                                    animated:YES
                                  completion:nil];
                 }];
  remove.backgroundColor = [UIColor redColor];

#ifdef RENAME_IN_SWIPE
  return @[ remove, rename, view ];
#endif
  return @[ remove, view, play ];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  self.navigationItem.rightBarButtonItem = nil;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  self.navigationItem.rightBarButtonItem = _edit;
}

@end

#pragma mark - NSIndexPath (THPlaylistsViewController)

@implementation NSIndexPath (THPlaylistsViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row {
  return [self indexPathForRow:row inSection:0];
}

@end
