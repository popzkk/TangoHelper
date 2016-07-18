#import <Foundation/Foundation.h>

@class THDepot;
@class THPlaylist;

@interface THFileCenter : NSObject

+ (instancetype)sharedInstance;

- (NSString *)directoryPath;

- (void)flushAll;

- (THDepot *)depot;

- (NSMutableArray *)playlists;

- (THPlaylist *)playlistWithPartialName:(NSString *)partialName create:(BOOL)create;

// - (THPlaylist *)tmpPlaylist;

- (void)renamePlaylist:(THPlaylist *)playlist withPartialName:(NSString *)partialName;

- (void)deletePlaylist:(THPlaylist *)playlist;

@end
