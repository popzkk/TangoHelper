#import <UIKit/UIKit.h>

@class THFileRW;
@class THPlaylist;

@interface THWordsViewDataManager : NSObject

- (instancetype)initWithFileRW:(THFileRW *)fileRW;

- (NSArray *)keys;

- (NSArray *)objects;

- (void)filterWithContent:(NSString *)content;

@end

@interface THWordsViewController : UITableViewController

- (instancetype)initUsingDepot;

- (instancetype)initWithPlaylist:(THPlaylist *)playlist;

- (instancetype)initUsingDepotWithPlaylist:(THPlaylist *)playlist;

@end
