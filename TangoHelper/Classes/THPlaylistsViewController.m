#import "THPlaylistsViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THFileRW.h"
#import "Backend/THPlaylist.h"
#import "Models/THPlaylistsViewModel.h"
#import "Shared/THStrings.h"
#import "THWordsViewController.h"

static NSString *kCellIdentifier = @"PlaylistsViewCell";
static UITableViewCellStyle kCellStyle = UITableViewCellStyleSubtitle;
static CGFloat kTextLabelFontSize = 15;
static CGFloat kDetailTextLabelFontSize = 12;

static CGFloat kPlaylistHeight = 60;

@implementation THPlaylistsViewController {
  UIAlertController *_savedAlert;
  NSString *_savedPartialName;
}

- (instancetype)init {
  return [self initWithExcluded:nil title:nil searchString:nil cancelBlock:nil confirmBlock:nil];
}

- (instancetype)initWithExcluded:(NSArray<THPlaylist *> *)excluded
                           title:(NSString *)title
                    searchString:(NSString *)searchString
                     cancelBlock:(THTableViewCancelBlock)cancelBlock
                    confirmBlock:(THTableViewConfirmBlock)confirmBlock {
  self = [super initWithStyle:UITableViewStylePlain
                        title:title
                 searchString:searchString
                  cancelBlock:cancelBlock
                 confirmBlock:confirmBlock];
  if (self) {
    self.model = [[THPlaylistsViewModel alloc] initWithExcluded:excluded];
    self.model.delegate = self;
    self.cellIdentifier = kCellIdentifier;
    self.cellStyle = kCellStyle;
    self.textLabelFont = ja_normal(kTextLabelFontSize);
    self.detailTextLabelFont = ja_normal(kDetailTextLabelFontSize);
    self.detailTextLabelColor = [UIColor grayColor];
    self.tableView.rowHeight = kPlaylistHeight;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    if (!self.confirmBlock) {
      self.rightItems = @[ self.barItemEdit ];
      self.rightItemsEditing = @[ self.barItemDone, self.barItemAction ];
      self.bottomItems = @[ self.barItemPadding, self.barItemAdd, self.barItemPadding ];
      self.bottomItemsEditing = @[ self.barItemTrash, self.barItemPadding, self.barItemPlay ];
      self.title = @"Playlists";
    }
  }
  return self;
}

#pragma mark - THTableViewModelDelegate

- (void)globalCheckFailedWithHints:(NSArray<NSString *> *)hints
                    positiveAction:(THAlertBasicAction)positiveAction {
  recover_dialog_texts(self.lastAlert, self.lastTexts);
  [self showAlert:dialog_playlist_exists(hints.firstObject, ^{
          [self showAlert:self.lastAlert];
        })];
}

- (void)modelDidAddAtRow:(NSUInteger)row {
  [self.navigationController pushViewController:[[THWordsViewController alloc]
                                                    initWithCollection:[self.model itemAtRow:row]]
                                       animated:YES];
}

- (void)modelDidRemoveRows:(NSIndexSet *)rows {
  if (rows) {
    [super modelDidRemoveRows:rows];
  } else {
    [self showAlert:dialog_special_playlist_disallowed()];
  }
}

- (void)modelDidModifyAtRow:(NSUInteger)row {
  if (row != NSNotFound) {
    [super modelDidModifyAtRow:row];
  } else {
    [self showAlert:dialog_special_playlist_disallowed()];
  }
}

#pragma mark - UITableViewDelegate related

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView.isEditing) {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  } else {
    THPlaylist *playlist = [self.model itemAtRow:indexPath.row];
    if (self.searchString && [playlist searchWithString:self.searchString].count > 0) {
      [self.navigationController
          pushViewController:[[THWordsViewController alloc] initWithCollection:playlist
                                                                  searchString:self.searchString]
                    animated:YES];
    } else {
      [self.navigationController
          pushViewController:[[THWordsViewController alloc] initWithCollection:playlist
                                                                  searchString:nil]
                    animated:YES];
    }
  }
}

- (NSString *)rowActionTitleModify {
  return kRename;
}

- (THTableViewRowActionHandler)rowActionHandlerModify {
  __weak THPlaylistsViewController *weakSelf = self;
  return ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
    NSUInteger row = indexPath.row;
    [self showAlert:dialog_rename_playlist(
                        ((THPlaylist *)[self.model itemAtRow:row]).partialName,
                        ^(NSArray<UITextField *> *textFields) {
                          weakSelf.lastTexts = texts_from_text_fields(textFields);
                          [weakSelf.model modifyRow:row withTexts:weakSelf.lastTexts];
                        })
               save:YES];
  };
}

#pragma mark - UIBarButtonItem actions

- (void)didTapBarItemAdd {
  __weak THPlaylistsViewController *weakSelf = self;
  [self showAlert:dialog_add_playlist(^(NSArray<UITextField *> *textFields) {
          weakSelf.lastTexts = texts_from_text_fields(textFields);
          [weakSelf.model add:weakSelf.lastTexts];
        })
             save:YES];
}

@end
