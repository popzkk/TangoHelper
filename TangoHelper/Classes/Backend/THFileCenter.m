#import "THFileCenter.h"

#import "THDepot.h"
#import "THPlaylist.h"

@interface THFileRW ()

- (instancetype)initWithFilename:(NSString *)filename;

@end

#pragma mark - THFileCenter

@implementation THFileCenter {
  NSString *_path;
  NSMutableDictionary *_openedFiles;
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
  return [self fileRWForClass:[THDepot class] filename:@"test.depot" create:YES];
}

- (NSMutableArray *)playlists {
  return [self filesWithExtension:@"playlist"];
}

- (THPlaylist *)playlistWithPartialName:(NSString *)partialName create:(BOOL)create {
  return [self fileRWForClass:[THPlaylist class]
                     filename:[partialName stringByAppendingPathExtension:@"playlist"]
                       create:create];
}

- (THPlaylist *)tmpPlaylist {
  return [self fileRWForClass:[THPlaylist class] filename:@"playlist" create:YES];
}

- (void)deletePlaylist:(THPlaylist *)playlist {
  NSString *filename = [playlist filename];
  [_openedFiles removeObjectForKey:filename];
  [[NSFileManager defaultManager] removeItemAtPath:[_path stringByAppendingPathComponent:filename]
                                             error:nil];
}

- (void)flushAll {
  for (THFileRW *fileRW in _openedFiles.allValues) {
    [fileRW flush];
  }
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
