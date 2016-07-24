#import <Foundation/Foundation.h>

@class THFileRW;
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

// if this update should align the same arcoss all files, this method must be called.
- (void)fileRW:(THFileRW *)fileRW
 updatedOldKey:(NSString *)oldKey
       withKey:(NSString *)key
        object:(id)object;

- (THFileRW *)secretFile;

@end
