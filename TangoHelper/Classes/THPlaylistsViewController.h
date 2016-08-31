#import "THBasicTableViewController.h"

@class THPlaylist;

@interface THPlaylistsViewController : THBasicTableViewController

- (instancetype)initWithExcluded:(NSArray<THPlaylist *> *)excluded
                           title:(NSString *)title
                     cancelBlock:(THTableViewCancelBlock)cancelBlock
                    confirmBlock:(THTableViewConfirmBlock)confirmBlock;

@end
