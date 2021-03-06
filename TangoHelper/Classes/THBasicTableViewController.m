#import "THBasicTableViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THMetadata.h"
#import "Backend/THPlaylist.h"
#import "Shared/THHelpers.h"
#import "Shared/THStrings.h"
#import "THPlayViewController.h"
#import "THPlaylistsViewController.h"

static CGFloat kSearchBarHeight = 40;

#pragma mark - THBasicTableViewController

@implementation THBasicTableViewController {
  // only the intersect set makes sense!
  NSMutableSet *_selectedItems;
  BOOL _searchControllerWillDismiss;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
                        title:(NSString *)title
                 searchString:(NSString *)searchString
                  cancelBlock:(THTableViewCancelBlock)cancelBlock
                 confirmBlock:(THTableViewConfirmBlock)confirmBlock {
  self = [super initWithStyle:style];
  if (self) {
    _cancelBlock = cancelBlock;
    _confirmBlock = confirmBlock;
    _barItemEdit = system_item(UIBarButtonSystemItemEdit, self, @selector(didTapBarItemEdit));
    _barItemDone = system_item(UIBarButtonSystemItemDone, self, @selector(didTapBarItemDone));
    _barItemTrash = system_item(UIBarButtonSystemItemTrash, self, @selector(didTapBarItemTrash));
    _barItemAdd = system_item(UIBarButtonSystemItemAdd, self, @selector(didTapBarItemAdd));
    _barItemPlay = system_item(UIBarButtonSystemItemPlay, self, @selector(didTapBarItemPlay));
    _barItemAction = system_item(UIBarButtonSystemItemAction, self, @selector(didTapBarItemAction));
    _barItemCancel = system_item(UIBarButtonSystemItemCancel, self, @selector(didTapBarItemCancel));
    _barItemPadding = system_item(UIBarButtonSystemItemFlexibleSpace, nil, nil);
    if (title) {
      self.title = title;
    }
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    if (_confirmBlock) {
      self.tableView.editing = YES;
      self.navigationItem.hidesBackButton = YES;
      _rightItemsEditing = @[ _barItemAction ];
      _bottomItemsEditing = @[ _barItemCancel, _barItemPadding, _barItemPlay ];
    }
    self.tableView.sectionHeaderHeight = kSearchBarHeight;
    _selectedItems = [NSMutableSet set];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.delegate = self;
    _searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _searchController.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    _searchController.searchBar.delegate = self;
    [_searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = _searchController.searchBar;
    if (searchString.length) {
      _searchString = [searchString copy];
      _searchController.searchBar.text = _searchString;
    }
  }
  return self;
}

#if (DEBUG)
- (void)dealloc {
  NSLog(@"dealloc: %@", self);
}
#endif

- (NSString *)customizedTitle {
  return nil;
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (self.tableView.editing) {
    self.navigationItem.rightBarButtonItems = self.rightItemsEditing;
    self.toolbarItems = self.bottomItemsEditing;
  } else {
    self.navigationItem.rightBarButtonItems = self.rightItems;
    self.toolbarItems = self.bottomItems;
  }
  self.navigationController.toolbarHidden = _searchString.length > 0;
  [_model reload];
  if (_searchString.length) {
    [_model filterContentWithString:_searchString ignoresEmptyString:YES];
  } else {
    [self.tableView reloadData];
  }
  if (self.tableView.editing) {
    [self recoverSelections];
  }
  [self updateTitle];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  _searchController.active = NO;
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
  _searchControllerWillDismiss = NO;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
  _searchControllerWillDismiss = YES;
  _searchString = searchController.searchBar.text;
  self.navigationController.toolbarHidden = _searchString.length > 0;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
  searchController.searchBar.text = _searchString;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
  [_model filterContentWithString:searchController.searchBar.text
               ignoresEmptyString:_searchControllerWillDismiss];
  [self recoverSelections];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:_cellStyle reuseIdentifier:_cellIdentifier];
  }
  NSInteger row = indexPath.row;
  cell.textLabel.text = [_model textAtRow:row];
  if (_textLabelFont) {
    cell.textLabel.font = _textLabelFont;
  }
  cell.detailTextLabel.text = [_model detailTextAtRow:row];
  if (_detailTextLabelFont) {
    cell.detailTextLabel.font = _detailTextLabelFont;
  }
  if (_detailTextLabelColor) {
    cell.detailTextLabel.textColor = _detailTextLabelColor;
  }

  // ...config a different style for pre-selected
  if ([self preSelectRow:row]) {
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  }

  if ([_model respondsToSelector:@selector(accessibilityLabelAtRow:)]) {
    cell.accessibilityLabel = [_model accessibilityLabelAtRow:row];
  }
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_model numberOfRows];
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self preSelectRow:indexPath.row]) {
    cell.selected = YES;
  }
}

- (NSIndexPath *)tableView:(UITableView *)tableView
    willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self preSelectRow:indexPath.row]) {
    return nil;
  } else {
    return indexPath;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [_selectedItems addObject:[_model itemAtRow:indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  [_selectedItems removeObject:[_model itemAtRow:indexPath.row]];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewRowAction *remove = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kRemove
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   NSUInteger row = indexPath.row;
                   [self showAlert:dialog_remove_item(
                                       [self.tableView cellForRowAtIndexPath:indexPath]
                                           .textLabel.text,
                                       ^{
                                         [_model remove:[NSIndexSet indexSetWithIndex:row]];
                                       })];
                 }];
  remove.backgroundColor = [UIColor redColor];

  UITableViewRowAction *modify =
      [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                         title:[self rowActionTitleModify]
                                       handler:[self rowActionHandlerModify]];
  modify.backgroundColor = [UIColor lightGrayColor];

  UITableViewRowAction *info = [UITableViewRowAction
      rowActionWithStyle:UITableViewRowActionStyleNormal
                   title:kInfo
                 handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                   [self showAlert:dialog_more_info([_model infoOfRow:indexPath.row])];
                 }];
  info.backgroundColor = [UIColor brownColor];

  return @[ remove, modify, info ];
}

- (NSString *)rowActionTitleModify {
#if (DEBUG)
  NSLog(@"WARNING: %@ should be implemented by subclasses", NSStringFromSelector(_cmd));
#endif
  return @"Modify";
}

- (THTableViewRowActionHandler)rowActionHandlerModify {
  return ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
    NSLog(@"WARNING: %@ should be implemented by subclasses", NSStringFromSelector(_cmd));
  };
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  self.navigationItem.rightBarButtonItems = nil;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  self.navigationItem.rightBarButtonItems = _rightItems;
}

#pragma mark - THTableViewModelDelegate

- (void)globalCheckFailedWithHints:(NSArray<NSString *> *)hints
                    positiveAction:(THAlertBasicAction)positiveAction {
  NSLog(@"WARNING: %@ should be implemented by subclasses", NSStringFromSelector(_cmd));
}

- (void)modelDidAddAtRow:(NSUInteger)row {
  [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:row] ]
                        withRowAnimation:UITableViewRowAnimationNone];
  [self updateTitle];
}

- (void)modelDidRemoveRows:(NSIndexSet *)rows {
  NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray arrayWithCapacity:rows.count];
  [rows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    [indexPaths addObject:[NSIndexPath indexPathForRow:idx]];
  }];
  [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
  [self updateTitle];
}

- (void)modelDidModifyAtRow:(NSUInteger)row {
  [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:row] ]
                        withRowAnimation:UITableViewRowAnimationNone];
}

- (void)modelDidGetUpdated {
  [self.tableView reloadData];
  [self updateTitle];
}

#pragma mark - UIBarButtonItem actions

- (void)didTapBarItemEdit {
  self.navigationItem.rightBarButtonItems = self.rightItemsEditing;
  [self setToolbarItems:self.bottomItemsEditing animated:YES];
  [self.tableView setEditing:YES animated:YES];
  [self recoverSelections];
}

- (void)didTapBarItemDone {
  [self.tableView setEditing:NO animated:YES];
  [self setToolbarItems:self.bottomItems animated:YES];
  self.navigationItem.rightBarButtonItems = self.rightItems;
}

- (void)didTapBarItemTrash {
  if (self.tableView.editing) {
    NSArray<NSIndexPath *> *selectIndexPaths = self.tableView.indexPathsForSelectedRows;
    if (!selectIndexPaths.count) {
      return;
    }
    [self showAlert:dialog_remove_selected(^{
            [self.model remove:index_set_from_index_paths(selectIndexPaths)];
          })];
  } else {
    NSLog(@"WARNING: %@ should be implemented by subclasses", NSStringFromSelector(_cmd));
  }
}

- (void)didTapBarItemAdd {
  NSLog(@"WARNING: %@ should be implemented by subclasses", NSStringFromSelector(_cmd));
}

- (void)didTapBarItemPlay {
  NSArray<NSIndexPath *> *selectedIndexPaths = self.tableView.indexPathsForSelectedRows;
  if (self.tableView.editing && !selectedIndexPaths.count) {
    return;
  }
  NSIndexSet *selectedIndexSet = index_set_from_index_paths(selectedIndexPaths);
  if (_confirmBlock) {
    _confirmBlock([_model itemsAtRows:selectedIndexSet]);
    [self.navigationController popViewControllerAnimated:YES];
  } else if (self.tableView.editing) {
    THWordsCollection *collection = [_model mergedContentOfRows:selectedIndexSet];
    id itemFromSelf = [self itemFromSelf];
    THAlertBasicAction play_block = ^{
      [self.navigationController
          pushViewController:[[THPlayViewController alloc] initWithCollection:collection]
                    animated:YES];
    };
    __weak THBasicTableViewController *weakSelf = self;
    THAlertBasicAction create_block = ^{
      [self showAlert:dialog_add_playlist(^(NSArray<UITextField *> *textFields) {
              weakSelf.lastTexts = texts_from_text_fields(textFields);
              [weakSelf.model add:weakSelf.lastTexts content:collection];
            })
                 save:YES];
    };
    THAlertBasicAction copy_to_playlists_block = ^{
      NSArray<THPlaylist *> *excluded;
      if (itemFromSelf) {
        if ([itemFromSelf isKindOfClass:[THPlaylist class]]) {
          excluded = @[ itemFromSelf ];
        }
      } else {
        excluded = [_model itemsAtRows:selectedIndexSet];
      }
      [self.navigationController
          pushViewController:[[THPlaylistsViewController alloc]
                                 initWithExcluded:excluded
                                            title:@"Select Playlist(s) to copy to"
                                     searchString:nil
                                      cancelBlock:nil
                                     confirmBlock:^(NSArray<THPlaylist *> *playlists) {
                                       for (THPlaylist *playlist in playlists) {
                                         [playlist addFromWordsCollection:collection];
                                       }
                                     }]
                    animated:YES];
    };
    [self showAlert:sheet_selected_options(play_block, create_block, copy_to_playlists_block)];
  } else {
    NSLog(@"WARNING: %@ should be implemented by subclasses", NSStringFromSelector(_cmd));
  }
}

- (BOOL)preSelectRow:(NSUInteger)row {
  return NO;
}

- (void)didTapBarItemAction {
  [self showAlert:sheet_selection_options(
                      ^{
                        [self selectionSelectAll];
                      },
                      ^{
                        [self selectionClear];
                      },
                      ^{
                        [self selectionInvert];
                      })];
}

- (void)didTapBarItemCancel {
  if (_cancelBlock) {
    _cancelBlock();
  } else {
    [self.navigationController popViewControllerAnimated:YES];
  }
}

#pragma mark - general

- (void)showAlert:(UIAlertController *)alert {
  [self showAlert:alert save:NO];
}

- (void)showAlert:(UIAlertController *)alert save:(BOOL)save {
  [self showAlert:alert completion:nil save:save];
}

- (void)showAlert:(UIAlertController *)alert completion:(void (^)(void))completion save:(BOOL)save {
  if (save) {
    _lastAlert = alert;
  }
  [self.navigationController presentViewController:alert animated:YES completion:completion];
}

- (id)itemFromSelf {
  return nil;
}

#pragma mark - private

- (void)recoverSelections {
  NSUInteger count = [_model numberOfRows];
  // we don't check pre-selected here as it cannot reach here.
  for (NSUInteger row = 0; row < count; ++row) {
    if ([_selectedItems containsObject:[_model itemAtRow:row]]) {
      [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row]
                                  animated:YES
                            scrollPosition:UITableViewScrollPositionNone];
    }
  }
}

- (void)selectionSelectAll {
  NSUInteger count = [_model numberOfRows];
  for (NSUInteger i = 0; i < count; ++i) {
    if (![self preSelectRow:i]) {
      [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i]
                                  animated:YES
                            scrollPosition:UITableViewScrollPositionNone];
      [_selectedItems addObject:[_model itemAtRow:i]];
    }
  }
}

- (void)selectionClear {
  NSUInteger count = [_model numberOfRows];
  for (NSUInteger i = 0; i < count; ++i) {
    if (![self preSelectRow:i]) {
      [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i] animated:YES];
    }
  }
  [_selectedItems removeAllObjects];
}

- (void)selectionInvert {
  [_selectedItems removeAllObjects];
  NSUInteger count = [_model numberOfRows];
  for (NSUInteger i = 0; i < count; ++i) {
    if (![self preSelectRow:i]) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i];
      if ([self.tableView cellForRowAtIndexPath:indexPath].selected) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      } else {
        [self.tableView selectRowAtIndexPath:indexPath
                                    animated:YES
                              scrollPosition:UITableViewScrollPositionNone];
        [_selectedItems addObject:[_model itemAtRow:i]];
      }
    }
  }
}

- (void)updateTitle {
  NSString *customizedTitle = [self customizedTitle];
  if (customizedTitle.length) {
    self.title = customizedTitle;
  }
}

@end

#pragma mark - NSIndexPath (THBaseTableViewController)

@implementation NSIndexPath (THBaseTableViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row {
  return [self indexPathForRow:row inSection:0];
}

@end
