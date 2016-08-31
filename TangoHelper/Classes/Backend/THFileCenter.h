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

- (void)flushAllWithThres:(NSUInteger)thres;

- (THDepot *)depot;

- (NSMutableArray<THPlaylist *> *)playlists;

- (THPlaylist *)playlistWithPartialName:(NSString *)partialName create:(BOOL)create;

// - (THPlaylist *)tmpPlaylist;

- (void)renamePlaylist:(THPlaylist *)playlist withPartialName:(NSString *)partialName;

- (void)deletePlaylist:(THPlaylist *)playlist;

// if a word should align the same arcoss all files, this method must be called.
- (void)fileRW:(THFileRW *)fileRW didUpdateKey:(THWordKey *)key withObject:(THWordObject *)object;

- (THFileRW *)secretFile;

- (NSMutableArray<THFileRW *> *)wordsFiles;

@end
