#import "THFileCenter.h"

#import "THFileRW.h"
#import "THPlaylist.h"
#import "THWord.h"
#import "THWordsManager.h"

NSString *const kSpecialPlaylistPartialName = @"You can speak English";

@interface THFileRW ()

- (instancetype)initWithFilename:(NSString *)filename;

- (void)updateWithFilename:(NSString *)filename;

- (void)flush;

@end

#pragma mark - THFileCenter

@implementation THFileCenter {
  NSString *_path;
  NSMutableDictionary<NSString *, THFileRW *> *_openedFiles;
}

#pragma mark - public

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static THFileCenter *instance = nil;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (NSString *)directoryPath {
  return _path;
}

- (NSMutableArray *)playlists {
  return [self filesWithExtension:@"playlist"];
}

- (THPlaylist *)playlistWithPartialName:(NSString *)partialName create:(BOOL)create {
  return [self fileRWForClass:[THPlaylist class]
                     filename:[partialName stringByAppendingPathExtension:@"playlist"]
                       create:create];
}

- (THPlaylist *)tryToCreatePlaylistWithPartialName:(NSString *)partialName {
  if ([self playlistWithPartialName:partialName create:NO]) {
    return nil;
  } else {
    return [self playlistWithPartialName:partialName create:YES];
  }
}

- (void)renamePlaylist:(THPlaylist *)playlist withPartialName:(NSString *)partialName {
  if ([playlist.partialName isEqualToString:partialName]) {
    return;
  }
  NSString *filename = [partialName stringByAppendingPathExtension:@"playlist"];
  [_openedFiles removeObjectForKey:playlist.filename];
  [[NSFileManager defaultManager]
      moveItemAtPath:[_path stringByAppendingPathComponent:playlist.filename]
              toPath:[_path stringByAppendingPathComponent:filename]
               error:nil];
  [playlist updateWithFilename:filename];
  [_openedFiles setObject:playlist forKey:filename];
}

- (void)removePlaylist:(THPlaylist *)playlist {
  NSString *filename = playlist.filename;
  [[THWordsManager sharedInstance] willRemoveFileRW:[_openedFiles objectForKey:filename]];
  [_openedFiles removeObjectForKey:filename];
  [[NSFileManager defaultManager] removeItemAtPath:[_path stringByAppendingPathComponent:filename]
                                             error:nil];
}

- (void)flushAll {
  for (THFileRW *fileRW in _openedFiles.allValues) {
    [fileRW flush];
  }
}
/*
- (THFileRW *)secretFile {
  return [self fileRWForClass:[THFileRW class] filename:@"secret" create:YES];
}
*/
#pragma mark - private

- (instancetype)init {
  self = [super init];
  if (self) {
    _path =
        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    _openedFiles = [NSMutableDictionary dictionary];
  }
  return self;
}

- (id)fileRWForClass:(Class)fileRWClass filename:(NSString *)filename create:(BOOL)create {
  THFileRW *fileRW = [_openedFiles objectForKey:filename];
  if (!fileRW) {
    NSString *path = [_path stringByAppendingPathComponent:filename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
      if (!create) {
        return nil;
      } else {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
      }
    }
    fileRW = [[fileRWClass alloc] initWithFilename:filename];
    [[THWordsManager sharedInstance] didInitializeFileRW:fileRW];
    [_openedFiles setObject:fileRW forKey:filename];
  }
  return fileRW;
}

// extension should be without the leading '.' and in lowercases.
- (NSMutableArray *)filesWithExtension:(NSString *)extension {
  NSArray *allFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_path error:nil];
  NSMutableArray *files = [NSMutableArray array];
  [allFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    NSString *ext = [filename.pathExtension lowercaseString];
    if ([ext isEqualToString:extension]) {
      [files addObject:[self fileRWForClass:[THPlaylist class] filename:filename create:NO]];
    }
  }];
  return files;
}

@end
