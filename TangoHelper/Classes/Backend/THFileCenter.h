#import <Foundation/Foundation.h>

@class THFileRW;
@class THDepot;
@class THPlaylist;
@class THWordKey;
@class THWordObject;

@interface THFileCenter : NSObject

+ (instancetype)sharedInstance;

- (NSString *)directoryPath;

- (void)flushAll;

- (THDepot *)depot;

- (NSMutableArray<THPlaylist *> *)playlists;

- (THPlaylist *)playlistWithPartialName:(NSString *)partialName create:(BOOL)create;

// - (THPlaylist *)tmpPlaylist;

- (void)renamePlaylist:(THPlaylist *)playlist withPartialName:(NSString *)partialName;

- (void)removePlaylist:(THPlaylist *)playlist;

- (THFileRW *)secretFile;

- (NSMutableArray<THFileRW *> *)wordsFiles;

@end
