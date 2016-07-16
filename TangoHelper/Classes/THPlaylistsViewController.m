#import "THPlaylistsViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THPlaylist.h"
#import "Shared/THStrings.h"
#import "THWordsViewController.h"

typedef void (^THRemoveConfirmAction)();
typedef void (^THPlayConfirmAction)();
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
  UIBarButtonItem *_left;
  UIBarButtonItem *_middle;
  UIBarButtonItem *_right;
  UIBarButtonItem *_padding;
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
    _left = [[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
             target:self
             action:@selector(leftTapped)];
    _middle = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                            target:self
                                                            action:@selector(middleTapped)];
    _right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                           target:self
                                                           action:@selector(rightTapped)];
  }
  return self;
}

- (void)showDialogForPlaylist:(THFileRW *)playlist {

}

#pragma mark - private

- (void)startEditing {
  [self.tableView setEditing:YES animated:YES];
  self.navigationItem.rightBarButtonItem = _done;
  [self setToolbarItems:@[ _left, _padding, _right ] animated:YES];
}

- (void)endEditing {
  [self setToolbarItems:@[ _padding, _middle, _padding ] animated:YES];
  self.navigationItem.rightBarButtonItem = _edit;
  [self.tableView setEditing:NO animated:YES];
}

- (void)leftTapped {
  NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
  if (!indexPaths) {
    return;
  }
  [self showRemoveDialogWithBlock:^() {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *indexPath in indexPaths) {
      [indexSet addIndex:indexPath.row];
      [[THFileCenter sharedInstance] deletePlaylist:[_playlists objectAtIndex:indexPath.row]];
    }
    [_playlists removeObjectsAtIndexes:indexSet];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
  }];
}

- (void)middleTapped {
}

- (void)rightTapped {

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

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
  self.toolbarItems = @[ _padding, _middle, _padding ];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  cell = [cell initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellIdentifier];
  THPlaylist *playlist = [_playlists objectAtIndex:indexPath.row];
  cell.textLabel.text = [playlist particialName];
  //cell.textLabel.font = [UIFont fontWithName:@"" size:24];
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
  return @[ remove, edit, recite ];
}

@end

#pragma mark - NSIndexPath (THPlaylistsViewController)

@implementation NSIndexPath (THPlaylistsViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row {
  return [self indexPathForRow:row inSection:0];
}

@end
