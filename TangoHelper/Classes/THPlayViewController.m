#import "THPlayViewController.h"

#import "Backend/THPlaylist.h"

@interface THPlayConfig : NSObject

@property(nonatomic) NSUInteger repeat;

@end

#pragma mark - THPlayViewController

@implementation THPlayViewController {
  THPlaylist *_playlist;
  THPlayConfig *_config;
}

#pragma mark - public

- (instancetype)initWithPlaylist:(THPlaylist *)playlist {
  self = [super init];
  if (self) {
    _playlist = playlist;
    _config = [[THPlayConfig alloc] init];
  }
  return self;
}

@end

#pragma mark - THPlayConfig

@implementation THPlayConfig

- (instancetype)init {
  self = [super init];
  if (self) {
    _repeat = 1;
  }
  return self;
}

@end
