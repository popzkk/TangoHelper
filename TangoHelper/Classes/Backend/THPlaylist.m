#import "THPlaylist.h"

/** TODO
 * add desc
 */

@implementation THPlaylist

- (NSString *)particialName {
  return [[super filename] stringByDeletingPathExtension];
}

- (NSString *)desc {
  return @"";
}

@end
