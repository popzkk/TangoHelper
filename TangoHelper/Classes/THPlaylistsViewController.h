#import <UIKit/UIKit.h>

@class THPlaylist;

@interface THPlaylistsViewController : UITableViewController

- (instancetype)init;

- (void)showDialogForPlaylist:(THPlaylist *)playlist;

@end
