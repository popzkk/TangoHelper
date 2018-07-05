#import "THWordsViewController.h"

#import "Backend/THFileCenter.h"
#import "Backend/THPlaylist.h"
#import "Backend/THWord.h"
#import "Shared/THStrings.h"
#import "THPlayViewController.h"

typedef NS_ENUM(NSUInteger, THWordsViewControllerSituation) {
  THWordsViewControllerSituationSimple = 0,
  THWordsViewControllerSituationPlaylist,
  THWordsViewControllerSituationCollection,
};

static NSString *kCellIdentifier = @"WordsViewCell";
static UITableViewCellStyle kCellStyle = UITableViewCellStyleValue1;
static CGFloat kTextLabelFontSize = 14;
static CGFloat kDetailTextLabelFontSize = 14;

static CGFloat kWordHeight = 40;

@implementation THWordsViewController {
  THWordsViewControllerSituation _situation;
  THWordsCollection *_collection;
  NSSet<THWordKey *> *_preSelected;
  NSString *_basicTitle;
}

- (instancetype)initWithCollection:(THWordsCollection *)collection {
  return [self initWithCollection:collection searchString:nil];
}

- (instancetype)initWithCollection:(THWordsCollection *)collection
                      searchString:(NSString *)searchString {
  return [self initWithCollection:collection
                      preSelected:nil
                            title:nil
                     searchString:searchString
                      cancelBlock:nil
                     confirmBlock:nil];
}

- (instancetype)initWithCollection:(THWordsCollection *)collection
                       preSelected:(NSArray<THWordKey *> *)preSelected
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
    _collection = collection;
    if ([_collection isKindOfClass:[THPlaylist class]]) {
      _situation = THWordsViewControllerSituationPlaylist;
    } else if (self.confirmBlock) {
      _situation = THWordsViewControllerSituationSimple;
    } else {
      _situation = THWordsViewControllerSituationCollection;
    }
#if (DEBUG)
    if (_situation == THWordsViewControllerSituationSimple && !confirmBlock) {
      NSLog(@"WARNING: a simple words view must have a confirm block");
      return nil;
    }
    if (_situation != THWordsViewControllerSituationSimple && confirmBlock) {
      NSLog(@"WARNING: a depot/playlist words view mustn't have a confirm block");
      return nil;
    }
#endif
    if (preSelected) {
      _preSelected = [NSSet setWithArray:preSelected];
    }

    self.model = [[THWordsViewModel alloc] initWithCollection:_collection];
    self.model.delegate = self;
    self.cellIdentifier = kCellIdentifier;
    self.cellStyle = kCellStyle;
    self.textLabelFont = ja_normal(kTextLabelFontSize);
    self.detailTextLabelFont = zh_normal(kDetailTextLabelFontSize);
    self.tableView.rowHeight = kWordHeight;
    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    if (!self.confirmBlock) {
      self.rightItems = @[ self.barItemEdit ];
      self.rightItemsEditing = @[ self.barItemDone, self.barItemAction ];
      self.bottomItemsEditing = @[
        self.barItemTrash, self.barItemPadding, self.barItemAdd, self.barItemPadding,
        self.barItemPlay
      ];
      if (_situation == THWordsViewControllerSituationPlaylist) {
        _basicTitle = ((THPlaylist *)collection).partialName;
        self.bottomItems = self.bottomItemsEditing;
      } else {
        self.navigationItem.hidesBackButton = YES;
        self.bottomItems = @[ self.barItemCancel, self.barItemPadding, self.barItemPlay ];
        self.bottomItemsEditing = @[ self.barItemTrash, self.barItemPadding, self.barItemPlay ];
      }
    }
  }
  return self;
}

- (NSString *)customizedTitle {
  if (_basicTitle.length) {
    return [NSString stringWithFormat:@"%@ (%lu)", _basicTitle, (unsigned long)_collection.count];
  }
  return nil;
}

#pragma mark - THTableViewModelDelegate

- (void)globalCheckFailedWithHints:(NSArray<NSString *> *)hints
                    positiveAction:(THAlertBasicAction)positiveAction {
  recover_dialog_texts(self.lastAlert, self.lastTexts);
  THAlertBasicAction showLastAlertblock = ^{
    [self showAlert:self.lastAlert];
  };
  if (hints.count == 3) {
    [self showAlert:dialog_add_word_conflicting(hints[0], hints[1], hints[2], showLastAlertblock,
                                                positiveAction)];
  } else if (hints.count == 4) {
    [self showAlert:dialog_edit_word_conflicting(hints[0], hints[1], hints[2], hints[3],
                                                 showLastAlertblock, positiveAction)];
  } else if (hints.count == 1) {
    [self showAlert:dialog_playlist_exists(hints[0], showLastAlertblock)];
  } else {
    NSLog(@"Internal error: unknown global check feedback");
  }
}

#pragma mark - THWordsViewModelDelegate

- (void)modelDidCreatePlaylist:(THPlaylist *)playlist {
  [self.navigationController popToRootViewControllerAnimated:YES];
  [self.navigationController
      pushViewController:[[THWordsViewController alloc] initWithCollection:playlist]
                animated:YES];
}

#pragma mark - UITableViewDelegate related

- (NSString *)rowActionTitleModify {
  return kEdit;
}

- (THTableViewRowActionHandler)rowActionHandlerModify {
  __weak THWordsViewController *weakSelf = self;
  return ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
    NSUInteger row = indexPath.row;
    [self
        showAlert:dialog_edit_word([self.tableView cellForRowAtIndexPath:indexPath].textLabel.text,
                                   [self.model textsForModifyingRow:row], nil,
                                   ^(NSArray<UITextField *> *textFields) {
                                     weakSelf.lastTexts = texts_from_text_fields(textFields);
                                     [weakSelf.model modifyRow:row withTexts:weakSelf.lastTexts];
                                   })
             save:YES];
  };
}

#pragma mark - UIBarButtonItem actions

- (void)didTapBarItemAdd {
  __weak THWordsViewController *weakSelf = self;
  [self showAlert:dialog_add_word(^(NSArray<UITextField *> *textFields) {
          weakSelf.lastTexts = texts_from_text_fields(textFields);
          [weakSelf.model add:weakSelf.lastTexts];
        })
             save:YES];
}

- (void)didTapBarItemTrash {
  if (self.tableView.editing) {
    [super didTapBarItemTrash];
    return;
  }
#if (TH_ALLOW_REMOVING_PLAYLISTS)
  if ([((THPlaylist *)_collection).partialName isEqualToString:kSpecialPlaylistPartialName]) {
#endif
    [self showAlert:dialog_special_playlist_disallowed()];
#if (TH_ALLOW_REMOVING_PLAYLISTS)
  } else {
    [self showAlert:dialog_remove_item(self.title, ^{
            [[THFileCenter sharedInstance] removePlaylist:(THPlaylist *)_collection];
            [self.navigationController popToRootViewControllerAnimated:YES];
          })];
  }
#endif
}

- (void)didTapBarItemPlay {
  if (self.tableView.editing || self.confirmBlock) {
    [super didTapBarItemPlay];
    return;
  }
  [self showAlert:dialog_play(self.title, ^{
          [self.navigationController
              pushViewController:[[THPlayViewController alloc] initWithCollection:_collection]
                        animated:YES];
        })];
}

- (BOOL)preSelectRow:(NSUInteger)row {
  return [_preSelected containsObject:[self.model itemAtRow:row]];
}

#pragma mark - general

- (id)itemFromSelf {
  return _collection;
}

@end
