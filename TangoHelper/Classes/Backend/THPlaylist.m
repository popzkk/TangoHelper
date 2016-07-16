#import "THPlaylist.h"

/** TODO
 * add desc
 */

@implementation THPlaylist

- (NSString *)partialName {
  return [[super filename] stringByDeletingPathExtension];
}

- (NSString *)desc {
  return @"";
}

@end
