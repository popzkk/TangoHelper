#import "THWordsViewController.h"

#import "THPlayViewController.h"
#import "Backend/THDepot.h"
#import "Backend/THFileCenter.h"
#import "Backend/THPlaylist.h"
#import "Backend/THWord.h"
#import "Shared/THStrings.h"

typedef NS_ENUM(NSUInteger, THWordsViewControllerSituation) {
  THWordsViewControllerSituationSimple = 0,
  THWordsViewControllerSituationDepot,
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
}

- (instancetype)initWithCollection:(THWordsCollection *)collection {
  return [self initWithCollection:collection preSelected:nil title:nil cancelBlock:nil confirmBlock:nil];
}

- (instancetype)initWithCollection:(THWordsCollection *)collection
                       preSelected:(NSArray<THWordKey *> *)preSelected
                             title:(NSString *)title
                       cancelBlock:(THTableViewCancelBlock)cancelBlock
                      confirmBlock:(THTableViewConfirmBlock)confirmBlock {
  self = [super initWithStyle:UITableViewStylePlain title:title cancelBlock:cancelBlock confirmBlock:confirmBlock];
  if (self) {
    _collection = collection;
    if ([_collection isKindOfClass:[THDepot class]]) {
      _situation = THWordsViewControllerSituationDepot;
    } else if ([_collection isKindOfClass:[THPlaylist class]]) {
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
    self.textLabelFont = cj_regular(kTextLabelFontSize);
    self.detailTextLabelFont = zh_light(kDetailTextLabelFontSize);
    self.tableView.rowHeight = kWordHeight;
    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    if (!self.confirmBlock) {
      self.rightItems = @[ self.barItemEdit ];
      self.rightItemsEditing = @[ self.barItemDone, self.barItemAction ];
      self.bottomItemsEditing = @[
        self.barItemTrash,
        self.barItemPadding,
        self.barItemAdd,
        self.barItemPadding,
        self.barItemPlay
      ];
      if (_situation == THWordsViewControllerSituationDepot) {
        self.title = @"Depot";
        self.bottomItems = @[ self.barItemPadding, self.barItemAdd, self.barItemPadding ];
      } else if (_situation == THWordsViewControllerSituationPlaylist) {
        self.title = ((THPlaylist *)collection).partialName;
        self.bottomItems = self.bottomItemsEditing;
      } else {
        self.navigationItem.hidesBackButton = YES;
        self.bottomItems = @[ self.barItemCancel, self.barItemPadding, self.barItemPlay ];
      }
    }
  }
  return self;
}

#pragma mark - THTableViewModelDelegate

- (void)globalCheckFailedWithHints:(NSArray<NSString *> *)hints
                    positiveAction:(THAlertBasicAction)positiveAction {
  recover_alert_texts(self.lastAlert, self.lastTexts);
  THAlertBasicAction showLastAlertblock = ^{
    [self showAlert:self.lastAlert];
  };
  if (hints.count == 3) {
    [self showAlert:alert_add_word_conflicting(hints[0], hints[1], hints[2], showLastAlertblock,
                                               positiveAction)];
  } else if (hints.count == 4) {
    [self showAlert:alert_edit_word_conflicting(hints[0], hints[1], hints[2], hints[3],
                                                showLastAlertblock, positiveAction)];
  } else if (hints.count == 1) {
    [self showAlert:alert_playlist_exists(hints[0], showLastAlertblock)];
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
    [self showAlert:alert_edit_word([self.tableView cellForRowAtIndexPath:indexPath].textLabel.text,
                                    [self.model textsForModifyingRow:row], nil,
                                    ^(NSArray<UITextField *> *textFields) {
                                      weakSelf.lastTexts = texts_from_text_fields(textFields);
                                      [weakSelf.model modifyRow:row
                                                      withTexts:weakSelf.lastTexts
                                                    globalCheck:YES];
                                    })
               save:YES];
  };
}

#pragma mark - UIBarButtonItem actions

- (void)didTapBarItemAdd {
  __weak THWordsViewController *weakSelf = self;
  [self showAlert:alert_add_word(^(NSArray<UITextField *> *textFields) {
          weakSelf.lastTexts = texts_from_text_fields(textFields);
          [weakSelf.model add:weakSelf.lastTexts globalCheck:YES];
        })
             save:YES];
}

- (void)didTapBarItemTrash {
  if (self.tableView.editing) {
    [super didTapBarItemTrash];
    return;
  }
  [self showAlert:alert_remove_item(self.title, ^{
          [[THFileCenter sharedInstance] deletePlaylist:(THPlaylist *)_collection];
          [self.navigationController popToRootViewControllerAnimated:YES];
        })];
}

- (void)didTapBarItemPlay {
  if (self.tableView.editing || self.confirmBlock) {
    [super didTapBarItemPlay];
    return;
  } else {
    [self showAlert:alert_play(self.title, ^{
            [self.navigationController
                pushViewController:[[THPlayViewController alloc] initWithCollection:_collection]
                          animated:YES];
          })];
  }
}

- (BOOL)preSelectRow:(NSUInteger)row {
  return [_preSelected containsObject:[self.model itemAtRow:row]];
}

#pragma mark - general

- (id)itemFromSelf {
  return _collection;
}

@end
