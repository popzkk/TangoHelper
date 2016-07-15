#import <UIKit/UIKit.h>

@class THFileRW;

@interface THWordsViewController : UITableViewController

- (instancetype)initUsingDepot;

- (instancetype)initWithPlaylist:(THFileRW *)playlist;

- (instancetype)initUsingDepotWithPlaylist:(THFileRW *)playlist;

@end
