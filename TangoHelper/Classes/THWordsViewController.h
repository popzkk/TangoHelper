#import <UIKit/UIKit.h>

@class THPlaylist;

@interface THWordsViewController : UITableViewController

- (instancetype)initUsingDepot;

- (instancetype)initWithPlaylist:(THPlaylist *)playlist;

- (instancetype)initUsingDepotWithPlaylist:(THPlaylist *)playlist;

@end
