#import <UIKit/UIKit.h>

@class THFileRW;

@interface THPlaylistsViewController : UITableViewController

- (instancetype)init;

- (void)showDialogForPlaylist:(THFileRW *)playlist;

@end
