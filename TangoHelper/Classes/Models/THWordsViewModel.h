#import "THTableViewModel.h"

@class THPlaylist;
@class THWordKey;

@protocol THWordsViewModelDelegate

- (void)modelDidCreatePlaylist:(THPlaylist *)playlist;

@end

@interface THWordsViewModel : NSObject <THTableViewModel>

- (instancetype)initWithCollection:(THWordsCollection *)collection;

@end
