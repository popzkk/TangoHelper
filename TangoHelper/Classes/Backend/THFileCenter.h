#import <Foundation/Foundation.h>

@class THFileRW;
@class THPlaylist;
@class THWordKey;
@class THWordObject;

#define TH_ALLOW_REMOVING_PLAYLISTS 0

extern NSString *kSpecialPlaylistPartialName;

@interface THFileCenter : NSObject

+ (instancetype)sharedInstance;

- (NSString *)directoryPath;

- (void)flushAll;

- (NSMutableArray<THPlaylist *> *)playlists;

- (THPlaylist *)playlistWithPartialName:(NSString *)partialName create:(BOOL)create;

- (THPlaylist *)tryToCreatePlaylistWithPartialName:(NSString *)partialName;

// - (THPlaylist *)tmpPlaylist;

- (void)renamePlaylist:(THPlaylist *)playlist withPartialName:(NSString *)partialName;

- (void)removePlaylist:(THPlaylist *)playlist;

// - (THFileRW *)secretFile;

@end
