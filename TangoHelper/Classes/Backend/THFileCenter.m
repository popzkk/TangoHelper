#import "THFileCenter.h"

#import "THFileRW.h"
#import "THDepot.h"
#import "THPlaylist.h"
#import "THWord.h"

@interface THFileRW ()

- (instancetype)initWithFilename:(NSString *)filename;

- (void)updateWithFilename:(NSString *)filename;

- (void)setObject:(THWordObject *)object forKey:(THWordKey *)key;

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

- (THDepot *)depot {
  return [self fileRWForClass:[THDepot class] filename:@"depot" create:YES];
}

- (NSMutableArray *)playlists {
  return [self filesWithExtension:@"playlist"];
}

- (THPlaylist *)playlistWithPartialName:(NSString *)partialName create:(BOOL)create {
  return [self fileRWForClass:[THPlaylist class]
                     filename:[partialName stringByAppendingPathExtension:@"playlist"]
                       create:create];
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

- (void)deletePlaylist:(THPlaylist *)playlist {
  NSString *filename = playlist.filename;
  [_openedFiles removeObjectForKey:filename];
  [[NSFileManager defaultManager] removeItemAtPath:[_path stringByAppendingPathComponent:filename]
                                             error:nil];
}

- (void)flushAll {
  for (THFileRW *fileRW in _openedFiles.allValues) {
    [fileRW flush];
  }
}

- (void)flushAllWithThres:(NSUInteger)thres {
  for (THFileRW *fileRW in _openedFiles.allValues) {
    [fileRW flushWithThres:thres];
  }
}

- (void)fileRW:(THFileRW *)fileRW didUpdateKey:(THWordKey *)key withObject:(THWordObject *)object {
#if (DEBUG)
  if ([_openedFiles objectForKey:fileRW.filename] != fileRW) {
    NSLog(@"Internal error: fileRW not found!");
    return;
  }
#endif
  for (THFileRW *anotherFileRW in [self wordsFiles]) {
    if (anotherFileRW == fileRW) {
      continue;
    }
    THWordObject *anotherObj = [anotherFileRW objectForKey:key];
    if (anotherObj && anotherObj != object) {
      [anotherFileRW setObject:object forKey:key];
    }
  }
}

- (THFileRW *)secretFile {
  return [self fileRWForClass:[THFileRW class] filename:@"secret" create:YES];
}

- (NSMutableArray *)wordsFiles {
  NSMutableArray *files = [self playlists];
  [files addObject:[self depot]];
  return files;
}

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
  id fileRW = [_openedFiles objectForKey:filename];
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
