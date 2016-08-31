#import <UIKit/UIKit.h>

#import "Models/THTableViewModel.h"
#import "Shared/THHelpers.h"

typedef void (^THTableViewConfirmBlock)(NSArray *);
typedef void (^THTableViewCancelBlock)();
typedef void (^THTableViewRowActionHandler)(UITableViewRowAction *, NSIndexPath *);

@interface NSIndexPath (THBaseTableViewController)

+ (instancetype)indexPathForRow:(NSUInteger)row;

@end

@interface THBasicTableViewController
    : UITableViewController<UISearchBarDelegate, UISearchControllerDelegate,
                            UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate,
                            THTableViewModelDelegate>

- (instancetype)initWithStyle:(UITableViewStyle)style
                        title:(NSString *)title
                  cancelBlock:(THTableViewCancelBlock)cancelBlock
                 confirmBlock:(THTableViewConfirmBlock)confirmBlock;

@property(nonatomic) THTableViewCancelBlock cancelBlock;

@property(nonatomic) THTableViewConfirmBlock confirmBlock;

@property(nonatomic) NSObject<THTableViewModel> *model;

@property(nonatomic) UISearchController *searchController;

#pragma mark - UI related

/**
 * trash bin, means remove
 * search: hidden
 * editing: remove selected
 * non-editing: remove self (can be a playlist)
 */
@property(nonatomic, readonly) UIBarButtonItem *barItemTrash;

/**
 * search: hidden
 * editing: sometimes hidden (cannot add a playlist)
 */
@property(nonatomic, readonly) UIBarButtonItem *barItemAdd;

/**
 * search: hidden
 * editing: selected options
 * non-editing: play a playlist
 */
@property(nonatomic, readonly) UIBarButtonItem *barItemPlay;

/**
 * edit, to enter the editing state of the table view
 */
@property(nonatomic, readonly) UIBarButtonItem *barItemEdit;

/**
 * done, to exit the editing state of the table view
 */
@property(nonatomic, readonly) UIBarButtonItem *barItemDone;

/**
 * will show a selection action sheet (all, reverse, none)
 * non-editing: hidden
 * search: hidden
 */
@property(nonatomic, readonly) UIBarButtonItem *barItemAction;

/**
 * allows a simple table view to cancel
 * only used in simple situations
 */
@property(nonatomic, readonly) UIBarButtonItem *barItemCancel;

// a padding item
@property(nonatomic, readonly) UIBarButtonItem *barItemPadding;

@property(nonatomic) NSArray<UIBarButtonItem *> *rightItems;

@property(nonatomic) NSArray<UIBarButtonItem *> *rightItemsEditing;

@property(nonatomic) NSArray<UIBarButtonItem *> *bottomItems;

@property(nonatomic) NSArray<UIBarButtonItem *> *bottomItemsEditing;

#pragma mark - UITableViewDataSource related

@property(nonatomic, copy) NSString *cellIdentifier;

@property(nonatomic, assign) UITableViewCellStyle cellStyle;

@property(nonatomic) UIFont *textLabelFont;

@property(nonatomic) UIFont *detailTextLabelFont;

#pragma mark - UITableViewDelegate related

- (NSString *)rowActionTitleModify;

- (THTableViewRowActionHandler)rowActionHandlerModify;

#pragma mark - UIBarButtonItem actions

- (void)didTapBarItemEdit;

- (void)didTapBarItemDone;

- (void)didTapBarItemAdd;

- (void)didTapBarItemTrash;

- (void)didTapBarItemPlay;

- (BOOL)preSelectRow:(NSUInteger)row;

- (void)didTapBarItemAction;

- (void)didTapBarItemCancel;

#pragma mark - general

@property(nonatomic, readonly) UIAlertController *lastAlert;

@property(nonatomic) NSArray<NSString *> *lastTexts;

- (void)showAlert:(UIAlertController *)alert;

- (void)showAlert:(UIAlertController *)alert save:(BOOL)save;

- (void)showAlert:(UIAlertController *)alert completion:(void (^)(void))completion save:(BOOL)save;

- (id)itemFromSelf;

@end
