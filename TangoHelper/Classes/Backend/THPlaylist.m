#import "THPlaylist.h"

@implementation THPlaylist

- (NSString *)particialName {
  return [[super filename] stringByDeletingPathExtension];
}

- (NSString *)desc {
  return @"";
}

@end
