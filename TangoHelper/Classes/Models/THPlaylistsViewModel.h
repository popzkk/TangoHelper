#import "THTableViewModel.h"

@class THPlaylist;

@interface THPlaylistsViewModel : NSObject<THTableViewModel>

- (instancetype)initWithExcluded:(NSArray<THPlaylist *> *)excluded;

@end
